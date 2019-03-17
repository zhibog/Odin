// +build windows
package w32

import "core:c"

MAX_PATH :: uint(260);
FALSE    :: BOOL(0!=0);
TRUE     :: BOOL(0==0);

ULONG   :: c.ulong;
PULONG  :: ^ULONG;
SHORT   :: c.short;
USHORT  :: c.ushort;
PUSHORT :: ^USHORT;
UCHAR   :: c.uchar;
PUCHAR  :: ^UCHAR;
PSZ     :: cstring;
DWORD   :: c.ulong;
BOOL    :: distinct b32;
BYTE    :: byte;
WORD    :: c.ushort;
FLOAT   :: c.float;
PFLOAT  :: ^FLOAT;
PBOOL   :: ^BOOL;
LPBOOL  :: ^BOOL;
PBYTE   :: ^BYTE;
LPBYTE  :: ^BYTE;
PINT    :: ^c.int;
LPINT   :: ^c.int;
PWORD   :: ^WORD;
LPWORD  :: ^WORD;
LPLONG  :: ^c.long;
PDWORD  :: ^DWORD;
LPDWORD :: ^DWORD;
LPVOID  :: rawptr;
LPCVOID :: rawptr;
INT     :: c.int;
UINT    :: c.uint;
PUINT   :: ^c.uint;
WPARAM  :: UINT_PTR;
LPARAM  :: LONG_PTR;
LRESULT :: LONG_PTR;

MAKEWORD :: inline proc(a: BYTE, b: BYTE) -> WORD {
    return WORD(a) | (WORD(b) << 8);
}
MAKELONG :: inline proc(a: WORD, b: WORD) -> LONG {
    return LONG(DWORD(a) | (DWORD(b) << 16));
}
LOWORD:: inline proc(l: DWORD) -> WORD {
    return WORD(l & 0xffff);
}
HIWORD:: inline proc(l: DWORD) -> WORD {
    return WORD((l >> 16) & 0xffff);
}
LOBYTE:: inline proc(l: WORD) -> BYTE {
    return BYTE(l & 0xff);
}
HIBYTE:: inline proc(l: WORD) -> BYTE {
    return BYTE((l >> 8) & 0xff);
}
SPHANDLE     :: ^HANDLE;
LPHANDLE     :: ^HANDLE;
HGLOBAL      :: distinct HANDLE;
HLOCAL       :: distinct HANDLE;
GLOBALHANDLE :: distinct HANDLE;
LOCALHANDLE  :: distinct HANDLE;
__some_function :: opaque proc "c" ();

/// Pointer to a function with unknown type signature.
FARPROC :: ^__some_function;
/// Pointer to a function with unknown type signature.
NEARPROC :: ^__some_function;
/// Pointer to a function with unknown type signature.
PROC :: ^__some_function;

ATOM :: distinct WORD;

HKEY      :: distinct HANDLE;
PHKEY     :: ^HKEY;
HMETAFILE :: distinct HANDLE;
HINSTANCE :: distinct HANDLE;
HMODULE   :: distinct HINSTANCE;
HRGN      :: distinct HANDLE;
HRSRC     :: distinct HANDLE;
HSPRITE   :: distinct HANDLE;
HLSURF    :: distinct HANDLE;
HSTR      :: distinct HANDLE;
HTASK     :: distinct HANDLE;
HWINSTA   :: distinct HANDLE;
HKL       :: distinct HANDLE;
HFILE     :: distinct opaque c.int;

FILETIME :: struct {
    dwLowDateTime:  DWORD,
    dwHighDateTime: DWORD,
}
PFILETIME  :: ^FILETIME;
LPFILETIME :: ^FILETIME;
