package os_win32

foreign import kernel32 "system:kernel32.lib"

HANDLE :: rawptr;
BOOL :: b32;
WORD :: u16;
DWORD :: u32;
QWORD :: u64;

WCHAR :: u16;

CP_UTF8 :: 65001;

foreign kernel32 {
	GetLastError   :: proc() -> DWORD ---

	ReadFile       :: proc(hFile: HANDLE, lpBuffer: rawptr, nNumberOfBytesToRead:  DWORD, lpNumberOfBytesRead:    ^i32, lpOverlapped: rawptr) -> BOOL ---
	WriteFile      :: proc(hFile: HANDLE, lpBuffer: rawptr, nNumberOfBytesToWrite: DWORD, lpNumberOfBytesWritten: ^i32, lpOverlapped: rawptr) -> BOOL ---
	CloseHandle    :: proc(hObject: HANDLE) -> BOOL ---
	GetFileType    :: proc(hFile: HANDLE) -> DWORD ---
	SetFilePointer :: proc(hFile: HANDLE, lo: i32, hi: ^i32, whence: DWORD) -> DWORD ---

	MoveFileExW :: proc(lpExistingFileName, lpNewFileName: ^WCHAR, dwFlags: DWORD) -> BOOL ---

	WideCharToMultiByte :: proc(CodePage: DWORD, dwFlags: DWORD,
	                            lpWideCharStr: ^WCHAR, cchWideChar: i32,
	                            lpMultiByteStr: cstring, cbMultiByte: i32,
	                            lpDefaultChar: cstring, lpUsedDefaultChar: ^b32,
	) -> i32 ---
	MultiByteToWideChar :: proc(CodePage: DWORD, dwFlags: DWORD,
	                            lpMultiByteStr: cstring, cbMultiByte: i32,
	                            lpWideCharStr: ^WCHAR, cchWideChar: i32,
	) -> i32 ---
}

@(default_calling_convention="stdcall")
foreign kernel32 {
	GetStdHandle :: proc(nStdHandle: DWORD) -> rawptr ---
}


@(default_calling_convention="c")
foreign kernel32 {
	FindFirstFileW :: proc(lpFileName: ^WCHAR, lpFindFileData: ^WIN32_FIND_DATAW) -> HANDLE ---
	FindNextFileW :: proc(hFindFile: HANDLE, lpFindFileData: ^WIN32_FIND_DATAW) -> BOOL ---
	GetFileAttributesW :: proc(lpFileName: ^WCHAR) -> DWORD ---
	GetFileInformationByHandle :: proc(hFile: HANDLE, lpFileInformation: ^BY_HANDLE_FILE_INFORMATION) -> BOOL ---

	GetEnvironmentVariableW :: proc(lpName: ^u16, lpBuffer: ^u16, nSize: DWORD) -> DWORD ---
	SetEnvironmentVariableW :: proc(lpName: ^u16, value: ^u16, nSize: DWORD) -> BOOL ---

}

FILETIME :: struct {
	dwLowDateTime:  DWORD,
	dwHighDateTime: DWORD,
}

WIN32_FIND_DATAW :: struct {
	dwFileAttributes:   DWORD,
	ftCreationTime:     FILETIME,
	ftLastAccessTime:   FILETIME,
	ftLastWriteTime:    FILETIME,
	nFileSizeHigh:      DWORD,
	nFileSizeLow:       DWORD,
	dwReserved0:        DWORD,
	dwReserved1:        DWORD,
	cFileName:          [MAX_PATH]WCHAR,
	cAlternateFileName: [14]WCHAR,
	dwFileType:         DWORD,
	dwCreatorType:      DWORD,
	wFinderFlags:       WORD,
}

WIN32_FILE_ATTRIBUTE_DATA :: struct {
	dwFileAttributes: DWORD,
	ftCreationTime:   FILETIME,
	ftLastAccessTime: FILETIME,
	ftLastWriteTime:  FILETIME,
	nFileSizeHigh:    DWORD,
	nFileSizeLow:     DWORD,
}

BY_HANDLE_FILE_INFORMATION :: struct {
	dwFileAttributes:     DWORD,
	ftCreationTime:       FILETIME,
	ftLastAccessTime:     FILETIME,
	ftLastWriteTime:      FILETIME,
	dwVolumeSerialNumber: DWORD,
	nFileSizeHigh:        DWORD,
	nFileSizeLow:         DWORD,
	nNumberOfLinks:       DWORD,
	nFileIndexHigh:       DWORD,
	nFileIndexLow:        DWORD,
}


MOVEFILE_REPLACE_EXISTING :: 0x1;
MOVEFILE_WRITE_THROUGH    :: 0x8;
FILE_TYPE_PIPE :: 0x0003;
INVALID_SET_FILE_POINTER :: ~u32(0);
MAX_PATH :: 260;


FILE_ATTRIBUTE_ARCHIVE               :: 0x20;
FILE_ATTRIBUTE_COMPRESSED            :: 0x800;
FILE_ATTRIBUTE_DEVICE                :: 0x40;
FILE_ATTRIBUTE_DIRECTORY             :: 0x10;
FILE_ATTRIBUTE_ENCRYPTED             :: 0x4000;
FILE_ATTRIBUTE_HIDDEN                :: 0x2;
FILE_ATTRIBUTE_INTEGRITY_STREAM      :: 0x8000;
FILE_ATTRIBUTE_NORMAL                :: 0x80;
FILE_ATTRIBUTE_NOT_CONTENT_INDEXED   :: 0x2000;
FILE_ATTRIBUTE_NO_SCRUB_DATA         :: 0x20000;
FILE_ATTRIBUTE_OFFLINE               :: 0x1000;
FILE_ATTRIBUTE_READONLY              :: 0x1;
FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS :: 0x400000;
FILE_ATTRIBUTE_RECALL_ON_OPEN        :: 0x40000;
FILE_ATTRIBUTE_REPARSE_POINT         :: 0x400;
FILE_ATTRIBUTE_SPARSE_FILE           :: 0x200;
FILE_ATTRIBUTE_SYSTEM                :: 0x4;
FILE_ATTRIBUTE_TEMPORARY             :: 0x100;
FILE_ATTRIBUTE_VIRTUAL               :: 0x10000;

ERROR_ENVVAR_NOT_FOUND               :: 203;
