package blake2b

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Interface for the BLAKE2B hashing algorithm.
    BLAKE2B and BLAKE2B share the implementation in the _blake2 package.
*/

import "core:os"
import "core:io"

import "../botan"
import "../ctx"
import "../_blake2"

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
    ctx.hash_bytes_64  = hash_bytes_odin
    ctx.hash_file_64   = hash_file_odin
    ctx.hash_stream_64 = hash_stream_odin
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    botan.assign_hash_vtable(_hash_impl, botan.HASH_BLAKE2B)
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
hash_bytes :: proc(data: []byte) -> [64]byte {
    _create_blake2_ctx()
    return _hash_impl->hash_bytes_64(data)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([64]byte, os.Errno) {
    _create_blake2_ctx()
    return _hash_impl->hash_stream_64(s)
}

// hash_file will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_file :: proc(path: string) -> ([64]byte, os.Errno) {
    _create_blake2_ctx()
    return _hash_impl->hash_file_64(path)
}

hash :: proc {
    hash_stream,
    hash_file,
    hash_bytes,
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

hash_bytes_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) -> [64]byte {
    hash: [64]byte
    if c, ok := ctx.internal_ctx.(_blake2.Blake2b_Context); ok {
        _blake2.init_odin(&c)
        _blake2.update_odin(&c, data)
        _blake2.blake2b_final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream) -> ([64]byte, os.Errno) {
    hash: [64]byte
    if c, ok := ctx.internal_ctx.(_blake2.Blake2b_Context); ok {
        _blake2.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _blake2.update_odin(&c, buf[:read])
            } 
        }
        _blake2.blake2b_final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        return hash, os.Errno(-1)
    }
}

hash_file_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string) -> ([64]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_odin(ctx, os.stream_from_handle(hd))
    } else {
        return [64]byte{}, err
    }
}

@(private)
_create_blake2_ctx :: #force_inline proc() {
    ctx: _blake2.Blake2b_Context
    cfg: _blake2.Blake2_Config
    cfg.size = _blake2.BLAKE2B_SIZE
    ctx.cfg  = cfg
    _hash_impl.internal_ctx = ctx
    _hash_impl.hash_size    = ._64
}

@(private)
_init_odin :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    _create_blake2_ctx()
    if c, ok := ctx.internal_ctx.(_blake2.Blake2b_Context); ok {
        _blake2.init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(_blake2.Blake2b_Context); ok {
        _blake2.update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(_blake2.Blake2b_Context); ok {
        _blake2.blake2b_final_odin(&c, hash)
    }
}
