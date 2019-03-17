// +build windows amd64

package w32

XSAVE_FORMAT :: struct #align 16 {
	ControlWord:    WORD,
	StatusWord:     WORD,
	TagWord:        BYTE,
	Reserved1:      BYTE,
	ErrorOpcode:    WORD,
	ErrorOffset:    DWORD,
	ErrorSelector:  WORD,
	Reserved2:      WORD,
	DataOffset:     DWORD,
	DataSelector:   WORD,
	Reserved3:      WORD,
	MxCsr:          DWORD,
	MxCsr_Mask:     DWORD,
	FloatRegisters: [8]M128A,
	XmmRegisters:   [16]M128A,
	Reserved4:      [96]BYTE,
}

XSTATE_CONTEXT :: struct {
	Mask:      DWORD64,
	Length:    DWORD,
	Reserved1: DWORD,
	Area:      PXSAVE_AREA,
	Buffer:    PVOID,
}

PXSAVE_FORMAT :: ^XSAVE_FORMAT;
XSAVE_AREA_HEADER :: struct #align 8 {
	Mask:           DWORD64,
	CompactionMask: DWORD64,
	Reserved2:      [6]DWORD64,
}
PXSAVE_AREA_HEADER :: ^XSAVE_AREA_HEADER;
XSAVE_AREA :: struct #align 16 {
	LegacyState: XSAVE_FORMAT,
	Header:      XSAVE_AREA_HEADER,
}
PXSAVE_AREA     :: ^XSAVE_AREA;
PXSTATE_CONTEXT :: ^XSTATE_CONTEXT;

EXCEPTION_READ_FAULT        :: DWORD(0);
EXCEPTION_WRITE_FAULT       :: DWORD(1);
EXCEPTION_EXECUTE_FAULT     :: DWORD(8);
CONTEXT_AMD64               :: DWORD(0x00100000);
CONTEXT_CONTROL             :: DWORD(CONTEXT_AMD64 | 0x00000001);
CONTEXT_INTEGER             :: DWORD(CONTEXT_AMD64 | 0x00000002);
CONTEXT_SEGMENTS            :: DWORD(CONTEXT_AMD64 | 0x00000004);
CONTEXT_FLOATING_POINT      :: DWORD(CONTEXT_AMD64 | 0x00000008);
CONTEXT_DEBUG_REGISTERS     :: DWORD(CONTEXT_AMD64 | 0x00000010);
CONTEXT_FULL                :: DWORD(CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_FLOATING_POINT);
CONTEXT_ALL                 :: DWORD(CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_SEGMENTS | CONTEXT_FLOATING_POINT | CONTEXT_DEBUG_REGISTERS);
CONTEXT_XSTATE              :: DWORD(CONTEXT_AMD64 | 0x00000040);
CONTEXT_EXCEPTION_ACTIVE    :: DWORD(0x08000000);
CONTEXT_SERVICE_ACTIVE      :: DWORD(0x10000000);
CONTEXT_EXCEPTION_REQUEST   :: DWORD(0x40000000);
CONTEXT_EXCEPTION_REPORTING :: DWORD(0x80000000);
INITIAL_MXCSR               :: DWORD(0x1f80);
INITIAL_FPCSR               :: DWORD(0x027f);

XMM_SAVE_AREA32 :: XSAVE_FORMAT;
PXMM_SAVE_AREA32 :: ^XSAVE_FORMAT;
CONTEXT_u_s :: struct {
	Header: [2]M128A,
	Legacy: [8]M128A,
	Xmm0:   M128A,
	Xmm1:   M128A,
	Xmm2:   M128A,
	Xmm3:   M128A,
	Xmm4:   M128A,
	Xmm5:   M128A,
	Xmm6:   M128A,
	Xmm7:   M128A,
	Xmm8:   M128A,
	Xmm9:   M128A,
	Xmm10:  M128A,
	Xmm11:  M128A,
	Xmm12:  M128A,
	Xmm13:  M128A,
	Xmm14:  M128A,
	Xmm15:  M128A,
}
CONTEXT_u :: struct #raw_union {
	u:       [64]u64,
	FltSave: XMM_SAVE_AREA32,
	s:       CONTEXT_u_s,
}
CONTEXT :: struct #align 16 {
	P1Home:               DWORD64,
	P2Home:               DWORD64,
	P3Home:               DWORD64,
	P4Home:               DWORD64,
	P5Home:               DWORD64,
	P6Home:               DWORD64,
	ContextFlags:         DWORD,
	MxCsr:                DWORD,
	SegCs:                WORD,
	SegDs:                WORD,
	SegEs:                WORD,
	SegFs:                WORD,
	SegGs:                WORD,
	SegSs:                WORD,
	EFlags:               DWORD,
	Dr0:                  DWORD64,
	Dr1:                  DWORD64,
	Dr2:                  DWORD64,
	Dr3:                  DWORD64,
	Dr6:                  DWORD64,
	Dr7:                  DWORD64,
	Rax:                  DWORD64,
	Rcx:                  DWORD64,
	Rdx:                  DWORD64,
	Rbx:                  DWORD64,
	Rsp:                  DWORD64,
	Rbp:                  DWORD64,
	Rsi:                  DWORD64,
	Rdi:                  DWORD64,
	R8:                   DWORD64,
	R9:                   DWORD64,
	R10:                  DWORD64,
	R11:                  DWORD64,
	R12:                  DWORD64,
	R13:                  DWORD64,
	R14:                  DWORD64,
	R15:                  DWORD64,
	Rip:                  DWORD64,
	u:                    CONTEXT_u,
	VectorRegister:       [26]M128A,
	VectorControl:        DWORD64,
	DebugControl:         DWORD64,
	LastBranchToRip:      DWORD64,
	LastBranchFromRip:    DWORD64,
	LastExceptionToRip:   DWORD64,
	LastExceptionFromRip: DWORD64,
}

IMAGE_RUNTIME_FUNCTION_ENTRY :: struct { // TODO(bill): REMOVE!
	dummy: rawptr,
}

PCONTEXT          :: ^CONTEXT;
RUNTIME_FUNCTION  :: IMAGE_RUNTIME_FUNCTION_ENTRY;
PRUNTIME_FUNCTION :: ^RUNTIME_FUNCTION;
SCOPE_TABLE       :: SCOPE_TABLE_AMD64;
PSCOPE_TABLE      :: ^SCOPE_TABLE_AMD64;

RUNTIME_FUNCTION_INDIRECT :: DWORD(0x1);
UNW_FLAG_NHANDLER         :: DWORD(0x0);
UNW_FLAG_EHANDLER         :: DWORD(0x1);
UNW_FLAG_UHANDLER         :: DWORD(0x2);
UNW_FLAG_CHAININFO        :: DWORD(0x4);
UNW_FLAG_NO_EPILOGUE      :: DWORD(0x80000000);
UNWIND_HISTORY_TABLE_SIZE :: 12;

UNWIND_HISTORY_TABLE_ENTRY :: struct {
	ImageBase:     DWORD64,
	FunctionEntry: PRUNTIME_FUNCTION,
}
PUNWIND_HISTORY_TABLE_ENTRY :: ^UNWIND_HISTORY_TABLE_ENTRY;
UNWIND_HISTORY_TABLE :: struct {
	Count:       DWORD,
	LocalHint:   BYTE,
	GlobalHint:  BYTE,
	Search:      BYTE,
	Once:        BYTE,
	LowAddress:  DWORD64,
	HighAddress: DWORD64,
	Entry:       [UNWIND_HISTORY_TABLE_SIZE]UNWIND_HISTORY_TABLE_ENTRY,
}
PUNWIND_HISTORY_TABLE :: ^UNWIND_HISTORY_TABLE;

PGET_RUNTIME_FUNCTION_CALLBACK :: #type proc "c" (
	ControlPc: DWORD64,
	Context: PVOID,
) -> PRUNTIME_FUNCTION;
POUT_OF_PROCESS_FUNCTION_TABLE_CALLBACK :: #type proc "c" (
	Process: HANDLE,
	TableAddress: PVOID,
	Entries: PDWORD,
	Functions: ^PRUNTIME_FUNCTION,
) -> DWORD;

OUT_OF_PROCESS_FUNCTION_TABLE_CALLBACK_EXPORT_NAME :: "OutOfProcessFunctionTableCallback";

DISPATCHER_CONTEXT :: struct {
	ControlPc:        DWORD64,
	ImageBase:        DWORD64,
	FunctionEntry:    PRUNTIME_FUNCTION,
	EstablisherFrame: DWORD64,
	TargetIp:         DWORD64,
	ContextRecord:    PCONTEXT,
	LanguageHandler:  PEXCEPTION_ROUTINE,
	HandlerData:      PVOID,
	HistoryTable:     PUNWIND_HISTORY_TABLE,
	ScopeIndex:       DWORD,
	Fill0:            DWORD,
}
PDISPATCHER_CONTEXT :: ^DISPATCHER_CONTEXT;

PEXCEPTION_FILTER :: #type proc "c" (
	ExceptionPointers: ^EXCEPTION_POINTERS,
	EstablisherFrame: PVOID,
) -> LONG;
PTERMINATION_HANDLER :: #type proc "c" (
	AbnormalTermination: BOOLEAN,
	EstablisherFrame: PVOID,
);

KNONVOLATILE_CONTEXT_POINTERS_u1_s :: struct {
	Xmm0:  PM128A,
	Xmm1:  PM128A,
	Xmm2:  PM128A,
	Xmm3:  PM128A,
	Xmm4:  PM128A,
	Xmm5:  PM128A,
	Xmm6:  PM128A,
	Xmm7:  PM128A,
	Xmm8:  PM128A,
	Xmm9:  PM128A,
	Xmm10: PM128A,
	Xmm11: PM128A,
	Xmm12: PM128A,
	Xmm13: PM128A,
	Xmm14: PM128A,
	Xmm15: PM128A,
}
KNONVOLATILE_CONTEXT_POINTERS_u1 :: struct #raw_union {
	u: [16]u64,
	FloatingContext: [16]PM128A,
	s: KNONVOLATILE_CONTEXT_POINTERS_u1_s,
}
KNONVOLATILE_CONTEXT_POINTERS_u2_s :: struct {
	Rax: PDWORD64,
	Rcx: PDWORD64,
	Rdx: PDWORD64,
	Rbx: PDWORD64,
	Rsp: PDWORD64,
	Rbp: PDWORD64,
	Rsi: PDWORD64,
	Rdi: PDWORD64,
	R8:  PDWORD64,
	R9:  PDWORD64,
	R10: PDWORD64,
	R11: PDWORD64,
	R12: PDWORD64,
	R13: PDWORD64,
	R14: PDWORD64,
	R15: PDWORD64,
}
KNONVOLATILE_CONTEXT_POINTERS_u2 :: struct #raw_union {
	u: [16]u64,
	IntegerContext: [16]PDWORD64,
	s: KNONVOLATILE_CONTEXT_POINTERS_u2_s,
}
KNONVOLATILE_CONTEXT_POINTERS :: struct {
	u1: KNONVOLATILE_CONTEXT_POINTERS_u1,
	u2: KNONVOLATILE_CONTEXT_POINTERS_u2,
}
PKNONVOLATILE_CONTEXT_POINTERS :: ^KNONVOLATILE_CONTEXT_POINTERS;
