package sha3

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Interface for the SHA3 hashing algorithm. The SHAKE functionality can be found in package shake.
    If you wish to compute a Keccak hash, you can use the keccak package, it will use the original padding.
*/

import "core:os"
import "core:io"

import "../botan"
import "../ctx"
import "../_sha3"

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
    ctx.hash_bytes_28  = hash_bytes_odin_28
    ctx.hash_file_28   = hash_file_odin_28
    ctx.hash_stream_28 = hash_stream_odin_28
    ctx.hash_bytes_32  = hash_bytes_odin_32
    ctx.hash_file_32   = hash_file_odin_32
    ctx.hash_stream_32 = hash_stream_odin_32
    ctx.hash_bytes_48  = hash_bytes_odin_48
    ctx.hash_file_48   = hash_file_odin_48
    ctx.hash_stream_48 = hash_stream_odin_48
    ctx.hash_bytes_64  = hash_bytes_odin_64
    ctx.hash_file_64   = hash_file_odin_64
    ctx.hash_stream_64 = hash_stream_odin_64
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    botan.assign_hash_vtable(_hash_impl, botan.HASH_SHA3)
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
use_odin :: #force_inline proc() {
    _assign_hash_vtable(_hash_impl)
}

/*
    High level API
*/

// hash_bytes_224 will hash the given input and return the
// computed hash
hash_bytes_224 :: proc(data: []byte) -> [28]byte {
    _create_sha3_ctx(28)
    return _hash_impl->hash_bytes_28(data)
}

// hash_stream_224 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224 :: proc(s: io.Stream) -> ([28]byte, os.Errno) {
    _create_sha3_ctx(28)
    return _hash_impl->hash_stream_28(s)
}

// hash_file_224 will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_file_224 :: proc(path: string) -> ([28]byte, os.Errno) {
    _create_sha3_ctx(28)
    return _hash_impl->hash_file_28(path)
}

hash_224 :: proc {
    hash_stream_224,
    hash_file_224,
    hash_bytes_224,
}

// hash_bytes_256 will hash the given input and return the
// computed hash
hash_bytes_256 :: proc(data: []byte) -> [32]byte {
    _create_sha3_ctx(32)
    return _hash_impl->hash_bytes_32(data)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([32]byte, os.Errno) {
    _create_sha3_ctx(32)
    return _hash_impl->hash_stream_32(s)
}

// hash_file_256 will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_file_256 :: proc(path: string) -> ([32]byte, os.Errno) {
    _create_sha3_ctx(32)
    return _hash_impl->hash_file_32(path)
}

hash_256 :: proc {
    hash_stream_256,
    hash_file_256,
    hash_bytes_256,
}

// hash_bytes_384 will hash the given input and return the
// computed hash
hash_bytes_384 :: proc(data: []byte) -> [48]byte {
    _create_sha3_ctx(48)
    return _hash_impl->hash_bytes_48(data)
}

// hash_stream_384 will read the stream in chunks and compute a
// hash from its contents
hash_stream_384 :: proc(s: io.Stream) -> ([48]byte, os.Errno) {
    _create_sha3_ctx(48)
    return _hash_impl->hash_stream_48(s)
}

// hash_file_384 will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_file_384 :: proc(path: string) -> ([48]byte, os.Errno) {
    _create_sha3_ctx(48)
    return _hash_impl->hash_file_48(path)
}

hash_384 :: proc {
    hash_stream_384,
    hash_file_384,
    hash_bytes_384,
}

// hash_bytes_512 will hash the given input and return the
// computed hash
hash_bytes_512 :: proc(data: []byte) -> [64]byte {
    _create_sha3_ctx(64)
    return _hash_impl->hash_bytes_64(data)
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([64]byte, os.Errno) {
    _create_sha3_ctx(64)
    return _hash_impl->hash_stream_64(s)
}

// hash_file_512 will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_file_512 :: proc(path: string) -> ([64]byte, os.Errno) {
    _create_sha3_ctx(64)
    return _hash_impl->hash_file_64(path)
}

hash_512 :: proc {
    hash_stream_512,
    hash_file_512,
    hash_bytes_512,
}

/*
    Low level API
*/

init :: proc(ctx: ^ctx.Hash_Context) {
    _hash_impl->init()
}

update :: proc(ctx: ^ctx.Hash_Context, data: []byte) {
    _hash_impl->update(data)
}

final :: proc(ctx: ^ctx.Hash_Context, hash: []byte) {
    _hash_impl->final(hash)
}

/*
    SHA3 implementation
*/

hash_bytes_odin_28 :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) -> [28]byte {
    hash: [28]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_28 :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream) -> ([28]byte, os.Errno) {
    hash: [28]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _sha3.update_odin(&c, buf[:read])
            } 
        }
        _sha3.final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        return hash, os.Errno(-1)
    }
}

hash_file_odin_28 :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string) -> ([28]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_odin_28(ctx, os.stream_from_handle(hd))
    } else {
        return [28]byte{}, err
    }
}

hash_bytes_odin_32 :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) -> [32]byte {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_32 :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream) -> ([32]byte, os.Errno) {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _sha3.update_odin(&c, buf[:read])
            } 
        }
        _sha3.final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        return hash, os.Errno(-1)
    }
}

hash_file_odin_32 :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string) -> ([32]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_odin_32(ctx, os.stream_from_handle(hd))
    } else {
        return [32]byte{}, err
    }
}

hash_bytes_odin_48 :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) -> [48]byte {
    hash: [48]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_48 :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream) -> ([48]byte, os.Errno) {
    hash: [48]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _sha3.update_odin(&c, buf[:read])
            } 
        }
        _sha3.final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        return hash, os.Errno(-1)
    }
}

hash_file_odin_48 :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string) -> ([48]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_odin_48(ctx, os.stream_from_handle(hd))
    } else {
        return [48]byte{}, err
    }
}

hash_bytes_odin_64 :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) -> [64]byte {
    hash: [64]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_64 :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream) -> ([64]byte, os.Errno) {
    hash: [64]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _sha3.update_odin(&c, buf[:read])
            } 
        }
        _sha3.final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        return hash, os.Errno(-1)
    }
}

hash_file_odin_64 :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string) -> ([64]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_odin_64(ctx, os.stream_from_handle(hd))
    } else {
        return [64]byte{}, err
    }
}

@(private)
_create_sha3_ctx :: #force_inline proc(mdlen: int) {
    ctx: _sha3.Sha3_Context
    ctx.mdlen               = mdlen
    _hash_impl.internal_ctx = ctx
    switch mdlen {
        case 28: _hash_impl.hash_size = ._28
        case 32: _hash_impl.hash_size = ._32
        case 48: _hash_impl.hash_size = ._48
        case 64: _hash_impl.hash_size = ._64
    }
}

@(private)
_init_odin :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    #partial switch ctx.hash_size {
        case ._28: _create_sha3_ctx(28)
        case ._32: _create_sha3_ctx(32)
        case ._48: _create_sha3_ctx(48)
        case ._64: _create_sha3_ctx(64)
    }
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.final_odin(&c, hash)
    }
}
