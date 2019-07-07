package os_v2

import "core:time"

Handle :: distinct uintptr;

File :: distinct Handle;

Error :: enum {
	None,
	Invalid,
	Invalid_Argument,
	Permission_Denied,
	Not_Found,
	Already_Exists,
	Already_Closed,
	File_Is_Pipe,
	EOF,
	Not_Directory,

	Platform_Specific,
}

File_Mode :: distinct u32;


File_Info :: struct {
	name:              string,
	size:              i64,
	mode:              File_Mode,
	creation_time:     time.Time,
	modification_time: time.Time,
	is_directory:      bool,
	handle:            Handle,
	underlying_data:   rawptr,
}


File_Flag :: enum {
	Read,
	Write,
	Append,
	Truncate,
	Sync,
	Create,
	Create_New, // if set, .Create and .Truncate are ignored
}
File_Flags :: bit_set[File_Flag];



SEEK_BEGIN   :: int(0); // seek relative to the origin of the file
SEEK_CURRENT :: int(1); // seek relative to the current offset
SEEK_END     :: int(2); // seek relative to the end



args: []string;


file_info_destroy :: proc(fi: ^File_Info) {
	delete(fi.name);
	fi.name = "";
}
