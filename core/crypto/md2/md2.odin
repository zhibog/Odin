package md2

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the MD2 hashing algorithm, as defined in RFC 1319 <https://datatracker.ietf.org/doc/html/rfc1319>
*/

import "core:os"
import "core:io"

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
    } else {
        _assign_hash_vtable(ctx)
    }
    return ctx
}

@(private)
_assign_hash_vtable :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    ctx.hash_bytes_16  = hash_bytes_odin
    ctx.hash_file_16   = hash_file_odin
    ctx.hash_stream_16 = hash_stream_odin
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan does nothing, since MD2 is not available in Botan
@(warning="MD2 is not provided by the Botan API. Odin implementation will be used")
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

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [16]byte {
	_create_md2_ctx()
    return _hash_impl->hash_bytes_16(data)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([16]byte, os.Errno) {
	_create_md2_ctx()
    return _hash_impl->hash_stream_16(s)
}

// hash_file will try to open the file provided by the given
// path and pass it to hash_stream to compute a hash
hash_file :: proc(path: string) -> ([16]byte, os.Errno) {
	_create_md2_ctx()
    return _hash_impl->hash_file_16(path)
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

/*
    MD2 implementation
*/

BLOCK_SIZE :: 16

Md2_Context :: struct {
    data:     [BLOCK_SIZE]byte,
    state:    [BLOCK_SIZE * 3]byte,
    checksum: [BLOCK_SIZE]byte,
    datalen:  int,
}

hash_bytes_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) -> [BLOCK_SIZE]byte {
    hash: [BLOCK_SIZE]byte
    if c, ok := ctx.internal_ctx.(Md2_Context); ok {
    	init_odin(&c)
    	update_odin(&c, data)
    	final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, fs: io.Stream) -> ([BLOCK_SIZE]byte, os.Errno) {
    hash: [BLOCK_SIZE]byte
    if c, ok := ctx.internal_ctx.(Md2_Context); ok {
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
    	return hash, os.Errno(-1)
    }
}

hash_file_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, path: string) -> ([BLOCK_SIZE]byte, os.Errno) {
    if hd, err := os.open(path); err == os.ERROR_NONE {
        return hash_stream_odin(ctx, os.stream_from_handle(hd))
    } else {
        return [BLOCK_SIZE]byte{}, err
    }
}

@(private)
_create_md2_ctx :: #force_inline proc() {
	ctx: Md2_Context
	_hash_impl.internal_ctx = ctx
	_hash_impl.hash_size    = ._16
}

@(private)
_init_odin :: #force_inline proc(ctx: ^ctx.Hash_Context) {
    _create_md2_ctx()
    if c, ok := ctx.internal_ctx.(Md2_Context); ok {
    	init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Md2_Context); ok {
    	update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Md2_Context); ok {
    	final_odin(&c, hash)
    }
}

PI_TABLE := [?]byte {
	41,  46,  67,  201, 162, 216, 124, 1,   61,  54,  84,  161, 236, 240, 6,
	19,  98,  167, 5,   243, 192, 199, 115, 140, 152, 147, 43,  217, 188, 76,
	130, 202, 30,  155, 87,  60,  253, 212, 224, 22,  103, 66,  111, 24,  138, 
	23,  229, 18,  190, 78,  196, 214, 218, 158, 222, 73,  160, 251, 245, 142,
	187, 47,  238, 122, 169, 104, 121, 145, 21,  178, 7,   63,  148, 194, 16,
	137, 11,  34,  95,  33,  128, 127, 93,  154, 90,  144, 50,  39,  53,  62, 
	204, 231, 191, 247, 151, 3,   255, 25,  48,  179, 72,  165, 181, 209, 215,
	94,  146, 42,  172, 86,  170, 198, 79,  184, 56,  210, 150, 164, 125, 182,
	118, 252, 107, 226, 156, 116, 4,   241, 69,  157, 112, 89,  100, 113, 135,
	32,  134, 91,  207, 101, 230, 45,  168, 2,   27,  96,  37,  173, 174, 176,
	185, 246, 28,  70,  97,  105, 52,  64,  126, 15,  85,  71,  163, 35,  221,
	81,  175, 58,  195, 92,  249, 206, 186, 197, 234, 38,  44,  83,  13,  110,
	133, 40,  132, 9,   211, 223, 205, 244, 65,  129, 77,  82,  106, 220, 55,
	200, 108, 193, 171, 250, 36,  225, 123, 8,   12,  189, 177, 74,  120, 136,
	149, 139, 227, 99,  232, 109, 233, 203, 213, 254, 59,  0,   29,  57,  242,
	239, 183, 14,  102, 88,  208, 228, 166, 119, 114, 248, 235, 117, 75,  10,
	49,  68,  80,  180, 143, 237, 31,  26,  219, 153, 141, 51,  159, 17,  131,
	20,
}

transform :: proc(ctx: ^Md2_Context, data: []byte) {
    j,k,t: byte
	for j = 0; j < BLOCK_SIZE; j += 1 {
		ctx.state[j + BLOCK_SIZE] = data[j]
		ctx.state[j + BLOCK_SIZE * 2] = (ctx.state[j + BLOCK_SIZE] ~ ctx.state[j])
	}
	t = 0
	for j = 0; j < BLOCK_SIZE + 2; j += 1 {
		for k = 0; k < BLOCK_SIZE * 3; k += 1 {
			ctx.state[k] ~= PI_TABLE[t]
			t = ctx.state[k]
		}
		t = (t + j) & 0xff
	}
	t = ctx.checksum[BLOCK_SIZE - 1]
	for j = 0; j < BLOCK_SIZE; j += 1 {
		ctx.checksum[j] ~= PI_TABLE[data[j] ~ t]
		t = ctx.checksum[j]
	}
}

init_odin :: proc(ctx: ^Md2_Context) {
	// No action needed here
}

update_odin :: proc(ctx: ^Md2_Context, data: []byte) {
	for i := 0; i < len(data); i += 1 {
		ctx.data[ctx.datalen] = data[i]
		ctx.datalen += 1
		if (ctx.datalen == BLOCK_SIZE) {
			transform(ctx, ctx.data[:])
			ctx.datalen = 0
		}
	}
}

final_odin :: proc(ctx: ^Md2_Context, hash: []byte) {
	to_pad := byte(BLOCK_SIZE - ctx.datalen)
    for ctx.datalen < BLOCK_SIZE {
        ctx.data[ctx.datalen] = to_pad
		ctx.datalen += 1
    }
	transform(ctx, ctx.data[:])
	transform(ctx, ctx.checksum[:])
    for i := 0; i < BLOCK_SIZE; i += 1 {
        hash[i] = ctx.state[i]
    }
}