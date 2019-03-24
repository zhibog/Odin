package os_v2

import "core:time"

OS :: "windows";


/*
stdin  := get_std_handle(int(w32.STD_INPUT_HANDLE));
stdout := get_std_handle(int(w32.STD_OUTPUT_HANDLE));
stderr := get_std_handle(int(w32.STD_ERROR_HANDLE));


get_std_handle :: proc(h: int) -> Handle {
	fd := w32.GetStdHandle(i32(h));
	win32.SetHandleInformation(fd, w32.HANDLE_FLAG_INHERIT, 0);
	return Handle(fd);
}
*/
