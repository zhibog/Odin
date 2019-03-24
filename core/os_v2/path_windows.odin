package os_v2

PATH_SEPARATOR      :: '\\';
PATH_LIST_SEPARATOR :: ';';

is_path_separator :: proc(c: byte) -> bool {
	return c == '\\' || c == '/';
}


