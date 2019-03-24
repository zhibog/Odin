package os_v2

import "core:mem"
import "core:unicode/utf8"

foreign import kernel32 "system:kernel32.lib"

@(private)
CP_UTF8 :: 65001;

@(private)
foreign kernel32 {
	GetLastError   :: proc() -> u32 ---

	ReadFile       :: proc(hFile: rawptr, lpBuffer: rawptr, nNumberOfBytesToRead:  u32, lpNumberOfBytesRead:    ^i32, lpOverlapped: rawptr) -> b32 ---
	WriteFile      :: proc(hFile: rawptr, lpBuffer: rawptr, nNumberOfBytesToWrite: u32, lpNumberOfBytesWritten: ^i32, lpOverlapped: rawptr) -> b32 ---
	CloseHandle    :: proc(hObject: rawptr) -> b32 ---
	GetFileType    :: proc(hFile: rawptr) -> u32 ---
	SetFilePointer :: proc(hFile: rawptr, lo: i32, hi: ^i32, whence: u32) -> u32 ---

	MoveFileExW :: proc(lpExistingFileName, lpNewFileName: ^u16, dwFlags: u32) -> b32 ---

	WideCharToMultiByte :: proc(CodePage: u32, dwFlags: u32,
	                            lpWideCharStr: ^u16, cchWideChar: i32,
	                            lpMultiByteStr: cstring, cbMultiByte: i32,
	                            lpDefaultChar: cstring, lpUsedDefaultChar: ^b32,
	) -> i32 ---
	MultiByteToWideChar :: proc(CodePage: u32, dwFlags: u32,
	                            lpMultiByteStr: cstring, cbMultiByte: i32,
	                            lpWideCharStr: ^u16, cchWideChar: i32,
	) -> i32 ---
}



open :: proc(path: string, options := Open_Options{.Read}, perm: File_Mode = 0) -> (fd: Handle, err: Error) {
	return 0, nil;
}

create :: proc(path: string) -> (fd: Handle, err: Error) {
	return open(path, {.Read, .Write, .Create, .Truncate}, 0o666);
}

close :: proc(fd: Handle) -> (err: Error) {
	if fd == 0 {
		err = .Invalid;
		return;
	}
	// if is_directory(fd) {
	// 	return;
	// }
	if ok := CloseHandle(rawptr(fd)); !ok {
		err = .Invalid;
		switch gle := GetLastError(); gle {
		// TODO(bill): Handle cases
		}
	}
	return;
}


rename :: proc(oldpath, newpath: string) -> Error #no_bounds_check {
	MOVEFILE_REPLACE_EXISTING :: 0x1;
	MOVEFILE_WRITE_THROUGH    :: 0x8;

	src := utf8_to_utf16_ptr(oldpath);
	dst := utf8_to_utf16_ptr(newpath);
	ok := MoveFileExW(src, dst, MOVEFILE_WRITE_THROUGH | MOVEFILE_REPLACE_EXISTING);
	return ok ? nil : .Invalid;
}


seek :: proc(fd: Handle, offset: i64, whence: int) -> (n: i64, err: Error) {
	FILE_TYPE_PIPE :: 0x0003;
	INVALID_SET_FILE_POINTER :: ~u32(0);

	w: u32;
	switch whence {
	case 0: w = 0;
	case 1: w = 1;
	case 2: w = 2;
	}
	hi := i32(offset>>32);
	lo := i32(offset);
	ft := GetFileType(rawptr(fd));
	if ft == FILE_TYPE_PIPE {
		return 0, Error.File_Is_Pipe;
	}

	dw_ptr := SetFilePointer(rawptr(fd), lo, &hi, w);
	if dw_ptr == INVALID_SET_FILE_POINTER {
		last_error := GetLastError();
		err: Error;
		return 0, err;
	}
	return i64(hi)<<32 + i64(dw_ptr), nil;
}

read :: proc(fd: Handle, data: []byte) -> (n: int, err: Error) {
	if len(data) == 0 do return;

	single_read_length: i32;
	total_read: i64;
	length := i64(len(data));

	for total_read < length {
		remaining := length - total_read;
		to_read: u32 = min(u32(remaining), max(u32));

		e := ReadFile(rawptr(fd), &data[total_read], to_read, &single_read_length, nil);
		if single_read_length <= 0 || !e {
			last_error := GetLastError();
			err: Error;
			return int(total_read), err;
		}
		total_read += i64(single_read_length);
	}
	return int(total_read), nil;
}

read_ptr :: proc(fd: Handle, ptr: rawptr, length: int) -> (n: int, err: Error) {
	return read(fd, mem.slice_ptr((^byte)(ptr), length));
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	prev: i64;
	prev, err = seek(fd, offset, SEEK_CURRENT);
	if err != nil {
		return 0, err;
	}

	n, err = read(fd, data);
	if err != nil {
		_, _ = seek(fd, prev, SEEK_BEGIN);
		return;
	}

	_, err = seek(fd, prev, SEEK_BEGIN);
	// NOTE(bill): No need to check 'err'
	return;
}

read_ptr_at :: proc(fd: Handle, ptr: rawptr, length: int, offset: i64) -> (n: int, err: Error) {
	return read_at(fd, mem.slice_ptr((^byte)(ptr), length), offset);
}




write :: proc(fd: Handle, data: []byte) -> (n: int, err: Error) {
	if len(data) == 0 do return;

	single_write_length: i32;
	total_write: i64;
	length := i64(len(data));

	for total_write < length {
		remaining := length - total_write;
		to_write := u32(min(i32(remaining), max(i32)));

		e := WriteFile(rawptr(fd), &data[total_write], to_write, &single_write_length, nil);
		if single_write_length <= 0 || !e {
			last_error := GetLastError();
			err: Error;
			return int(total_write), err;
		}
		total_write += i64(single_write_length);
	}
	return int(total_write), nil;
}

write_ptr :: proc(fd: Handle, ptr: rawptr, length: int) -> (n: int, err: Error) {
	return write(fd, mem.slice_ptr((^byte)(ptr), length));
}

write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	prev: i64;
	prev, err = seek(fd, offset, SEEK_CURRENT);
	if err != nil {
		return 0, err;
	}

	n, err = write(fd, data);
	if err != nil {
		_, _ = seek(fd, prev, SEEK_BEGIN);
		return;
	}

	_, err = seek(fd, prev, SEEK_BEGIN);
	// NOTE(bill): No need to check 'err'
	return;
}

write_ptr_at :: proc(fd: Handle, ptr: rawptr, length: int, offset: i64) -> (n: int, err: Error) {
	return write_at(fd, mem.slice_ptr((^byte)(ptr), length), offset);
}


write_string :: proc(fd: Handle, str: string) -> (n: int, err: Error) {
	return write(fd, ([]byte)(str));
}
write_byte :: proc(fd: Handle, b: byte) -> (n: int, err: Error) {
	return write(fd, []byte{b});
}
write_rune :: proc(fd: Handle, r: rune) -> (n: int, err: Error) {
	if r < utf8.RUNE_SELF {
		return write_byte(fd, byte(r));
	}

	b, w := utf8.encode_rune(r);
	return write(fd, b[:w]);
}



// read_entire_file :: proc(name: string) -> (data: []byte, err: Error) {
// 	fd, err := open(name, O_RDONLY, 0);
// 	if err != 0 {
// 		return nil, err;
// 	}
// 	defer close(fd);

// 	length: i64;
// 	if length, err = file_size(fd); err != 0 {
// 		return nil, err;
// 	}

// 	if length <= 0 {
// 		return nil, nil;
// 	}

// 	data = make([]byte, int(length));
// 	if data == nil {
// 		return nil, err;
// 	}

// 	bytes_read, read_err := read(fd, data);
// 	if read_err != 0 {
// 		delete(data);
// 		return nil, err;
// 	}
// 	return data[0:bytes_read], nill;
// }


// write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (err: Error) {
// 	flags: int = O_WRONLY|O_CREATE;
// 	if truncate {
// 		flags |= O_TRUNC;
// 	}
// 	fd, err := open(name, flags, 0);
// 	if err != 0 {
// 		return false;
// 	}
// 	defer close(fd);

// 	_, write_err := write(fd, data);
// 	return write_err == 0;
// }



utf8_to_utf16 :: proc(str: string, allocator := context.temp_allocator) -> []u16 {
	#no_bounds_check cstr := cstring(&str[0]);
	n := i32(len(str));

	size_needed := MultiByteToWideChar(CP_UTF8, 0, cstr, n, nil, 0);
	buf := make([]u16, size_needed+1, allocator);
	MultiByteToWideChar(CP_UTF8, 0, cstr, n, &buf[0], i32(len(buf)));
	buf[size_needed] = 0;
	return buf[:size_needed];
}
utf16_to_utf8 :: proc(wstr: []u16, allocator := context.temp_allocator) -> string {
	#no_bounds_check pwstr := &wstr[0];
	n := i32(len(wstr));

	size_needed := WideCharToMultiByte(CP_UTF8, 0, pwstr, n, nil, 0, nil, nil);
	buf := make([]u8, size_needed+1, allocator);
	WideCharToMultiByte(CP_UTF8, 0, pwstr, n, cstring(&buf[0]), i32(len(buf)), nil, nil);
	buf[size_needed] = 0;
	return string(buf[:size_needed]);
}

utf8_to_utf16_ptr :: proc(str: string, allocator := context.temp_allocator) -> ^u16 {
	#no_bounds_check cstr := cstring(&str[0]);
	n := i32(len(str));

	size_needed := MultiByteToWideChar(CP_UTF8, 0, cstr, n, nil, 0);
	buf := make([]u16, size_needed+1, allocator);
	MultiByteToWideChar(CP_UTF8, 0, cstr, n, &buf[0], i32(len(buf)));
	buf[size_needed] = 0;
	return &buf[0];
}
utf16_to_utf8_csting :: proc(wstr: []u16, allocator := context.temp_allocator) -> cstring {
	#no_bounds_check pwstr := &wstr[0];
	n := i32(len(wstr));

	size_needed := WideCharToMultiByte(CP_UTF8, 0, pwstr, n, nil, 0, nil, nil);
	buf := make([]u8, size_needed+1, allocator);
	WideCharToMultiByte(CP_UTF8, 0, pwstr, n, cstring(&buf[0]), i32(len(buf)), nil, nil);
	buf[size_needed] = 0;
	return cstring(&buf[0]);
}
