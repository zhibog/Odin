package os_v2

import win32 "os_win32"

set_env :: proc(key, value: string) -> Error {
	k, _ := win32.utf8_to_utf16_ptr(key, context.temp_allocator);
	v, n := win32.utf8_to_utf16_ptr(value, context.temp_allocator);
	defer free(k, context.temp_allocator);
	defer free(v, context.temp_allocator);

	ok := win32.SetEnvironmentVariableW(k, v, win32.DWORD(n));
	// TODO(bill): handle error
	return nil;
}
unset_env :: proc(key: string) -> Error {
	k, _ := win32.utf8_to_utf16_ptr(key, context.temp_allocator);
	defer free(k, context.temp_allocator);

	ok := win32.SetEnvironmentVariableW(k, nil, 0);
	// TODO(bill): handle error
	return nil;
}

clear_env :: proc() -> Error {
	keys := environ(context.temp_allocator);
	defer delete(keys);
	for k in keys {
		// NOTE(bill): Environment variables may start with =
		// See: https://blogs.msdn.com/b/oldnewthing/archive/2010/05/06/10008132.aspx
		for i in 1..<len(k) {
			if k[i] == '=' {
				unset_env(k[0:i]);
				break;
			}
		}
	}

	return nil;
}

lookup_env :: proc(key: string, allocator := context.allocator) -> (string, bool) {
	str, _ := win32.utf8_to_utf16_ptr(key, context.temp_allocator);
	defer free(str, context.temp_allocator);

	n := win32.GetEnvironmentVariableW(str, nil, 0);
	if n <= 0 {
		err := win32.GetLastError();
		if err == win32.ERROR_ENVVAR_NOT_FOUND {
			return "", false;
		}
		return "", true;
	}

	res := make([]u16, n, context.temp_allocator);
	defer delete(res, context.temp_allocator);
	m := win32.GetEnvironmentVariableW(str, &res[0], win32.DWORD(n));
	str16 := res[:min(m, n)];
	return win32.utf16_to_utf8(str16, allocator), true;
}
get_env :: proc(key: string, allocator := context.allocator) -> string {
	value, _ := lookup_env(key, allocator);
	return value;
}


environ :: proc(allocator := context.allocator) -> []string {
	return nil;
}
