package os_v2

import "core:unicode/utf8"
import "core:mem"

read_ptr :: proc(f: File, ptr: rawptr, length: int) -> (n: int, err: Error) {
	return read(f, mem.slice_ptr((^byte)(ptr), length));
}

read_ptr_at :: proc(f: File, ptr: rawptr, length: int, offset: i64) -> (n: int, err: Error) {
	return read_at(f, mem.slice_ptr((^byte)(ptr), length), offset);
}


write_ptr :: proc(f: File, ptr: rawptr, length: int) -> (n: int, err: Error) {
	return write(f, mem.slice_ptr((^byte)(ptr), length));
}
write_ptr_at :: proc(f: File, ptr: rawptr, length: int, offset: i64) -> (n: int, err: Error) {
	return write_at(f, mem.slice_ptr((^byte)(ptr), length), offset);
}

write_string :: proc(f: File, str: string) -> (n: int, err: Error) {
	return write(f, ([]byte)(str));
}
write_byte :: proc(f: File, b: byte) -> (n: int, err: Error) {
	return write(f, []byte{b});
}
write_rune :: proc(f: File, r: rune) -> (n: int, err: Error) {
	if r < utf8.RUNE_SELF {
		return write_byte(f, byte(r));
	}

	b, w := utf8.encode_rune(r);
	return write(f, b[:w]);
}



read_entire_file :: proc(name: string) -> (data: []byte, err: Error) {
	f: File;
	f, err = open(name, {.Read}, 0);
	if err != nil {
		return nil, err;
	}
	defer close(f);

	length: i64;
	if length, err = file_size(f); err != nil {
		return nil, err;
	}

	if length <= 0 {
		return nil, nil;
	}

	data = make([]byte, int(length));
	if data == nil {
		return nil, err;
	}

	bytes_read, read_err := read(f, data);
	if read_err != nil {
		delete(data);
		return nil, read_err;
	}
	return data[0:bytes_read], nil;
}


write_entire_file :: proc(name: string, data: []byte, truncate := true) -> Error {
	flags := File_Flags{.Write, .Create};
	if truncate {
		flags |= {.Truncate};
	}
	f, err := open(name, flags, 0);
	if err != nil {
		return err;
	}
	defer close(f);

	_, write_err := write(f, data);
	return write_err;
}

