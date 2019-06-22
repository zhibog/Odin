package os_v2

set_env :: proc(key, value: string) -> Error {
	return nil;
}
unset_env :: proc(key: string) -> Error {
	return nil;
}

clear_env :: proc() -> Error {
	return nil;
}

lookup_env :: proc(key: string, allocator := context.allocator) -> (string, bool) {
	return "", false;
}
get_env :: proc(key: string, allocator := context.allocator) -> string {
	value, _ := lookup_env(key, allocator);
	return value;
}


environ :: proc(allocator := context.allocator) -> []string {
	return nil;
}
