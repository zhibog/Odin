package os_v2

read_directory :: proc(f: File, n: int) -> ([]File_Info, Error) {
	if f == 0 {
		return nil, .Invalid;
	}
	return nil, nil;
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
