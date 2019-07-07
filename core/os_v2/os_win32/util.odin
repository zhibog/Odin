package os_win32

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

utf8_to_utf16_ptr :: proc(str: string, allocator := context.temp_allocator) -> (ptr: ^u16, length: int) {
	#no_bounds_check cstr := cstring(&str[0]);
	n := i32(len(str));

	size_needed := MultiByteToWideChar(CP_UTF8, 0, cstr, n, nil, 0);
	buf := make([]u16, size_needed+1, allocator);
	MultiByteToWideChar(CP_UTF8, 0, cstr, n, &buf[0], i32(len(buf)));
	buf[size_needed] = 0;
	return &buf[0], int(size_needed);
}
utf16_to_utf8_cstring :: proc(wstr: []u16, allocator := context.temp_allocator) -> cstring {
	#no_bounds_check pwstr := &wstr[0];
	n := i32(len(wstr));

	size_needed := WideCharToMultiByte(CP_UTF8, 0, pwstr, n, nil, 0, nil, nil);
	buf := make([]u8, size_needed+1, allocator);
	WideCharToMultiByte(CP_UTF8, 0, pwstr, n, cstring(&buf[0]), i32(len(buf)), nil, nil);
	buf[size_needed] = 0;
	return cstring(&buf[0]);
}
