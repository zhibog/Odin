package skein

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the SKEIN hashing algorithm, as defined in <https://www.schneier.com/academic/skein/>
    
    This package offers the internal state sizes of 256, 512 and 1024 bits and arbitrary output
*/

import "core:mem"
import "core:os"
import "core:io"

import "../util"
import "../botan"
import "../ctx"

/*
    Context initialization and switching between the Odin implementation and the bindings
*/

USE_BOTAN_LIB :: bool(#config(USE_BOTAN_LIB, false))

@(private)
_init_vtable :: #force_inline proc() -> ^ctx.Hash_Context {
    ctx := ctx._init_vtable()
    when USE_BOTAN_LIB {
        use_botan()
        ctx.is_using_odin = false
    } else {
        _assign_hash_vtable(ctx)
        ctx.is_using_odin = true
    }
    return ctx
}

@(private)
_assign_hash_vtable :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    // @note(zh): Default to SKEIN-512
    ctx.hash_bytes_slice  = hash_bytes_skein512_odin
    ctx.hash_file_slice   = hash_file_skein512_odin
    ctx.hash_stream_slice = hash_stream_skein512_odin
    ctx.init              = _init_skein512_odin
    ctx.update            = _update_skein512_odin
    ctx.final             = _final_skein512_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    _hash_impl.is_using_odin = false
    // @note(zh): Botan only supports SKEIN-512.
    botan.assign_hash_vtable(_hash_impl, botan.HASH_SKEIN_512)
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
use_odin :: #force_inline proc() {
    _hash_impl.is_using_odin = true
    _assign_hash_vtable(_hash_impl)
}

@(private)
_create_skein256_ctx :: #force_inline proc(size: int) {
    _hash_impl.hash_size_val = size
    if _hash_impl.is_using_odin {
        ctx: Skein256_Context
        ctx.h.bit_length             = u64(size)
        _hash_impl.internal_ctx      = ctx
        _hash_impl.hash_bytes_slice  = hash_bytes_skein256_odin
        _hash_impl.hash_file_slice   = hash_file_skein256_odin
        _hash_impl.hash_stream_slice = hash_stream_skein256_odin
        _hash_impl.init              = _init_skein256_odin
        _hash_impl.update            = _update_skein256_odin
        _hash_impl.final             = _final_skein256_odin
    }
}

@(private)
_create_skein512_ctx :: #force_inline proc(size: int) {
    _hash_impl.hash_size_val = size
    if _hash_impl.is_using_odin {
        ctx: Skein512_Context
        ctx.h.bit_length             = u64(size)
        _hash_impl.internal_ctx      = ctx
        _hash_impl.hash_bytes_slice  = hash_bytes_skein512_odin
        _hash_impl.hash_file_slice   = hash_file_skein512_odin
        _hash_impl.hash_stream_slice = hash_stream_skein512_odin
        _hash_impl.init              = _init_skein512_odin
        _hash_impl.update            = _update_skein512_odin
        _hash_impl.final             = _final_skein512_odin
    }
}

@(private)
_create_skein1024_ctx :: #force_inline proc(size: int) {
    _hash_impl.hash_size_val = size
    if _hash_impl.is_using_odin {
        ctx: Skein1024_Context
        ctx.h.bit_length             = u64(size)
        _hash_impl.internal_ctx      = ctx
        _hash_impl.hash_bytes_slice  = hash_bytes_skein1024_odin
        _hash_impl.hash_file_slice   = hash_file_skein1024_odin
        _hash_impl.hash_stream_slice = hash_stream_skein1024_odin
        _hash_impl.init              = _init_skein1024_odin
        _hash_impl.update            = _update_skein1024_odin
        _hash_impl.final             = _final_skein1024_odin
    }
}

/*
    High level API
*/

// hash_skein256_bytes will hash the given input and return the
// computed hash
hash_skein256_bytes :: proc(data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    _create_skein256_ctx(bit_size)
    return _hash_impl->hash_bytes_slice(data, bit_size, allocator)
}

// hash_skein256_stream will read the stream in chunks and compute a
// hash from its contents
hash_skein256_stream :: proc(s: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    _create_skein256_ctx(bit_size)
    return _hash_impl->hash_stream_slice(s, bit_size, allocator)
}

// hash_skein256_file will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_skein256_file :: proc(path: string, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    _create_skein256_ctx(bit_size)
    return _hash_impl->hash_file_slice(path, bit_size, allocator)
}

hash_skein256 :: proc {
    hash_skein256_stream,
    hash_skein256_file,
    hash_skein256_bytes,
}

// hash_skein512_bytes will hash the given input and return the
// computed hash
hash_skein512_bytes :: proc(data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    _create_skein512_ctx(bit_size)
    return _hash_impl->hash_bytes_slice(data, bit_size, allocator)
}

// hash_skein512_stream will read the stream in chunks and compute a
// hash from its contents
hash_skein512_stream :: proc(s: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    _create_skein512_ctx(bit_size)
    return _hash_impl->hash_stream_slice(s, bit_size, allocator)
}

// hash_skein512_file will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_skein512_file :: proc(path: string, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    _create_skein512_ctx(bit_size)
    return _hash_impl->hash_file_slice(path, bit_size, allocator)
}

hash_skein512 :: proc {
    hash_skein512_stream,
    hash_skein512_file,
    hash_skein512_bytes,
}

// hash_skein1024_bytes will hash the given input and return the
// computed hash
hash_skein1024_bytes :: proc(data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    _create_skein1024_ctx(bit_size)
    return _hash_impl->hash_bytes_slice(data, bit_size, allocator)
}

// hash_skein1024_stream will read the stream in chunks and compute a
// hash from its contents
hash_skein1024_stream :: proc(s: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    _create_skein1024_ctx(bit_size)
    return _hash_impl->hash_stream_slice(s, bit_size, allocator)
}

// hash_skein1024_file will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_skein1024_file :: proc(path: string, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    _create_skein1024_ctx(bit_size)
    return _hash_impl->hash_file_slice(path, bit_size, allocator)
}

hash_skein1024 :: proc {
    hash_skein1024_stream,
    hash_skein1024_file,
    hash_skein1024_bytes,
}

/*
    Low level API
*/

hash_bytes_skein256_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
        return hash
    } else {
        delete(hash)
        return nil
    }
}

hash_stream_skein256_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                update_odin(&c, buf[:read])
            } 
        }
        final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        delete(hash)
        return nil, os.Errno(-1)
    }
}

hash_file_skein256_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_skein256_odin(ctx, os.stream_from_handle(hd), bit_size, allocator)
    } else {
        return nil, err
    }
}

hash_bytes_skein512_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
        return hash
    } else {
        delete(hash)
        return nil
    }
}

hash_stream_skein512_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                update_odin(&c, buf[:read])
            } 
        }
        final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        delete(hash)
        return nil, os.Errno(-1)
    }
}

hash_file_skein512_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_skein512_odin(ctx, os.stream_from_handle(hd), bit_size, allocator)
    } else {
        return nil, err
    }
}

hash_bytes_skein1024_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
        return hash
    } else {
        delete(hash)
        return nil
    }
}

hash_stream_skein1024_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                update_odin(&c, buf[:read])
            } 
        }
        final_odin(&c, hash[:])
        return hash, os.ERROR_NONE
    } else {
        delete(hash)
        return nil, os.Errno(-1)
    }
}

hash_file_skein1024_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string, bit_size: int, allocator := context.allocator) -> ([]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_skein1024_odin(ctx, os.stream_from_handle(hd), bit_size, allocator)
    } else {
        return nil, err
    }
}

init :: proc(ctx: ^ctx.Hash_Context) {
    _hash_impl->init()
}

update :: proc(ctx: ^ctx.Hash_Context, data: []byte) {
    _hash_impl->update(data)
}

final :: proc(ctx: ^ctx.Hash_Context, hash: []byte) {
    _hash_impl->final(hash)
}

@(private)
_init_skein256_odin :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    _create_skein256_ctx(ctx.hash_size_val)
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_skein256_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_skein256_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        final_odin(&c, hash)
    }
}

@(private)
_init_skein512_odin :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    _create_skein512_ctx(ctx.hash_size_val)
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_skein512_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_skein512_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        final_odin(&c, hash)
    }
}

@(private)
_init_skein1024_odin :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    _create_skein1024_ctx(ctx.hash_size_val)
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_skein1024_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_skein1024_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        final_odin(&c, hash)
    }
}

/*
    SKEIN implementation
*/

SKEIN_MODIFIER_WORDS :: 2

STATE_WORDS_256  :: 4
STATE_WORDS_512  :: 8
STATE_WORDS_1024 :: 16

STATE_BYTES_256  :: 32
STATE_BYTES_512  :: 64
STATE_BYTES_1024 :: 128

BLOCK_BYTES_256  :: 32
BLOCK_BYTES_512  :: 64
BLOCK_BYTES_1024 :: 128

ROUNDS_TOTAL_256  :: 72
ROUNDS_TOTAL_512  :: 72
ROUNDS_TOTAL_1024 :: 80

R_256 := [16]u64 {
     5, 56, 36, 28, 13, 46, 58, 44,
    26, 20, 53, 35, 11, 42, 59, 50,
}

R_512 := [32]u64 {
    38, 30, 50, 53, 48, 20, 43, 31,
    34, 14, 15, 27, 26, 12, 58,  7,
    33, 49,  8, 42, 39, 27, 41, 14,
    29, 26, 11,  9, 33, 51, 39, 35,
}

R_1024 := [64]u64 {
    55, 43, 37, 40, 16, 22, 38, 12,
    25, 25, 46, 13, 14, 13, 52, 57,
    33,  8, 18, 57, 21, 12, 32, 54,
    34, 43, 25, 60, 44,  9, 59, 34,
    28,  7, 47, 48, 51,  9, 35, 41,
    17,  6, 18, 25, 43, 42, 40, 15,
    58,  7, 32, 45, 19, 18,  2, 56,
    47, 49, 27, 58, 37, 48, 53, 56,
}

SKEIN_INJECT_KEY :: #force_inline proc (r: int, WCNT: u64, X, ks, ts: []u64) {
    for i := u64(0); i < WCNT; i += 1 {
        X[i] += ks[(u64(r) + i) % (WCNT + 1)]
    }
    X[WCNT - 3] += ts[(r + 0) % 3]
    X[WCNT - 2] += ts[(r + 1) % 3]
    X[WCNT - 1] += u64(r)
}

block :: proc (ctx: ^$T, blkPtr: []byte, blkCnt, byteCntAdd: u64) {
    blkPtr, blkCnt := blkPtr, blkCnt
    when T == Skein256_Context {
        WCNT :: STATE_WORDS_256
    } else when T == Skein512_Context {
        WCNT :: STATE_WORDS_512
    } else when T == Skein1024_Context {
        WCNT :: STATE_WORDS_1024
    }

    ts: [3]u64
    X:  [WCNT]u64
    w:  [WCNT]u64
    ks := make([]u64, WCNT + 1)
    defer delete(ks)

    for blkCnt != 0 {
        ctx.h.T[0] += byteCntAdd
        ks[WCNT] = 0x55555555 + (0x55555555 << 32)
        for i := u64(0); i < WCNT; i += 1 {
            ks[i] = ctx.X[i]
            ks[WCNT] ~= ctx.X[i]
        }

        ts[0] = ctx.h.T[0]
        ts[1] = ctx.h.T[1]
        ts[2] = ts[0] ~ ts[1]

        mem.copy(&w[0], &blkPtr[0], int(8 * WCNT))

        for i := 0; i < WCNT; i += 1 {
            X[i] = w[i] + ks[i]
        }

        X[WCNT - 3] += ts[0]
        X[WCNT - 2] += ts[1]

        when T == Skein256_Context {
            for r := 1; r <= ROUNDS_TOTAL_256 / 8; r += 1 {
                X[0] += X[1]; X[1] = util.ROTL64(X[1], R_256[ 0]); X[1] ~= X[0]
                X[2] += X[3]; X[3] = util.ROTL64(X[3], R_256[ 1]); X[3] ~= X[2]

                X[0] += X[3]; X[3] = util.ROTL64(X[3], R_256[ 2]); X[3] ~= X[0]
                X[2] += X[1]; X[1] = util.ROTL64(X[1], R_256[ 3]); X[1] ~= X[2]

                X[0] += X[1]; X[1] = util.ROTL64(X[1], R_256[ 4]); X[1] ~= X[0]
                X[2] += X[3]; X[3] = util.ROTL64(X[3], R_256[ 5]); X[3] ~= X[2]

                X[0] += X[3]; X[3] = util.ROTL64(X[3], R_256[ 6]); X[3] ~= X[0]
                X[2] += X[1]; X[1] = util.ROTL64(X[1], R_256[ 7]); X[1] ~= X[2]
                SKEIN_INJECT_KEY(2 * r - 1, WCNT, X[:], ks[:], ts[:])

                X[0] += X[1]; X[1] = util.ROTL64(X[1], R_256[ 8]); X[1] ~= X[0]
                X[2] += X[3]; X[3] = util.ROTL64(X[3], R_256[ 9]); X[3] ~= X[2]

                X[0] += X[3]; X[3] = util.ROTL64(X[3], R_256[10]); X[3] ~= X[0]
                X[2] += X[1]; X[1] = util.ROTL64(X[1], R_256[11]); X[1] ~= X[2]

                X[0] += X[1]; X[1] = util.ROTL64(X[1], R_256[12]); X[1] ~= X[0]
                X[2] += X[3]; X[3] = util.ROTL64(X[3], R_256[13]); X[3] ~= X[2]

                X[0] += X[3]; X[3] = util.ROTL64(X[3], R_256[14]); X[3] ~= X[0]
                X[2] += X[1]; X[1] = util.ROTL64(X[1], R_256[15]); X[1] ~= X[2]
                SKEIN_INJECT_KEY(2 * r, WCNT, X[:], ks[:], ts[:])
            }   
        } else when T == Skein512_Context {
            for r := 1; r <= ROUNDS_TOTAL_512 / 8; r += 1 {
                X[0] += X[1]; X[1] = util.ROTL64(X[1], R_512[ 0]); X[1] ~= X[0]
                X[2] += X[3]; X[3] = util.ROTL64(X[3], R_512[ 1]); X[3] ~= X[2]
                X[4] += X[5]; X[5] = util.ROTL64(X[5], R_512[ 2]); X[5] ~= X[4]
                X[6] += X[7]; X[7] = util.ROTL64(X[7], R_512[ 3]); X[7] ~= X[6]

                X[2] += X[1]; X[1] = util.ROTL64(X[1], R_512[ 4]); X[1] ~= X[2]
                X[4] += X[7]; X[7] = util.ROTL64(X[7], R_512[ 5]); X[7] ~= X[4]
                X[6] += X[5]; X[5] = util.ROTL64(X[5], R_512[ 6]); X[5] ~= X[6]
                X[0] += X[3]; X[3] = util.ROTL64(X[3], R_512[ 7]); X[3] ~= X[0]

                X[4] += X[1]; X[1] = util.ROTL64(X[1], R_512[ 8]); X[1] ~= X[4]
                X[6] += X[3]; X[3] = util.ROTL64(X[3], R_512[ 9]); X[3] ~= X[6]
                X[0] += X[5]; X[5] = util.ROTL64(X[5], R_512[10]); X[5] ~= X[0]
                X[2] += X[7]; X[7] = util.ROTL64(X[7], R_512[11]); X[7] ~= X[2]

                X[6] += X[1]; X[1] = util.ROTL64(X[1], R_512[12]); X[1] ~= X[6]
                X[0] += X[7]; X[7] = util.ROTL64(X[7], R_512[13]); X[7] ~= X[0]
                X[2] += X[5]; X[5] = util.ROTL64(X[5], R_512[14]); X[5] ~= X[2]
                X[4] += X[3]; X[3] = util.ROTL64(X[3], R_512[15]); X[3] ~= X[4]
                SKEIN_INJECT_KEY(2 * r - 1, WCNT, X[:], ks[:], ts[:])

                X[0] += X[1]; X[1] = util.ROTL64(X[1], R_512[16]); X[1] ~= X[0]
                X[2] += X[3]; X[3] = util.ROTL64(X[3], R_512[17]); X[3] ~= X[2]
                X[4] += X[5]; X[5] = util.ROTL64(X[5], R_512[18]); X[5] ~= X[4]
                X[6] += X[7]; X[7] = util.ROTL64(X[7], R_512[19]); X[7] ~= X[6]

                X[2] += X[1]; X[1] = util.ROTL64(X[1], R_512[20]); X[1] ~= X[2]
                X[4] += X[7]; X[7] = util.ROTL64(X[7], R_512[21]); X[7] ~= X[4]
                X[6] += X[5]; X[5] = util.ROTL64(X[5], R_512[22]); X[5] ~= X[6]
                X[0] += X[3]; X[3] = util.ROTL64(X[3], R_512[23]); X[3] ~= X[0]

                X[4] += X[1]; X[1] = util.ROTL64(X[1], R_512[24]); X[1] ~= X[4]
                X[6] += X[3]; X[3] = util.ROTL64(X[3], R_512[25]); X[3] ~= X[6]
                X[0] += X[5]; X[5] = util.ROTL64(X[5], R_512[26]); X[5] ~= X[0]
                X[2] += X[7]; X[7] = util.ROTL64(X[7], R_512[27]); X[7] ~= X[2]

                X[6] += X[1]; X[1] = util.ROTL64(X[1], R_512[28]); X[1] ~= X[6]
                X[0] += X[7]; X[7] = util.ROTL64(X[7], R_512[29]); X[7] ~= X[0]
                X[2] += X[5]; X[5] = util.ROTL64(X[5], R_512[30]); X[5] ~= X[2]
                X[4] += X[3]; X[3] = util.ROTL64(X[3], R_512[31]); X[3] ~= X[4]
                SKEIN_INJECT_KEY(2 * r, WCNT, X[:], ks[:], ts[:])
            }
        } else when T == Skein1024_Context {
            for r := 1; r <= ROUNDS_TOTAL_1024 / 8; r += 1 {
                X[ 0] += X[ 1]; X[ 1] = util.ROTL64(X[ 1], R_1024[ 0]); X[ 1] ~= X[ 0]
                X[ 2] += X[ 3]; X[ 3] = util.ROTL64(X[ 3], R_1024[ 1]); X[ 3] ~= X[ 2]
                X[ 4] += X[ 5]; X[ 5] = util.ROTL64(X[ 5], R_1024[ 2]); X[ 5] ~= X[ 4]
                X[ 6] += X[ 7]; X[ 7] = util.ROTL64(X[ 7], R_1024[ 3]); X[ 7] ~= X[ 6]
                X[ 8] += X[ 9]; X[ 9] = util.ROTL64(X[ 9], R_1024[ 4]); X[ 9] ~= X[ 8]
                X[10] += X[11]; X[11] = util.ROTL64(X[11], R_1024[ 5]); X[11] ~= X[10]
                X[12] += X[13]; X[13] = util.ROTL64(X[13], R_1024[ 6]); X[13] ~= X[12]
                X[14] += X[15]; X[15] = util.ROTL64(X[15], R_1024[ 7]); X[15] ~= X[14]

                X[ 0] += X[ 9]; X[ 9] = util.ROTL64(X[ 9], R_1024[ 8]); X[ 9] ~= X[ 0]
                X[ 2] += X[13]; X[13] = util.ROTL64(X[13], R_1024[ 9]); X[13] ~= X[ 2]
                X[ 6] += X[11]; X[11] = util.ROTL64(X[11], R_1024[10]); X[11] ~= X[ 6]
                X[ 4] += X[15]; X[15] = util.ROTL64(X[15], R_1024[11]); X[15] ~= X[ 4]
                X[10] += X[ 7]; X[ 7] = util.ROTL64(X[ 7], R_1024[12]); X[ 7] ~= X[10]
                X[12] += X[ 3]; X[ 3] = util.ROTL64(X[ 3], R_1024[13]); X[ 3] ~= X[12]
                X[14] += X[ 5]; X[ 5] = util.ROTL64(X[ 5], R_1024[14]); X[ 5] ~= X[14]
                X[ 8] += X[ 1]; X[ 1] = util.ROTL64(X[ 1], R_1024[15]); X[ 1] ~= X[ 8]

                X[ 0] += X[ 7]; X[ 7] = util.ROTL64(X[ 7], R_1024[16]); X[ 7] ~= X[ 0]
                X[ 2] += X[ 5]; X[ 5] = util.ROTL64(X[ 5], R_1024[17]); X[ 5] ~= X[ 2]
                X[ 4] += X[ 3]; X[ 3] = util.ROTL64(X[ 3], R_1024[18]); X[ 3] ~= X[ 4]
                X[ 6] += X[ 1]; X[ 1] = util.ROTL64(X[ 1], R_1024[19]); X[ 1] ~= X[ 6]
                X[12] += X[15]; X[15] = util.ROTL64(X[15], R_1024[20]); X[15] ~= X[12]
                X[14] += X[13]; X[13] = util.ROTL64(X[13], R_1024[21]); X[13] ~= X[14]
                X[ 8] += X[11]; X[11] = util.ROTL64(X[11], R_1024[22]); X[11] ~= X[ 8]
                X[10] += X[ 9]; X[ 9] = util.ROTL64(X[ 9], R_1024[23]); X[ 9] ~= X[10]
                                                                                
                X[ 0] += X[15]; X[15] = util.ROTL64(X[15], R_1024[24]); X[15] ~= X[ 0]
                X[ 2] += X[11]; X[11] = util.ROTL64(X[11], R_1024[25]); X[11] ~= X[ 2]
                X[ 6] += X[13]; X[13] = util.ROTL64(X[13], R_1024[26]); X[13] ~= X[ 6]
                X[ 4] += X[ 9]; X[ 9] = util.ROTL64(X[ 9], R_1024[27]); X[ 9] ~= X[ 4]
                X[14] += X[ 1]; X[ 1] = util.ROTL64(X[ 1], R_1024[28]); X[ 1] ~= X[14]
                X[ 8] += X[ 5]; X[ 5] = util.ROTL64(X[ 5], R_1024[29]); X[ 5] ~= X[ 8]
                X[10] += X[ 3]; X[ 3] = util.ROTL64(X[ 3], R_1024[30]); X[ 3] ~= X[10]
                X[12] += X[ 7]; X[ 7] = util.ROTL64(X[ 7], R_1024[31]); X[ 7] ~= X[12]
                SKEIN_INJECT_KEY(2 * r - 1, WCNT, X[:], ks[:], ts[:])

                X[ 0] += X[ 1]; X[ 1] = util.ROTL64(X[ 1], R_1024[32]); X[ 1] ~= X[ 0]
                X[ 2] += X[ 3]; X[ 3] = util.ROTL64(X[ 3], R_1024[33]); X[ 3] ~= X[ 2]
                X[ 4] += X[ 5]; X[ 5] = util.ROTL64(X[ 5], R_1024[34]); X[ 5] ~= X[ 4]
                X[ 6] += X[ 7]; X[ 7] = util.ROTL64(X[ 7], R_1024[35]); X[ 7] ~= X[ 6]
                X[ 8] += X[ 9]; X[ 9] = util.ROTL64(X[ 9], R_1024[36]); X[ 9] ~= X[ 8]
                X[10] += X[11]; X[11] = util.ROTL64(X[11], R_1024[37]); X[11] ~= X[10]
                X[12] += X[13]; X[13] = util.ROTL64(X[13], R_1024[38]); X[13] ~= X[12]
                X[14] += X[15]; X[15] = util.ROTL64(X[15], R_1024[39]); X[15] ~= X[14]

                X[ 0] += X[ 9]; X[ 9] = util.ROTL64(X[ 9], R_1024[40]); X[ 9] ~= X[ 0]
                X[ 2] += X[13]; X[13] = util.ROTL64(X[13], R_1024[41]); X[13] ~= X[ 2]
                X[ 6] += X[11]; X[11] = util.ROTL64(X[11], R_1024[42]); X[11] ~= X[ 6]
                X[ 4] += X[15]; X[15] = util.ROTL64(X[15], R_1024[43]); X[15] ~= X[ 4]
                X[10] += X[ 7]; X[ 7] = util.ROTL64(X[ 7], R_1024[44]); X[ 7] ~= X[10]
                X[12] += X[ 3]; X[ 3] = util.ROTL64(X[ 3], R_1024[45]); X[ 3] ~= X[12]
                X[14] += X[ 5]; X[ 5] = util.ROTL64(X[ 5], R_1024[46]); X[ 5] ~= X[14]
                X[ 8] += X[ 1]; X[ 1] = util.ROTL64(X[ 1], R_1024[47]); X[ 1] ~= X[ 8]

                X[ 0] += X[ 7]; X[ 7] = util.ROTL64(X[ 7], R_1024[48]); X[ 7] ~= X[ 0]
                X[ 2] += X[ 5]; X[ 5] = util.ROTL64(X[ 5], R_1024[49]); X[ 5] ~= X[ 2]
                X[ 4] += X[ 3]; X[ 3] = util.ROTL64(X[ 3], R_1024[50]); X[ 3] ~= X[ 4]
                X[ 6] += X[ 1]; X[ 1] = util.ROTL64(X[ 1], R_1024[51]); X[ 1] ~= X[ 6]
                X[12] += X[15]; X[15] = util.ROTL64(X[15], R_1024[52]); X[15] ~= X[12]
                X[14] += X[13]; X[13] = util.ROTL64(X[13], R_1024[53]); X[13] ~= X[14]
                X[ 8] += X[11]; X[11] = util.ROTL64(X[11], R_1024[54]); X[11] ~= X[ 8]
                X[10] += X[ 9]; X[ 9] = util.ROTL64(X[ 9], R_1024[55]); X[ 9] ~= X[10]
                                                                                
                X[ 0] += X[15]; X[15] = util.ROTL64(X[15], R_1024[56]); X[15] ~= X[ 0]
                X[ 2] += X[11]; X[11] = util.ROTL64(X[11], R_1024[57]); X[11] ~= X[ 2]
                X[ 6] += X[13]; X[13] = util.ROTL64(X[13], R_1024[58]); X[13] ~= X[ 6]
                X[ 4] += X[ 9]; X[ 9] = util.ROTL64(X[ 9], R_1024[59]); X[ 9] ~= X[ 4]
                X[14] += X[ 1]; X[ 1] = util.ROTL64(X[ 1], R_1024[60]); X[ 1] ~= X[14]
                X[ 8] += X[ 5]; X[ 5] = util.ROTL64(X[ 5], R_1024[61]); X[ 5] ~= X[ 8]
                X[10] += X[ 3]; X[ 3] = util.ROTL64(X[ 3], R_1024[62]); X[ 3] ~= X[10]
                X[12] += X[ 7]; X[ 7] = util.ROTL64(X[ 7], R_1024[63]); X[ 7] ~= X[12]
                SKEIN_INJECT_KEY(2 * r, WCNT, X[:], ks[:], ts[:])
            }
        }

        for i := 0; i < WCNT; i += 1 {
            ctx.X[i] = X[i] ~ w[i]
        }
        SKEIN_CLEAR_FIRST_FLAG(ctx)

        when T == Skein256_Context {
            blkPtr = blkPtr[BLOCK_BYTES_256:]
        } else when T == Skein512_Context {
            blkPtr = blkPtr[BLOCK_BYTES_512:]
        } else when T == Skein1024_Context {
            blkPtr = blkPtr[BLOCK_BYTES_1024:]
        }
        
        blkCnt -= 1
    }
}

Skein_Header :: struct {
    bit_length: u64,
    bCnt:      u64,
    T:         [SKEIN_MODIFIER_WORDS]u64,
}

Skein256_Context :: struct {
    h: Skein_Header,
    X: [STATE_WORDS_256]u64,
    b: [STATE_BYTES_256]byte,
}

Skein512_Context :: struct {
    h: Skein_Header,
    X: [STATE_WORDS_512]u64,
    b: [STATE_BYTES_512]byte,
}

Skein1024_Context :: struct {
    h: Skein_Header,
    X: [STATE_WORDS_1024]u64,
    b: [STATE_BYTES_1024]byte,
}

SKEIN_CLEAR_FIRST_FLAG :: #force_inline proc (ctx: ^$T) {
    sk1: u64 = u64(1) << (126 - 64)
    ctx.h.T[1] &= ~u64(i32(sk1))
}

SKEIN_START_NEW_TYPE_CFG_FINAL :: #force_inline proc (ctx: ^$T) {
    ctx.h.T[0] = 0
    sk1 : u64 = u64(1) << (126 - 64)
    sk2 : u64 = u64(4) << (120 - 64)
    sk3 : u64 = u64(1) << (127 - 64)
    ctx.h.T[1] = u64(i32(sk1)) | u64(i32(sk2)) | u64(i32(sk3))
    ctx.h.bCnt = 0
}

SKEIN_START_NEW_TYPE_MSG :: #force_inline proc (ctx: ^$T) {
    ctx.h.T[0] = 0
    sk1 : u64 = u64( 1) << (126 - 64)
    sk2 : u64 = u64(48) << (120 - 64)
    ctx.h.T[1] = u64(i32(sk1)) | u64(i32(sk2))
    ctx.h.bCnt = 0
}

SKEIN_START_NEW_TYPE_OUT_FINAL :: #force_inline proc (ctx: ^$T) {
    ctx.h.T[0] = 0
    sk1 : u64 = u64(1) << (126 - 64)
    sk2 : u64 = u64(63) << (120 - 64)
    sk3 : u64 = u64(1) << (127 - 64)
    ctx.h.T[1] = u64(i32(sk1)) | u64(i32(sk2)) | u64(i32(sk3))
    ctx.h.bCnt = 0
}

skein_put64_lsb_first :: #force_inline proc (dst: []byte src: []u64, bCnt: u64) {
    for i := u64(0); i < bCnt; i += 1 {
        dst[i] = byte(src[i >> 3] >> (8 * (i & 7)))
    }
}

skein_swap64 :: #force_inline proc (w64: u64) -> u64 {
    when ODIN_ENDIAN == "little" {
        return w64
    } else {
        return  (( w64        & 0xff) << 56) |
                (((w64 >>  8) & 0xff) << 48) |
                (((w64 >> 16) & 0xff) << 40) |
                (((w64 >> 24) & 0xff) << 32) |
                (((w64 >> 32) & 0xff) << 24) |
                (((w64 >> 40) & 0xff) << 16) |
                (((w64 >> 48) & 0xff) <<  8) |
                (((w64 >> 56) & 0xff)      )
    }
}

init_odin :: proc(ctx: ^$T) {
    when T == Skein256_Context {
        cfg: struct #raw_union {
            b: [STATE_BYTES_256]byte,
            w: [STATE_WORDS_256]u64,
        }
    } else when T == Skein512_Context {
        cfg: struct #raw_union {
            b: [STATE_BYTES_512]byte,
            w: [STATE_WORDS_512]u64,
        }
    } else when T == Skein1024_Context {
        cfg: struct #raw_union {
            b: [STATE_BYTES_1024]byte,
            w: [STATE_WORDS_1024]u64,
        }
    }

    SKEIN_START_NEW_TYPE_CFG_FINAL(ctx)
 
    sk1 := u64(1) << 32
    cfg.w[0] = skein_swap64(0x33414853 + u64(i32(sk1)))
    cfg.w[1] = skein_swap64(ctx.h.bit_length)
    cfg.w[2] = skein_swap64(0)

    block(ctx, cfg.b[:], 1, 32)
    SKEIN_START_NEW_TYPE_MSG(ctx)
}

update_odin :: proc(ctx: ^$T, data: []byte) {
    msgByteCnt := u64(len(data))
    n: u64
    data := data
    when T == Skein256_Context {
        block_bytes :: 32
    } else when T == Skein512_Context {
        block_bytes :: 64
    } else when T == Skein1024_Context {
        block_bytes :: 128
    }

    if msgByteCnt + ctx.h.bCnt > block_bytes {
        if ctx.h.bCnt != 0 {
            n = block_bytes - ctx.h.bCnt
            if n != 0 {
                copy(ctx.b[ctx.h.bCnt:], data[:n])
                msgByteCnt -= n
                data = data[n:]
                ctx.h.bCnt += n
            }
            block(ctx, ctx.b[:], 1, block_bytes)
            ctx.h.bCnt = 0
        }

        if msgByteCnt > block_bytes {
            n = (msgByteCnt - 1) / block_bytes
            block(ctx, data, n, block_bytes)
            msgByteCnt -= n * block_bytes
            data = data[n * block_bytes:]
        }

        if msgByteCnt != 0 {
            copy(ctx.b[ctx.h.bCnt:], data[:msgByteCnt])
            ctx.h.bCnt += msgByteCnt
        }
    }
}

final_odin :: proc(ctx: ^$T, hash: []byte) {
    n, byteCnt: u64

    when T == Skein256_Context {
        block_bytes :: 32
        X: [STATE_WORDS_256]u64
    } else when T == Skein512_Context {
        block_bytes :: 64
        X: [STATE_WORDS_512]u64
    } else when T == Skein1024_Context {
        block_bytes :: 128
        X: [STATE_WORDS_1024]u64
    }

    sk1: u64 = u64(1) << (127 - 64)
    ctx.h.T[1] |= u64(i32(sk1))

    block(ctx, ctx.b[:], 1, ctx.h.bCnt)
    byteCnt = (ctx.h.bit_length + 7) >> 3

    copy(X[:], ctx.X[:])

    for i := u64(0); i * block_bytes < byteCnt; i += 1 {
        (^u64)(&ctx.b[0])^ = skein_swap64(u64(i))
        SKEIN_START_NEW_TYPE_OUT_FINAL(ctx)
        block(ctx, ctx.b[:], 1, size_of(u64))
        n = byteCnt - i * block_bytes
        if n >= block_bytes {
            n = block_bytes
        }
        skein_put64_lsb_first(hash[i * block_bytes:], ctx.X[:], n)
        copy(ctx.X[:], X[:])
    }
}