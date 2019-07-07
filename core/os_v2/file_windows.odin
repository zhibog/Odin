package os_v2

import "core:mem"
import "core:time"
import win32 "os_win32"


stdin  := File(win32.GetStdHandle(~u32(0)-10));
stdout := File(win32.GetStdHandle(~u32(0)-11));
stderr := File(win32.GetStdHandle(~u32(0)-12));



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
	if ok := win32.CloseHandle(rawptr(f)); !ok {
		err = .Invalid;
		switch gle := win32.GetLastError(); gle {
		// TODO(bill): Handle cases
		}
	}
	return;
}


rename :: proc(oldpath, newpath: string) -> Error #no_bounds_check {
	src, _ := win32.utf8_to_utf16_ptr(oldpath);
	dst, _ := win32.utf8_to_utf16_ptr(newpath);
	ok := win32.MoveFileExW(src, dst, win32.MOVEFILE_WRITE_THROUGH | win32.MOVEFILE_REPLACE_EXISTING);
	return ok ? nil : .Invalid;
}


seek :: proc(f: File, offset: i64, whence: int) -> (n: i64, err: Error) {


	w: u32;
	switch whence {
	case 0: w = 0;
	case 1: w = 1;
	case 2: w = 2;
	}
	hi := i32(offset>>32);
	lo := i32(offset);
	ft := win32.GetFileType(rawptr(f));
	if ft == win32.FILE_TYPE_PIPE {
		return 0, .File_Is_Pipe;
	}

	dw_ptr := win32.SetFilePointer(rawptr(f), lo, &hi, w);
	if dw_ptr == win32.INVALID_SET_FILE_POINTER {
		last_error := win32.GetLastError();
		// TODO(bill): convert to Error
		n = 0;
		return;
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

		e := win32.ReadFile(rawptr(f), &data[total_read], to_read, &single_read_length, nil);
		if single_read_length <= 0 || !e {
			last_error := win32.GetLastError();
			n = int(total_read);
			// TODO(bill): convert to Error
			return;
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

		e := win32.WriteFile(rawptr(f), &data[total_write], to_write, &single_write_length, nil);
		if single_write_length <= 0 || !e {
			last_error := win32.GetLastError();
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






