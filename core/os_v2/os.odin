package os_v2

import "core:time"

Handle :: distinct uintptr;

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
}

File_Mode :: distinct u32;


File_Info :: struct {
	name:              string,
	size:              i64,
	mode:              File_Mode,
	modification_time: time.Time,
	is_directory:      bool,
}


Open_Option :: enum {
	Read,
	Write,
	Append,
	Truncate,
	Sync,
	Create,
	Create_New, // if set, .Create and .Truncate are ignored
}
Open_Options :: bit_set[Open_Option];


Permission :: enum {
	Read_Only,
}
Permissions :: bit_set[Permission];




SEEK_BEGIN   :: int(0); // seek relative to the origin of the file
SEEK_CURRENT :: int(1); // seek relative to the current offset
SEEK_END     :: int(2); // seek relative to the end



args: []string;
