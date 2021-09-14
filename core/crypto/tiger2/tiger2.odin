package tiger2

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Interface for the Tiger2 variant of the Tiger hashing algorithm as defined in <https://www.cs.technion.ac.il/~biham/Reports/Tiger/>
*/

import "core:os"
import "core:io"

import "../ctx"
import "../_tiger"

/*
    Context initialization and switching between the Odin implementation and the bindings
*/

USE_BOTAN_LIB :: bool(#config(USE_BOTAN_LIB, false))

@(private)
_init_vtable :: #force_inline proc() -> ^ctx.Hash_Context {
    ctx := ctx._init_vtable()
    when USE_BOTAN_LIB {
        use_botan()
    } else {
        _assign_hash_vtable(ctx)
    }
    return ctx
}

@(private)
_assign_hash_vtable :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    ctx.hash_bytes_16  = hash_bytes_odin_16
    ctx.hash_file_16   = hash_file_odin_16
    ctx.hash_stream_16 = hash_stream_odin_16
    ctx.hash_bytes_20  = hash_bytes_odin_20
    ctx.hash_file_20   = hash_file_odin_20
    ctx.hash_stream_20 = hash_stream_odin_20
    ctx.hash_bytes_24  = hash_bytes_odin_24
    ctx.hash_file_24   = hash_file_odin_24
    ctx.hash_stream_24 = hash_stream_odin_24
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan does nothing, since Tiger2 is not available in Botan
@(warning="Tiger2 is not provided by the Botan API. Odin implementation will be used")
use_botan :: #force_inline proc() {
    use_odin()
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
use_odin :: #force_inline proc() {
    _assign_hash_vtable(_hash_impl)
}

/*
    High level API
*/

// hash_bytes_128 will hash the given input and return the
// computed hash
hash_bytes_128 :: proc(data: []byte) -> [16]byte {
    _create_ripemd_ctx(16)
    return _hash_impl->hash_bytes_16(data)
}

// hash_stream_128 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128 :: proc(s: io.Stream) -> ([16]byte, os.Errno) {
    _create_ripemd_ctx(16)
    return _hash_impl->hash_stream_16(s)
}

// hash_file_128 will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_file_128 :: proc(path: string) -> ([16]byte, os.Errno) {
    _create_ripemd_ctx(16)
    return _hash_impl->hash_file_16(path)
}

hash_128 :: proc {
    hash_stream_128,
    hash_file_128,
    hash_bytes_128,
}

// hash_bytes_160 will hash the given input and return the
// computed hash
hash_bytes_160 :: proc(data: []byte) -> [20]byte {
    _create_ripemd_ctx(20)
    return _hash_impl->hash_bytes_20(data)
}

// hash_stream_160 will read the stream in chunks and compute a
// hash from its contents
hash_stream_160 :: proc(s: io.Stream) -> ([20]byte, os.Errno) {
    _create_ripemd_ctx(20)
    return _hash_impl->hash_stream_20(s)
}

// hash_file_160 will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_file_160 :: proc(path: string) -> ([20]byte, os.Errno) {
    _create_ripemd_ctx(20)
    return _hash_impl->hash_file_20(path)
}

hash_160 :: proc {
    hash_stream_160,
    hash_file_160,
    hash_bytes_160,
}

// hash_bytes_192 will hash the given input and return the
// computed hash
hash_bytes_192 :: proc(data: []byte) -> [24]byte {
    _create_ripemd_ctx(24)
    return _hash_impl->hash_bytes_24(data)
}

// hash_stream_192 will read the stream in chunks and compute a
// hash from its contents
hash_stream_192 :: proc(s: io.Stream) -> ([24]byte, os.Errno) {
    _create_ripemd_ctx(24)
    return _hash_impl->hash_stream_24(s)
}

// hash_file_192 will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_file_192 :: proc(path: string) -> ([24]byte, os.Errno) {
    _create_ripemd_ctx(24)
    return _hash_impl->hash_file_24(path)
}

hash_192 :: proc {
    hash_stream_192,
    hash_file_192,
    hash_bytes_192,
}

/*
    Tiger implementation
*/

hash_bytes_odin_16 :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) -> [16]byte {
    hash: [16]byte
    if c, ok := ctx.internal_ctx.(_tiger.Tiger_Context); ok {
        _tiger.init_odin(&c)
        _tiger.update_odin(&c, data)
        _tiger.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_16 :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream) -> ([16]byte, os.Errno) {
    hash: [16]byte
    if c, ok := ctx.internal_ctx.(_tiger.Tiger_Context); ok {
        _tiger.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _tiger.update_odin(&c, buf[:read])
            } 
        }
        _tiger.final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        return hash, os.Errno(-1)
    }
}

hash_file_odin_16 :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string) -> ([16]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_odin_16(ctx, os.stream_from_handle(hd))
    } else {
        return [16]byte{}, err
    }
}

hash_bytes_odin_20 :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) -> [20]byte {
    hash: [20]byte
    if c, ok := ctx.internal_ctx.(_tiger.Tiger_Context); ok {
        _tiger.init_odin(&c)
        _tiger.update_odin(&c, data)
        _tiger.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_20 :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream) -> ([20]byte, os.Errno) {
    hash: [20]byte
    if c, ok := ctx.internal_ctx.(_tiger.Tiger_Context); ok {
        _tiger.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _tiger.update_odin(&c, buf[:read])
            } 
        }
        _tiger.final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        return hash, os.Errno(-1)
    }
}

hash_file_odin_20 :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string) -> ([20]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_odin_20(ctx, os.stream_from_handle(hd))
    } else {
        return [20]byte{}, err
    }
}

hash_bytes_odin_24 :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) -> [24]byte {
    hash: [24]byte
    if c, ok := ctx.internal_ctx.(_tiger.Tiger_Context); ok {
        _tiger.init_odin(&c)
        _tiger.update_odin(&c, data)
        _tiger.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_24 :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream) -> ([24]byte, os.Errno) {
    hash: [24]byte
    if c, ok := ctx.internal_ctx.(_tiger.Tiger_Context); ok {
        _tiger.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _tiger.update_odin(&c, buf[:read])
            } 
        }
        _tiger.final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        return hash, os.Errno(-1)
    }
}

hash_file_odin_24 :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string) -> ([24]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_odin_24(ctx, os.stream_from_handle(hd))
    } else {
        return [24]byte{}, err
    }
}

@(private)
_create_ripemd_ctx :: #force_inline proc(hash_size: int) {
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _hash_impl.internal_ctx = ctx
    switch hash_size {
        case 16: _hash_impl.hash_size = ._16
        case 20: _hash_impl.hash_size = ._20
        case 24: _hash_impl.hash_size = ._24
    }
}

@(private)
_init_odin :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    #partial switch ctx.hash_size {
        case ._16: _create_ripemd_ctx(16)
        case ._20: _create_ripemd_ctx(20)
        case ._24: _create_ripemd_ctx(24)
    }
    if c, ok := ctx.internal_ctx.(_tiger.Tiger_Context); ok {
        _tiger.init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(_tiger.Tiger_Context); ok {
        _tiger.update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(_tiger.Tiger_Context); ok {
        _tiger.final_odin(&c, hash)
    }
}