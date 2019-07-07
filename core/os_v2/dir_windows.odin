package os_v2

import win32 "os_win32"

is_directory :: proc(f: File) -> bool {
	info: win32.BY_HANDLE_FILE_INFORMATION;
	ok := cast(bool)win32.GetFileInformationByHandle(win32.HANDLE(f), &info);
	return ok && info.dwFileAttributes & win32.FILE_ATTRIBUTE_DIRECTORY != 0;
}

read_directory :: proc(f: File, n: int) -> (fi: []File_Info, err: Error) {
	if f == 0 {
		return nil, .Invalid;
	}
	if !is_directory(f) {
		return nil, .Not_Directory;
	}

	return;
}

read_directory_names :: proc(f: File, n: int) -> ([]string, Error) {
	if f == 0 {
		return nil, .Invalid;
	}
	return nil, nil;
}


working_directory :: proc() -> (dir: string, err: Error) {
	return "", nil;
}



make_directory :: proc(path: string, perm: File_Mode = 0) -> Error {
	return nil;
}
make_directory_all :: proc(path: string, perm: File_Mode = 0) -> Error {
	return nil;
}

remove_all :: proc(path: string) -> Error {
	return nil;
}

change_directory :: proc(path: string) -> Error {
	return nil;
}
