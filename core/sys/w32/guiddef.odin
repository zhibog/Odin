// +build windows

package w32

import "core:c"

GUID :: struct {
    Data1: c.ulong,
    Data2: c.ushort,
    Data3: c.ushort,
    Data4: [8]c.uchar,
}
LPGUID   :: ^GUID;
LPCGUID  :: ^GUID;
IID      :: GUID;
LPIID    :: ^IID;
CLSID    :: GUID;
LPCLSID  :: ^CLSID;
FMTID    :: GUID;
LPFMTID  :: ^FMTID;
REFGUID  :: ^GUID;
REFIID   :: ^IID;
REFCLSID :: ^IID;
REFFMTID :: ^IID;

@static IID_NULL := GUID{0x00000000, 0x0000, 0x0000, {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}};

IsEqualFMTID :: IsEqualGUID;
IsEqualIID :: IsEqualGUID;
IsEqualGUID :: inline proc(g1: ^GUID, g2: ^GUID) -> bool {
    a := (cast(^[4]u32)g1)^;
    b := (cast(^[4]u32)g2)^;
    return a[0] == b[0] && a[1] == b[1] && a[2] == b[2] && a[3] == b[3];
}
