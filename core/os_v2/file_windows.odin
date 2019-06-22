package os_v2

import "core:mem"
import "core:time"

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

@(private)
@(default_calling_convention="stdcall")
foreign kernel32 {
	GetStdHandle :: proc(nStdHandle: u32) -> rawptr ---
}


stdin  := File(GetStdHandle(~u32(0)-10));
stdout := File(GetStdHandle(~u32(0)-11));
stderr := File(GetStdHandle(~u32(0)-12));



open :: proc(path: string, flags := File_Flags{.Read}, perm: File_Mode = 0) -> (f: File, err: Error) {
	if flags == nil do flags = {.Read};

	return 0, nil;
}

create :: proc(path: string) -> (f: File, err: Error) {
	return open(path, {.Read, .Write, .Create, .Truncate}, 0o666);
}

close :: proc(f: File) -> (err: Error) {
	if f == 0 {
		err = .Invalid;
		return;
	}
	// if is_directory(f) {
	// 	return;
	// }
	if ok := CloseHandle(rawptr(f)); !ok {
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


seek :: proc(f: File, offset: i64, whence: int) -> (n: i64, err: Error) {
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
	ft := GetFileType(rawptr(f));
	if ft == FILE_TYPE_PIPE {
		return 0, Error.File_Is_Pipe;
	}

	dw_ptr := SetFilePointer(rawptr(f), lo, &hi, w);
	if dw_ptr == INVALID_SET_FILE_POINTER {
		last_error := GetLastError();
		err: Error;
		return 0, err;
	}
	return i64(hi)<<32 + i64(dw_ptr), nil;
}

read :: proc(f: File, data: []byte) -> (n: int, err: Error) {
	if len(data) == 0 do return;

	single_read_length: i32;
	total_read: i64;
	length := i64(len(data));

	for total_read < length {
		remaining := length - total_read;
		to_read: u32 = min(u32(remaining), max(u32));

		e := ReadFile(rawptr(f), &data[total_read], to_read, &single_read_length, nil);
		if single_read_length <= 0 || !e {
			last_error := GetLastError();
			err: Error;
			return int(total_read), err;
		}
		total_read += i64(single_read_length);
	}
	return int(total_read), nil;
}



read_at :: proc(f: File, data: []byte, offset: i64) -> (n: int, err: Error) {
	prev: i64;
	prev, err = seek(f, offset, SEEK_CURRENT);
	if err != nil {
		return 0, err;
	}

	n, err = read(f, data);
	if err != nil {
		_, _ = seek(f, prev, SEEK_BEGIN);
		return;
	}

	_, err = seek(f, prev, SEEK_BEGIN);
	// NOTE(bill): No need to check 'err'
	return;
}


file_size :: proc(f: File) -> (i64, Error) {
	// TODO(bill): file_size for windows
	return 0, nil;
}



write :: proc(f: File, data: []byte) -> (n: int, err: Error) {
	if len(data) == 0 do return;

	single_write_length: i32;
	total_write: i64;
	length := i64(len(data));

	for total_write < length {
		remaining := length - total_write;
		to_write := u32(min(i32(remaining), max(i32)));

		e := WriteFile(rawptr(f), &data[total_write], to_write, &single_write_length, nil);
		if single_write_length <= 0 || !e {
			last_error := GetLastError();
			err: Error;
			return int(total_write), err;
		}
		total_write += i64(single_write_length);
	}
	return int(total_write), nil;
}

write_at :: proc(f: File, data: []byte, offset: i64) -> (n: int, err: Error) {
	prev: i64;
	prev, err = seek(f, offset, SEEK_CURRENT);
	if err != nil {
		return 0, err;
	}

	n, err = write(f, data);
	if err != nil {
		_, _ = seek(f, prev, SEEK_BEGIN);
		return;
	}

	_, err = seek(f, prev, SEEK_BEGIN);
	// NOTE(bill): No need to check 'err'
	return;
}


truncate :: proc(fd: File, size: i64) -> Error {
	return nil;
}

sync :: proc(f: File) -> Error {
	return nil;
}

remove :: proc(name: string) -> Error {
	return nil;
}

pipe :: proc() -> (r, w: File, err: Error) {
	return 0, 0, nil;
}

link :: proc(old_name, new_name: string) -> Error {
	return nil;
}

symlink :: proc(old_name, new_name: string) -> Error {
	return nil;
}

read_link :: proc(name: string) -> (string, Error) {
	return "", nil;
}


change_mode :: proc(f: File, mode: File_Mode) -> Error {
	return nil;
}

change_ownership :: proc(f: File, uid, gid: int) -> Error {
	return .Platform_Specific;
}

change_ownership_link :: proc(f: File, uid, gid: int) -> Error {
	return .Platform_Specific;
}

change_times :: proc(name: string, atime, mtime: time.Time) -> Error {
	return nil;
}














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
