/*
 * Copyright 2003
 *     Bang Jun-Young.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by Bang Jun-Young.
 * 4. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _NTDLL_H
#define _NTDLL_H

#include <ntdef.h>
#include <winioctl.h>		/* For DEVICE_TYPE */
#include <heap.h>

/*
 * Constant definitions.
 */

#define CURRENT_THREAD_PSEUDO_HANDLE	((HANDLE)-2)
#define CURRENT_PROCESS_PSEUDO_HANDLE	((HANDLE)-1)

#define FILE_ATTRIBUTE_VALID_SET_FLAGS	0x000031A7

/* Used for NtLockVirtualMemory(). */
#define LOCK_VM_IN_WSL	1
#define LOCK_VM_IN_RAM	2

/*
 * NtGlobalFlags.
 */
#define FLG_STOP_ON_EXCEPTION		0x00000001
#define FLG_SHOW_LDR_SNAPS		0x00000002
#define FLG_DEBUG_INITIAL_COMMAND	0x00000004
#define FLG_STOP_ON_HANG_GUI		0x00000008
#define FLG_HEAP_ENABLE_TAIL_CHECK	0x00000010
#define FLG_HEAP_ENABLE_FREE_CHECK	0x00000020
#define FLG_HEAP_VALIDATE_PARAMETERS	0x00000040
#define FLG_HEAP_VALIDATE_ALL		0x00000080
#define FLG_POOL_ENABLE_TAIL_CHECK	0x00000100
#define FLG_POOL_ENABLE_FREE_CHECK	0x00000200
#define FLG_POOL_ENABLE_TAGGING		0x00000400
#define FLG_HEAP_ENABLE_TAGGING		0x00000800
#define FLG_USER_STACK_TRACE_DB		0x00001000
#define FLG_KERNEL_STACK_TRACE_DB	0x00002000
#define FLG_MAINTAIN_OBJECT_TYPELIST	0x00004000
#define FLG_HEAP_ENABLE_TAG_BY_DLL	0x00008000
#define FLG_IGNORE_DEBUG_PRIV		0x00010000
#define FLG_ENABLE_CSRDEBUG		0x00020000
#define FLG_ENABLE_KDEBUG_SYMBOL_LOAD	0x00040000
#define FLG_DISABLE_PAGE_KERNEL_STACKS	0x00080000
#define FLG_HEAP_ENABLE_CALL_TRACING	0x00100000
#define FLG_HEAP_DISABLE_COALESCING	0x00200000
#define FLG_ENABLE_CLOSE_EXCEPTION	0x00400000
#define FLG_ENABLE_EXCEPTION_LOGGING	0x00800000
#define FLG_ENABLE_HANDLE_TYPE_TAGGING	0x01000000
#define FLG_HEAP_PAGE_ALLOCS		0x02000000
#define FLG_DEBUG_WINLOGON		0x04000000
#define FLG_ENABLE_DBGPRINT_BUFFERING	0x08000000
#define FLG_EARLY_CRITICAL_SECTION_EVT	0x10000000
#define FLG_DISABLE_DLL_VERIFICATION	0x80000000

/*
 * XXX should be in ntddk.h.
 */
#define FILE_DIRECTORY_FILE		0x00000001
#define FILE_WRITE_THROUGH		0x00000002
#define FILE_SEQUENTIAL_ONLY		0x00000004
#define FILE_NO_INTERMEDIATE_BUFFERING	0x00000008
#define FILE_SYNCHRONOUS_IO_ALERT	0x00000010
#define FILE_SYNCHRONOUS_IO_NONALERT	0x00000020
#define FILE_NON_DIRECTORY_FILE		0x00000040
#define FILE_CREATE_TREE_CONNECTION	0x00000080
#define FILE_COMPLETE_IF_OPLOCKED	0x00000100
#define FILE_NO_EA_KNOWLEDGE		0x00000200
#define FILE_OPEN_FOR_RECOVERY		0x00000400
#define FILE_RANDOM_ACCESS		0x00000800
#define FILE_DELETE_ON_CLOSE		0x00001000
#define FILE_OPEN_BY_FILE_ID		0x00002000
#define FILE_OPEN_FOR_BACKUP_INTENT	0x00004000
#define FILE_NO_COMPRESSION		0x00008000
#define FILE_RESERVE_OPFILTER		0x00100000
#define FILE_OPEN_REPARSE_POINT		0x00200000
#define FILE_OPEN_NO_RECALL		0x00400000
#define FILE_OPEN_FOR_FREE_SPACE_QUERY	0x00800000

#define FILE_VALID_OPTION_FLAGS		0x00FFFFFF

/*
 * Priority Classes.
 */
#define PC_IDLE		1
#define PC_NORMAL	2
#define PC_HIGH		3
#define PC_REALTIME	4
#define PC_BELOW_NORMAL	5
#define PC_ABOVE_NORMAL	6

/*
 * XXX
 */
#define FILE_SUPERSEDE			0
#define FILE_OPEN			1
#define FILE_CREATE			2
#define FILE_OPEN_IF			3
#define FILE_OVERWRITE			4
#define FILE_OVERWRITE_IF		5
#define FILE_MAXIMUM_DISPOSITION	5

#define DIRECTORY_QUERY			1
#define DIRECTORY_TRAVERSE		2
#define DIRECTORY_CREATE_OBJECT		4
#define DIRECTORY_CREATE_SUBDIRECTORY	8

/*
 * Simple types.
 */

typedef VOID **PPVOID;
typedef ULONG KAFFINITY;
typedef KAFFINITY *PKAFFINITY;
typedef LONG KPRIORITY;
typedef LANGID *PLANGID;
typedef CHAR KPROCESSOR_MODE;
typedef ULONG EXECUTION_STATE, *PEXECUTION_STATE;
typedef short CSHORT;
typedef CONST char *PCSZ;

/*
 * Enumerated types.
 */

typedef enum _PROCESSINFOCLASS {
	ProcessBasicInformation,
	ProcessQuotaLimits,
	ProcessIoCounters,
	ProcessVmCounters,
	ProcessTimes,
	ProcessBasePriority,
	ProcessRaisePriority,
	ProcessDebugPort,
	ProcessExceptionPort,
	ProcessAccessToken,
	ProcessLdtInformation,
	ProcessLdtSize,
	ProcessDefaultHardErrorMode,
	ProcessIoPortHandlers,
	ProcessPooledUsageAndLimits,
	ProcessWorkingSetWatch,
	ProcessUserModeIOPL,
	ProcessEnableAlignmentFaultFixup,
	ProcessPriorityClass,
	ProcessWx86Information,
	ProcessHandleCount,
	ProcessAffinityMask,
	ProcessPriorityBoost,
	ProcessDeviceMap,
	ProcessSessionInformation,
	ProcessForegroundInformation,
	ProcessWow64Information,
	MaxProcessInfoClass
} PROCESSINFOCLASS;

typedef enum _THREADINFOCLASS {
	ThreadBasicInformation,
	ThreadTimes,
	ThreadPriority,
	ThreadBasePriority,
	ThreadAffinityMask,
	ThreadImpersonationToken,
	ThreadDescriptorTableEntry,
	ThreadEnableAlignmentFaultFixup,
	ThreadEventPair,
	ThreadQuerySetWin32StartAddress,
	ThreadZeroTlsCell,
	ThreadPerformanceCount,
	ThreadAmILastThread,
	ThreadIdealProcessor,
	ThreadPriorityBoost,
	ThreadSetTlsArrayAddress,
	ThreadIsIoPending,
	ThreadHideFromDebugger
} THREADINFOCLASS;

typedef enum _SYSTEM_INFORMATION_CLASS {
	SystemBasicInformation,
	SystemProcessorInformation,
	SystemPerformanceInformation,
	SystemTimeOfDayInformation,
	SystemNotImplemented1,
	SystemProcessesAndThreadsInformation,
	SystemCallCounts,
	SystemConfigurationInformation,
	SystemProcessorTimes,
	SystemGlobalFlag,
	SystemNotImplemented2,
	SystemModuleInformation,
	SystemLockInformation,
	SystemNotImplemented3,
	SystemNotImplemented4,
	SystemNotImplemented5,
	SystemHandleInformation,
	SystemObjectInformation,
	SystemPagefileInformation,
	SystemInstructionEmulationCounts,
	SystemInvalidInfoClass1,
	SystemCacheInformation,
	SystemPoolTagInformation,
	SystemProcessorStatistics,
	SystemDpcInformation,
	SystemNotImplemented6,
	SystemLoadImage,
	SystemUnloadImage,
	SystemTimeAdjustment,
	SystemNotImplemented7,
	SystemNotImplemented8,
	SystemNotImplemented9,
	SystemCrashDumpInformation,
	SystemExceptionInformation,
	SystemCrashDumpStateInformation,
	SystemKernelDebuggerInformation,
	SystemContextSwitchInformation,
	SystemRegistryQuotaInformation,
	SystemLoadAndCallImage,
	SystemPrioritySeparation,
	SystemNotImplemented10,
	SystemNotImplemented11,
	SystemInvalidInfoClass2,
	SystemInvalidInfoClass3,
	SystemTimeZoneInformation,
	SystemLookasideInformation,
	SystemSetTimeSlipEvent,
	SystemCreateSession,
	SystemDeleteSession,
	SystemInvalidInfoClass4,
	SystemRangeStartInformation,
	SystemVerifierInformation,
	SystemAddVerifier,
	SystemSessionProcessesInformation
} SYSTEM_INFORMATION_CLASS;

typedef enum _OBJECT_INFORMATION_CLASS {
	ObjectBasicInformation,
	ObjectNameInformation,
	ObjectTypeInformation,
	ObjectAllTypesInformation,
	ObjectHandleInformation
} OBJECT_INFORMATION_CLASS;

typedef enum _MEMORY_INFORMATION_CLASS {
	MemoryBasicInformation,
	MemoryWorkingSetList,
	MemorySectionName,
	MemoryBasicVlmInformation
} MEMORY_INFORMATION_CLASS;

typedef enum _SECTION_INFORMATION_CLASS {
	SectionBasicInformation,
	SectionImageInformation
} SECTION_INFORMATION_CLASS;

typedef enum _FILE_INFORMATION_CLASS {
	FileDirectoryInformation = 1,
	FileFullDirectoryInformation,
	FileBothDirectoryInformation,
	FileBasicInformation,
	FileStandardInformation,
	FileInternalInformation,
	FileEaInformation,
	FileAccessInformation,
	FileNameInformation,
	FileRenameInformation,
	FileLinkInformation,
	FileNamesInformation,
	FileDispositionInformation,
	FilePositionInformation,
	FileFullEaInformation,
	FileModeInformation,
	FileAlignmentInformation,
	FileAllInformation,
	FileAllocationInformation,
	FileEndOfFileInformation,
	FileAlternateNameInformation,
	FileStreamInformation,
	FilePipeInformation,
	FilePipeLocalInformation,
	FilePipeRemoteInformation,
	FileMailslotQueryInformation,
	FileMailslotSetInformation,
	FileCompressionInformation,
	FileObjectIdInformation,
	FileCompletionInformation,
	FileMoveClusterInformation,
	FileQuotaInformation,
	FileReparsePointInformation,
	FileNetworkOpenInformation,
	FileAttributeTagInformation,
	FileTrackingInformation,
	FileMaximumInformation
} FILE_INFORMATION_CLASS, *PFILE_INFORMATION_CLASS;

typedef enum _FSINFOCLASS {
	FileFsVolumeInformation = 1,
	FileFsLabelInformation,
	FileFsSizeInformation,
	FileFsDeviceInformation,
	FileFsAttributeInformation,
	FileFsControlInformation,
	FileFsFullSizeInformation,
	FileFsObjectIdInformation,
	FileFsMaximumInformation
} FS_INFORMATION_CLASS, *PFS_INFORMATION_CLASS;

typedef enum _KEY_INFORMATION_CLASS {
	KeyBasicInformation,
	KeyNodeInformation,
	KeyFullInformation,
	KeyNameInformation
} KEY_INFORMATION_CLASS;

typedef enum _KEY_SET_INFORMATION_CLASS {
	KeyWriteTimeInformation
} KEY_SET_INFORMATION_CLASS;

typedef enum _KEY_VALUE_INFORMATION_CLASS {
	KeyValueBasicInformation,
	KeyValueFullInformation,
	KeyValuePartialInformation,
	KeyValueFullInformationAlign64,
	KeyValuePartialInformationAlign64
} KEY_VALUE_INFORMATION_CLASS;

typedef enum _ATOM_INFORMATION_CLASS {
	AtomBasicInformation,
	AtomListInformation
} ATOM_INFORMATION_CLASS;

typedef enum _EVENT_INFORMATION_CLASS {
	EventBasicInformation
} EVENT_INFORMATION_CLASS;

typedef enum _IO_COMPLETION_INFORMATION_CLASS {
	IoCompletionBasicInformation
} IO_COMPLETION_INFORMATION_CLASS;

typedef enum _MUTANT_INFORMATION_CLASS {
	MutantBasicInformation
} MUTANT_INFORMATION_CLASS;

typedef enum _SEMAPHORE_INFORMATION_CLASS {
	SemaphoreBasicInformation
} SEMAPHORE_INFORMATION_CLASS;

typedef enum _TIMER_INFORMATION_CLASS {
	TimerBasicInformation
} TIMER_INFORMATION_CLASS;

typedef enum _PORT_INFORMATION_CLASS {
	PortBasicInformation
} PORT_INFORMATION_CLASS;

typedef enum _AUDIT_EVENT_TYPE {
	AuditEventObjectAccess,
	AuditEventDirectoryServiceAccess
} AUDIT_EVENT_TYPE, *PAUDIT_EVENT_TYPE;

typedef enum _SHUTDOWN_ACTION {
	ShutdownNoReboot,
	ShutdownReboot,
	ShutdownPoweroff
} SHUTDOWN_ACTION;

typedef enum _EVENT_TYPE {
	NotificationEvent,
	SynchronizationEvent
} EVENT_TYPE;

typedef enum _TIMER_TYPE {
	NotificationTimer,
	SynchronizationTimer
} TIMER_TYPE;

typedef enum _WAIT_TYPE {
	WaitAll,
	WaitAny
} WAIT_TYPE, *PWAIT_TYPE;

typedef enum _KPROFILE_SOURCE {
	ProfileTime
} KPROFILE_SOURCE;

typedef enum _DEBUG_CONTROL_CODE {
	DebugGetTraceInformation = 1,
	DebugSetInternalBreakpoint,
	DebugSetSpecialCall,
	DebugClearSpecialCalls,
	DebugQuerySpecialCalls,
	DebugDbgBreakPoint
} DEBUG_CONTROL_CODE;

typedef enum _LPC_TYPE {
	LPC_NEW_MESSAGE,
	LPC_REQUEST,
	LPC_REPLY,
	LPC_DATAGRAM,
	LPC_LOST_REPLY,
	LPC_PORT_CLOSED,
	LPC_CLIENT_DIED,
	LPC_EXCEPTION,
	LPC_DEBUG_EVENT,
	LPC_ERROR_EVENT,
	LPC_CONNECTION_REQUEST
} LPC_TYPE;

/*
 * Type definitions.
 */

typedef struct _RTL_BITMAP {
	DWORD  SizeOfBitMap;
	PDWORD Buffer;
} RTL_BITMAP, *PRTL_BITMAP, **PPRTL_BITMAP;

typedef struct _IO_STATUS_BLOCK {
	union {
		NTSTATUS Status;
		PVOID Pointer;
	};
	ULONG_PTR Information;
} IO_STATUS_BLOCK, *PIO_STATUS_BLOCK;

typedef struct _CLIENT_ID {
	HANDLE UniqueProcess;
	HANDLE UniqueThread;
} CLIENT_ID, *PCLIENT_ID;

typedef struct _PORT_BASIC_INFORMATION {
	/* Does not have any members. */
} PORT_BASIC_INFORMATION, *PPORT_BASIC_INFORMATION;

typedef struct _SYSTEM_STRINGS {
	UNICODE_STRING SystemRoot;
	UNICODE_STRING System32Root;
	UNICODE_STRING BaseNamedObjects;
} SYSTEM_STRINGS, *PSYSTEM_STRINGS, **PPSYSTEM_STRINGS;

typedef struct _TEXT_INFO {
	PVOID Reserved;
	PSYSTEM_STRINGS SystemStrings;
} TEXT_INFO, *PTEXT_INFO, **PPTEXT_INFO;

typedef VOID (*PIO_APC_ROUTINE)(PVOID, PIO_STATUS_BLOCK, ULONG);
typedef VOID (*PTIMER_APC_ROUTINE)(PVOID, ULONG, LONG);
typedef VOID (*PKNORMAL_ROUTINE)(PVOID, PVOID, PVOID);
struct _KAPC;
typedef VOID (*PKKERNEL_ROUTINE)(struct _KAPC *, PKNORMAL_ROUTINE *, PVOID *,
    PVOID *, PVOID *);
typedef VOID (*PKRUNDOWN_ROUTINE)(struct _KAPC *);

typedef struct _KAPC {
	SHORT Type;
	SHORT Size;
	DWORD Spare0;
	struct _KTHREAD *Thread;
	LIST_ENTRY ApcListEntry;
	PKKERNEL_ROUTINE KernelRoutine;
	PKRUNDOWN_ROUTINE RundownRoutine;
	PKNORMAL_ROUTINE NormalRoutine;
	PVOID NormalContext;
	PVOID SystemArgument1;
	PVOID SystemArgument2;
	CHAR ApcStateIndex;
	KPROCESSOR_MODE ApcMode;
	BOOLEAN Inserted;
} KAPC, *PKAPC, **PPKAPC;

typedef struct _FILE_BASIC_INFORMATION {
	LARGE_INTEGER CreationTime;
	LARGE_INTEGER LastAccessTime;
	LARGE_INTEGER LastWriteTime;
	LARGE_INTEGER ChangeTime;
	ULONG FileAttributes;
} FILE_BASIC_INFORMATION, *PFILE_BASIC_INFORMATION;

/*
 * XXX should be in ntddk.h
 */
typedef struct _FILE_STANDARD_INFORMATION {
	LARGE_INTEGER AllocationSize;
	LARGE_INTEGER EndOfFile;
	ULONG NumberOfLinks;
	BOOLEAN DeletePending;
	BOOLEAN Directory;
} FILE_STANDARD_INFORMATION, *PFILE_STANDARD_INFORMATION;

typedef struct _FILE_POSITION_INFORMATION {
	LARGE_INTEGER CurrentByteOffset;
} FILE_POSITION_INFORMATION, *PFILE_POSITION_INFORMATION;

typedef struct _FILE_END_OF_FILE_INFORMATION {
	LARGE_INTEGER EndOfFile;
} FILE_END_OF_FILE_INFORMATION, *PFILE_END_OF_FILE_INFORMATION;

typedef struct _FILE_FULL_EA_INFORMATION {
	ULONG NextEntryOffset;
	UCHAR Flags;
	UCHAR EaNameLength;
	USHORT EaValueLength;
	CHAR EaName[1];
} FILE_FULL_EA_INFORMATION, *PFILE_FULL_EA_INFORMATION;

typedef struct _FILE_GET_EA_INFORMATION {
	ULONG NextEntryOffset;
	UCHAR EaNameLength;
	CHAR EaName[1];
} FILE_GET_EA_INFORMATION, *PFILE_GET_EA_INFORMATION;

typedef struct _FILE_USER_QUOTA_INFORMATION {
	ULONG NextEntryOffset;
	ULONG SidLength;
	LARGE_INTEGER ChangeTime;
	LARGE_INTEGER QuotaUsed;
	LARGE_INTEGER QuotaThreshold;
	LARGE_INTEGER QuotaLimit;
	SID Sid[1];
} FILE_USER_QUOTA_INFORMATION, *PFILE_USER_QUOTA_INFORMATION;

typedef struct _FILE_QUOTA_LIST_INFORMATION {
	ULONG NextEntryOffset;
	ULONG SidLength;
	SID Sid[1];
} FILE_QUOTA_LIST_INFORMATION, *PFILE_QUOTA_LIST_INFORMATION;

typedef struct _FILE_FS_DEVICE_INFORMATION {
	DEVICE_TYPE DeviceType;
	ULONG Characteristics;
} FILE_FS_DEVICE_INFORMATION, *PFILE_FS_DEVICE_INFORMATION;

typedef struct _FILE_COMPLETION_INFORMATION {
	HANDLE IoCompletionHandle;
	ULONG CompletionKey;
} FILE_COMPLETION_INFORMATION, *PFILE_COMPLETION_INFORMATION;

typedef struct _PORT_MESSAGE_HEADER {
/*000*/	USHORT DataSize;
/*002*/	USHORT MessageSize;
/*004*/	USHORT MessageType;
/*006*/	USHORT VirtualRangesOffset;
/*008*/	CLIENT_ID ClientId;
/*010*/	ULONG MessageId;
/*014*/	ULONG SectionSize;
} PORT_MESSAGE_HEADER, *PPORT_MESSAGE_HEADER;
typedef struct _PORT_MESSAGE_HEADER PORT_MESSAGE, *PPORT_MESSAGE;

typedef struct _CSRSS_MESSAGE_HEADER {		/* XXX */
/*000*/	ULONG Unknown1;
/*004*/	ULONG Opcode;
/*008*/	ULONG Status;
/*00C*/	ULONG Unknown2;
} CSRSS_MESSAGE_HEADER;

typedef struct _CSR_MESSAGE_HEADER {			/* XXX */
/*000*/	struct _PORT_MESSAGE_HEADER;
/*018*/	struct _CSRSS_MESSAGE_HEADER;
} CSR_MESSAGE_HEADER, *PCSR_MESSAGE_HEADER;
typedef struct _CSR_MESSAGE_HEADER CSR_MESSAGE, *PCSR_MESSAGE;

typedef struct _PORT_SECTION_WRITE {
	ULONG Length;
	HANDLE SectionHandle;
	ULONG SectionOffset;
	ULONG ViewSize;
	PVOID ViewBase;
	PVOID TargetViewBase;
} PORT_SECTION_WRITE, *PPORT_SECTION_WRITE;

typedef struct _PORT_SECTION_READ {
	ULONG Length;
	ULONG ViewSize;
	ULONG ViewBase;
} PORT_SECTION_READ, *PPORT_SECTION_READ;

typedef struct _KEY_VALUE_ENTRY {
	PUNICODE_STRING ValueName;
	ULONG DataLength;
	ULONG DataOffset;
	ULONG Type;
} KEY_VALUE_ENTRY, *PKEY_VALUE_ENTRY;

typedef struct _USER_STACK {
	PVOID FixedStackBase;
	PVOID FixedStackLimit;
	PVOID ExpandableStackBase;
	PVOID ExpandableStackLimit;
	PVOID ExpandableStackBottom;
} USER_STACK, *PUSER_STACK;

typedef struct _OBJECT_TYPE_LIST {
	WORD Level;
	WORD Sbz;
	GUID *ObjectType;
} OBJECT_TYPE_LIST, *POBJECT_TYPE_LIST;

/*
 * Thread Environment Blocks are located at 0x7FFDE000, 0x7FFDD000,
 * 0x7FFDC000, and so on.
 */
typedef struct _TEB {
/*000*/	NT_TIB Tib;
/*01C*/	PVOID EnvironmentPointer;
/*020*/	CLIENT_ID Cid;
/*028*/	HANDLE RpcHandle;
/*02C*/	PPVOID ThreadLocalStorage;
/*030*/	struct _PEB *Peb;
/*034*/	DWORD LastErrorValue;
/*038*/	BYTE Reserved_038[116];
/*0AC*/	PVOID Unknown_0AC;
/*0B0*/	BYTE Reserved_0B0[20];
/*0C4*/	LCID Locale;
/*0C8*/	BYTE Reserved_0C8[1752];
/*7A0*/	PVOID Reserved_7A0[277];
/*BF4*/	NTSTATUS LastStatusValue;
/*BF8*/	UNICODE_STRING UnicodeString;
/*C00*/	WCHAR UnicodeBuffer[262];
/*E0C*/	PVOID Reserved_E0C;
/*E10*/	PVOID TlsSlots[64];
/*F10*/	BYTE Reserved_F10[8];
/*F18*/	PVOID Reserved_F18[4];
/*F28*/	ULONG HardErrorDisabled;	/* XXX BOOL? */
/*F2C*/	PVOID Reserved_F2C[21];
/*F80*/	PVOID ReservedForOle;
/*F84*/	PVOID Reserved_F84[4];
/*F94*/	PVOID TlsExpansionSlots;
} TEB, *PTEB, **PPTEB;

typedef struct _PROCESS_PARAMETERS {
/*000*/	ULONG AllocationSize;
/*004*/	ULONG Size;
/*008*/	ULONG Flags;
/*00C*/	ULONG Zero;
/*010*/	LONG Console;
/*014*/	ULONG ProcessGroup;
/*018*/	HANDLE StdInput;
/*01C*/	HANDLE StdOutput;
/*020*/	HANDLE StdError;
/*024*/	UNICODE_STRING CurrentDirectoryName;
/*02C*/	HANDLE CurrentDirectoryHandle;
/*030*/	UNICODE_STRING DllPath;
/*038*/	UNICODE_STRING ImageFile;
/*040*/	UNICODE_STRING CommandLine;
/*048*/	PWSTR Environment;
/*04C*/	ULONG X;
/*050*/	ULONG Y;
/*054*/	ULONG XSize;
/*058*/	ULONG YSize;
/*05C*/	ULONG XCountChars;
/*060*/	ULONG YCountChars;
/*064*/	ULONG FillAttribute;
/*068*/	ULONG Flags2;
/*06C*/	ULONG ShowWindow;
/*070*/	UNICODE_STRING WindowTitle;
/*078*/	UNICODE_STRING Desktop;
/*080*/	UNICODE_STRING Reserved;
/*088*/	UNICODE_STRING Reserved2;
} PROCESS_PARAMETERS, *PPROCESS_PARAMETERS;

typedef struct _MODULE_HEADER {
	DWORD Unknown[2];
	LIST_ENTRY LoadOrder;
	LIST_ENTRY MemOrder;
	LIST_ENTRY InitOrder;
} MODULE_HEADER, *PMODULE_HEADER, **PPMODULE_HEADER;

typedef struct _PROCESS_MODULE_INFO {
/*000*/	DWORD Size;
#if 0
	MODULE_HEADER ModuleHeader;
#else
/*004*/	DWORD Unknown[2];
/*00C*/	LIST_ENTRY LoadOrder;
/*014*/	LIST_ENTRY MemOrder;
/*01C*/	LIST_ENTRY InitOrder;
#endif
} PROCESS_MODULE_INFO, *PPROCESS_MODULE_INFO, **PPPROCESS_MODULE_INFO;

/*
 * Module flags.
 */
#define STATIC_LINK		0x00000002
#define IMAGE_DLL		0x00000004
#define LOAD_IN_PROGRESS	0x00001000
#define UNLOAD_IN_PROGRESS	0x00002000
#define ENTRY_PROCESSED		0x00004000
#define ENTRY_INSERTED		0x00008000
#define CURRENT_LOAD		0x00010000
#define FAILED_BUILTIN_LOAD	0x00020000
#define DONT_CALL_FOR_THREAD	0x00040000
#define PROCESS_ATTACH_CALLED	0x00080000
#define DEBUG_SYMBOLS_LOADED	0x00100000
#define IMAGE_NOT_AT_BASE	0x00200000
#define WX86_IGNORE_MACHINETYPE	0x00400000

typedef struct _MODULE_ENTRY {
/*000*/	LIST_ENTRY LoadOrder;
/*008*/	LIST_ENTRY MemOrder;
/*010*/	LIST_ENTRY InitOrder;
/*018*/	DWORD ImageBase;	/* Used as HMODULE in Win32 API */
/*01C*/	DWORD EntryPoint;
/*020*/	ULONG ImageSize;
/*024*/	UNICODE_STRING PathFileName;
/*02C*/	UNICODE_STRING FileName;
/*034*/	ULONG ModuleFlags;
/*038*/	SHORT LoadCount;
/*03A*/	WORD Fill;
/*03C*/	LIST_ENTRY Link;	/* Points to entry in LdrpHashTable */
/*044*/	ULONG TimeDateStamp;
} MODULE_ENTRY, *PMODULE_ENTRY, **PPMODULE_ENTRY;

/*
 * Process Environment Block is located at 0x7FFDF000.
 */
typedef struct _PEB {
/*000*/	BOOLEAN InheritedAddressSpace;
/*001*/	BOOLEAN ReadImageFileExecOptions;
/*002*/	BOOLEAN BeingDebugged;
	BYTE b003;
	DWORD d004;
/*008*/	PVOID SectionBaseAddress;
/*00C*/	PPROCESS_MODULE_INFO ProcessModuleInfo;
/*010*/	PPROCESS_PARAMETERS ProcessParameters;
/*014*/	DWORD SubSystemData;
/*018*/	HANDLE ProcessHeap;
/*01C*/	PCRITICAL_SECTION FastPebLock;
/*020*/	VOID (*AcquireFastPebLock)(PCRITICAL_SECTION);
/*024*/	VOID (*ReleaseFastPebLock)(PCRITICAL_SECTION);
	DWORD d028;
/*02C*/	PPVOID User32Dispatch;
	DWORD d030;
	DWORD d034;
	DWORD d038;
/*03C*/	DWORD TlsBitMapSize;
/*040*/	PRTL_BITMAP TlsBitMap;
/*044*/	DWORD TlsBitMapData[2];
	PVOID p04C;
	PVOID p050;
/*054*/	PTEXT_INFO TextInfo;
/*058*/	PWCHAR InitAnsiCodePageData;
/*05C*/	PWCHAR InitOemCodePageData;
/*060*/	PSHORT InitUnicodeCaseTableData;
/*064*/	DWORD KeNumberProcessors;
/*068*/	DWORD NtGlobalFlag;
	DWORD d06C;
/*070*/	LARGE_INTEGER MmCriticalSectionTimeout;
/*078*/	DWORD MmHeapSegmentReserve;
/*07C*/	DWORD MmHeapSegmentCommit;
/*080*/	DWORD MmHeapDeCommitTotalFreeThreshold;
/*084*/	DWORD MmHeapDeCommitFreeBlockThreshold;
/*088*/	DWORD NumberOfHeaps;
/*08C*/	DWORD AvailableHeaps;
/*090*/	PHANDLE ProcessHeapsListBuffer;
	DWORD d094;
	DWORD d098;
	DWORD d09C;
/*0A0*/	PCRITICAL_SECTION LoaderLock;
/*0A4*/	DWORD NtMajorVersion;
/*0A8*/	DWORD NtMinorVersion;
/*0AC*/	WORD NtBuildNumber;
/*0AE*/	WORD CmNtCSDVersion;
/*0B0*/	DWORD PlatformId;
/*0B4*/	DWORD Subsystem;
/*0B8*/	DWORD MajorSubsystemVersion;
/*0BC*/	DWORD MinorSubsystemVersion;
/*0C0*/	KAFFINITY AffinityMask;
/*0C4*/	DWORD ad0C4[35];
	PVOID p150;
	DWORD ad154[32];
/*1D4*/	HANDLE Win32WindowStation;
	DWORD d1D8;
	DWORD d1DC;
/*1E0*/	PWORD CSDVersion;
	DWORD d1E4;
} PEB, *PPEB, **PPPEB;

/*
 * XXX should be in ntddk.h.
 */
typedef struct _PROCESS_BASIC_INFORMATION {
	NTSTATUS ExitStatus;
	PPEB PebBaseAddress;
	ULONG_PTR AffinityMask;
	KPRIORITY BasePriority;
	ULONG_PTR UniqueProcessId;
	ULONG_PTR InheritedFromUniqueProcessId;
} PROCESS_BASIC_INFORMATION, *PPROCESS_BASIC_INFORMATION;

typedef struct _PROCESS_DEVICEMAP_INFORMATION {
	union {
		struct {
			HANDLE DirectoryHandle;
		} Set;
		struct {
			ULONG DriveMap;
			UCHAR DriveType[32];
		} Query;
	};
} PROCESS_DEVICEMAP_INFORMATION, *PPROCESS_DEVICEMAP_INFORMATION;

typedef struct _THREAD_BASIC_INFORMATION {
	NTSTATUS ExitStatus;
	PNT_TIB TebBaseAddress;
	CLIENT_ID ClientId;
	KAFFINITY AffinityMask;
	KPRIORITY Priority;
	KPRIORITY BasePriority;
} THREAD_BASIC_INFORMATION, *PTHREAD_BASIC_INFORMATION;

typedef struct _KERNEL_USER_TIMES {
	LARGE_INTEGER CreateTime;
	LARGE_INTEGER ExitTime;
	LARGE_INTEGER KernelTime;
	LARGE_INTEGER UserTime;
} KERNEL_USER_TIMES, *PKERNEL_USER_TIMES;

/*
 * XXX should be in ntdef.h.
 */
typedef enum _NT_PRODUCT_TYPE {
	NtProductWinNt = 1,
	NtProductLanManNt,
	NtProductServer
} NT_PRODUCT_TYPE, *PNT_PRODUCT_TYPE;

/*
 * XXX should be in ntddk.h.
 */
#define PROCESSOR_FEATURE_MAX	64

#define KI_USER_SHARED_DATA	0xffdf0000
#define SharedUserData		((KUSER_SHARED_DATA * const)KI_USER_SHARED_DATA)

typedef struct _KSYSTEM_TIME {
	ULONG LowPart;
	LONG High1Time;
	LONG High2Time;
} KSYSTEM_TIME, *PKSYSTEM_TIME;

typedef enum _ALTERNATIVE_ARCHITECTURE_TYPE {
	StandardDesign,
	NEC98x86,
	EndAlternatives
} ALTERNATIVE_ARCHITECTURE_TYPE;

typedef struct _KUSER_SHARED_DATA {
/*000*/	volatile ULONG TickCountLow;
/*004*/	ULONG TickCountMultiplier;
/*008*/	volatile KSYSTEM_TIME InterruptTime;
/*014*/	volatile KSYSTEM_TIME SystemTime;
/*020*/	volatile KSYSTEM_TIME TimeZoneBias;
/*02C*/	USHORT ImageNumberLow;
/*02E*/	USHORT ImageNumberHigh;
/*030*/	WCHAR NtSystemRoot[260];
/*238*/	ULONG MaxStackTraceDepth;
/*23C*/	ULONG CryptoExponent;
/*240*/	ULONG TimeZoneId;
/*244*/	ULONG Reserved2[8];
/*264*/	NT_PRODUCT_TYPE NtProductType;
/*268*/	BOOLEAN ProductTypeIsValid;
/*26C*/	ULONG NtMajorVersion;
/*270*/	ULONG NtMinorVersion;
/*274*/	BOOLEAN ProcessorFeatures[PROCESSOR_FEATURE_MAX];
	ULONG Reserved1;
	ULONG Reserved3;
	volatile ULONG TimeSlip;
	ALTERNATIVE_ARCHITECTURE_TYPE AlternativeArchitecture;
	LARGE_INTEGER SystemExpirationDate;
	ULONG SuiteMask;
#ifdef REMOTE_BOOT
	ULONG SystemFlags;
	WCHAR RemoteBootServerPath[260];
#endif
	BOOLEAN KdDebuggerEnabled;
} KUSER_SHARED_DATA, *PKUSER_SHARED_DATA;

/*
 * XXX should be in ntddk.h.
 */
typedef struct _TIME_FIELDS {
	CSHORT Year;
	CSHORT Month;
	CSHORT Day;
	CSHORT Hour;
	CSHORT Minute;
	CSHORT Second;
	CSHORT Milliseconds;
	CSHORT Weekday;
} TIME_FIELDS, *PTIME_FIELDS;

typedef struct _DESCRIPTOR_TABLE_ENTRY {
	ULONG Selector;
	LDT_ENTRY Descriptor;
} DESCRIPTOR_TABLE_ENTRY, *PDESCRIPTOR_TABLE_ENTRY;

/*
 * XXX should be in ntapi.h.
 */
typedef enum _HARDERROR_RESPONSE_OPTION {
	OptionAbortRetryIgnore,
	OptionOk,
	OptionOkCancel,
	OptionRetryCancel,
	OptionYesNo,
	OptionYesNoCancel,
	OptionShutdownSystem
} HARDERROR_RESPONSE_OPTION, *PHARDERROR_RESPONSE_OPTION;

typedef enum _HARDERROR_RESPONSE {
	ResponseReturnToCaller,
	ResponseNotHandled,
	ResponseAbort,
	ResponseCancel,
	ResponseIgnore,
	ResponseNo,
	ResponseOk,
	ResponseRetry,
	ResponseYes
} HARDERROR_RESPONSE, *PHARDERROR_RESPONSE;

/*
 * XXX those are not found in ntddk.h.
 */
typedef struct _ATOM_BASIC_INFORMATION {
	USHORT ReferenceCount;
	USHORT Pinned;
	USHORT NameLength;
	WCHAR Name[1];
} ATOM_BASIC_INFORMATION, *PATOM_BASIC_INFORMATION;

typedef struct _SYSTEM_BASIC_INFORMATION {
	ULONG Unknown;
	ULONG MaximumIncrement;
	ULONG PhysicalPageSize;
	ULONG NumberOfPhysicalPages;
	ULONG LowestPhysicalPage;
	ULONG HighestPhysicalPage;
	ULONG AllocationGranularity;
	ULONG LowestUserAddress;
	ULONG HighestUserAddress;
	ULONG ActiveProcessors;
	UCHAR NumberProcessors;
} SYSTEM_BASIC_INFORMATION, *PSYSTEM_BASIC_INFORMATION;

typedef struct _SYSTEM_SET_TIME_ADJUSTMENT {
	ULONG  TimeAdjustment;
	BOOLEAN  TimeSynchronization;
} SYSTEM_SET_TIME_ADJUSTMENT, *PSYSTEM_SET_TIME_ADJUSTMENT;

typedef struct _OBJECT_HANDLE_ATTRIBUTE_INFORMATION {
	BOOLEAN Inherit;
	BOOLEAN ProtectFromClose;
} OBJECT_HANDLE_ATTRIBUTE_INFORMATION, *POBJECT_HANDLE_ATTRIBUTE_INFORMATION;

typedef struct _FILE_MAILSLOT_QUERY_INFORMATION {
	ULONG MaxMessageSize;
	ULONG Unknown;
	ULONG NextSize;
	ULONG MessageCount;
	LARGE_INTEGER ReadTimeout;
} FILE_MAILSLOT_QUERY_INFORMATION, *PFILE_MAILSLOT_QUERY_INFORMATION;

typedef struct _FILE_MAILSLOT_SET_INFORMATION {
	PLARGE_INTEGER ReadTimeout;
} FILE_MAILSLOT_SET_INFORMATION, *PFILE_MAILSLOT_SET_INFORMATION;

typedef struct _FILE_ALLOCATION_INFORMATION {
	LARGE_INTEGER AllocationSize;
} FILE_ALLOCATION_INFORMATION, *PFILE_ALLOCATION_INFORMATION;

typedef struct _FILE_PIPE_INFORMATION {
	BOOL ReadModeMessage;
	BOOL NoWait;
} FILE_PIPE_INFORMATION, *PFILE_PIPE_INFORMATION;

typedef struct _FILE_PIPE_LOCAL_INFORMATION {
	ULONG MessageType;
	ULONG Unknown1;
	ULONG MaxInstances;
	ULONG CurInstances;
	ULONG InBufferSize;
	ULONG Unknown2;
	ULONG OutBufferSize;
	ULONG Unknown3[2];
	ULONG ServerEnd;
} FILE_PIPE_LOCAL_INFORMATION, *PFILE_PIPE_LOCAL_INFORMATION;

typedef struct _FILE_PIPE_REMOTE_INFORMATION {
	LARGE_INTEGER CollectDataTimeout;
	ULONG MaxCollectionCount;
} FILE_PIPE_REMOTE_INFORMATION, *PFILE_PIPE_REMOTE_INFORMATION;

typedef struct _FILE_NETWORK_OPEN_INFORMATION {
	LARGE_INTEGER CreationTime;
	LARGE_INTEGER LastAccessTime;
	LARGE_INTEGER LastWriteTime;
	LARGE_INTEGER ChangeTime;
	LARGE_INTEGER AllocationSize;
	LARGE_INTEGER EndOfFile;
	ULONG FileAttributes;
} FILE_NETWORK_OPEN_INFORMATION, *PFILE_NETWORK_OPEN_INFORMATION;

typedef struct _PROCESS_PRIORITY_CLASS {
	BOOLEAN Foreground;
	UCHAR PriorityClass;
} PROCESS_PRIORITY_CLASS, *PPROCESS_PRIORITY_CLASS;

typedef struct _PROCESS_SESSION_INFORMATION {
	DWORD SessionId;
} PROCESS_SESSION_INFORMATION, *PPROCESS_SESSION_INFORMATION;

typedef struct _SYSTEM_QUERY_TIME_ADJUSTMENT {
	ULONG TimeAdjustment;
	ULONG MaximumIncrement;
	BOOLEAN TimeSynchronization;
} SYSTEM_QUERY_TIME_ADJUSTMENT, *PSYSTEM_QUERY_TIME_ADJUSTMENT;

/*
 * Internal structure.
 * Used in RtlDosPathNameToNtPathName_U().
 */
typedef struct _RTL_PATH_NAME_INFO {
/*000*/	UNICODE_STRING PathName;
/*008*/	HANDLE Handle;
} RTL_PATH_NAME_INFO, *PRTL_PATH_NAME_INFO;

#define TH32_SNAPSHOT_HEAP		0
#define TH32_SNAPSHOT_PROCESS		1
#define TH32_SNAPSHOT_MODULE		2
#define TH32_SNAPSHOT_THREAD		3

typedef struct _TOOLHELP32_SNAPSHOT_HEADER {
	DWORD TotalEntries[4];
	DWORD FirstEntryOffset[4];
	DWORD RetrievedEntries[4];
} TOOLHELP32_SNAPSHOT_HEADER, *PTOOLHELP32_SNAPSHOT_HEADER;

typedef struct _BASE_STATIC_SERVER_DATA {
#if 0
	struct _SYSTEM_STRINGS;
#else
/*000*/	UNICODE_STRING SystemRoot;
/*008*/	UNICODE_STRING System32Root;
/*010*/	UNICODE_STRING NamedObjectName;
#endif
/*018*/	WORD Unknown_018[3];
/*01C*/	WORD Length;
/*020*/	WORD MaximumLength;
/*022*/	WCHAR RevisionName[130];	/* e.g. "Service Pack 3" */
/*128*/	DWORD Unknown_128;
/*12C*/	DWORD PageSize;
	DWORD Unknown_130;
	DWORD Unknown_134;
	DWORD Unknown_138;
/*13C*/	LPVOID LowestUserAddress;
	DWORD Unknown_140;
/*144*/	LPVOID HighestUserAddress;
/*148*/	DWORD_PTR AffinityMask;
} BASE_STATIC_SERVER_DATA, *PBASE_STATIC_SERVER_DATA;

/*
 * Inline functions.
 */

static inline PTEB
NtCurrentTeb(void)
{
	DWORD addr;

	__asm __volatile("movl %%fs:0x18,%0" : "=a" (addr));
	return (PTEB)addr;
}

/*
 * NTDLL API prototypes.
 *   Csr: client-server runtime
 *   Ldr: image loader
 *   Rtl: runtime library
 */

/*
 * Client-server runtime functions.
 */
NTSTATUS NTAPI CsrClientCallServer(PCSR_MESSAGE, PVOID, ULONG, LONG);

/*
 * Debug functions.
 */
void NTAPI DbgBreakPoint(void);
NTSTATUS NTAPI DbgUiContinue(PCLIENT_ID, DWORD);

/*
 * Image loader functions.
 */
NTSTATUS NTAPI LdrDisableThreadCalloutsForDll(HMODULE);
NTSTATUS NTAPI LdrGetDllHandle(LPWSTR, PVOID, PUNICODE_STRING, HMODULE *);
NTSTATUS NTAPI LdrGetProcedureAddress(HMODULE, PANSI_STRING, DWORD, PVOID *);
NTSTATUS NTAPI LdrLoadDll(LPCWSTR, PULONG, PUNICODE_STRING, HMODULE *);
VOID NTAPI LdrShutdownProcess(void);
VOID NTAPI LdrShutdownThread(void);
BOOLEAN NTAPI LdrUnloadAlternateResourceModule(HMODULE);
NTSTATUS NTAPI LdrUnloadDll(HMODULE);

/*
 * Runtime library functions.
 */
void NTAPI RtlAcquirePebLock(void);
ULONG NTAPI RtlAnsiStringToUnicodeSize(PANSI_STRING);
NTSTATUS NTAPI RtlAnsiStringToUnicodeString(PUNICODE_STRING, PANSI_STRING,
    BOOLEAN);
PHEAP_HANDLE_ENTRY NTAPI RtlAllocateHandle(PHEAP_HANDLE_TABLE, PDWORD);
LPVOID NTAPI RtlAllocateHeap(HANDLE, DWORD, SIZE_T);
NTSTATUS NTAPI RtlAppendUnicodeStringToString(PUNICODE_STRING, PUNICODE_STRING);
NTSTATUS NTAPI RtlAppendUnicodeToString(PUNICODE_STRING, PCWSTR);
BOOLEAN NTAPI RtlAreBitsClear(PRTL_BITMAP, ULONG, ULONG);
BOOLEAN NTAPI RtlAreBitsSet(PRTL_BITMAP, ULONG, ULONG);
NTSTATUS NTAPI RtlCharToInteger(PCSZ, ULONG, PULONG);
ULONG NTAPI RtlCheckBit(PRTL_BITMAP, ULONG);
NTSTATUS NTAPI RtlCheckRegistryKey(ULONG, PWSTR);
VOID NTAPI RtlClearAllBits(PRTL_BITMAP);
VOID NTAPI RtlClearBits(PRTL_BITMAP, ULONG, ULONG);
SIZE_T NTAPI RtlCompactHeap(HANDLE, DWORD);
SIZE_T NTAPI RtlCompareMemory(CONST VOID *, CONST VOID *, SIZE_T);
SIZE_T NTAPI RtlCompareMemoryUlong(CONST VOID *, SIZE_T, ULONG);
LONG NTAPI RtlCompareString(PSTRING, PSTRING, BOOLEAN);
LONG NTAPI RtlCompareUnicodeString(PUNICODE_STRING, PUNICODE_STRING,
    BOOLEAN);
LARGE_INTEGER NTAPI RtlConvertLongToLargeInteger(LONG);
LUID NTAPI RtlConvertLongToLuid(LONG);
LARGE_INTEGER NTAPI RtlConvertUlongToLargeInteger(ULONG);
LUID NTAPI RtlConvertUlongToLuid(ULONG);
void NTAPI RtlCopyString(PSTRING, PSTRING);
void NTAPI RtlCopyUnicodeString(PUNICODE_STRING, PUNICODE_STRING);
HANDLE NTAPI RtlCreateHeap(DWORD, LPVOID, SIZE_T, SIZE_T, BOOL,
    PRTL_HEAP_INFORMATION);
PVOID NTAPI RtlCreateQueryDebugBuffer(PVOID, PVOID);
NTSTATUS NTAPI RtlCreateTimerQueue(PHANDLE);
void NTAPI RtlDeleteCriticalSection(LPCRITICAL_SECTION);
NTSTATUS NTAPI RtlDeleteTimer(HANDLE, HANDLE, HANDLE);
NTSTATUS NTAPI RtlDeleteTimerQueueEx(HANDLE, HANDLE);
NTSTATUS NTAPI RtlDeregisterWait(HANDLE);
NTSTATUS NTAPI RtlDeregisterWaitEx(HANDLE, HANDLE);
HANDLE NTAPI RtlDestroyHeap(HANDLE);
void NTAPI RtlDestroyQueryDebugBuffer(PVOID);
LONG NTAPI RtlDetermineDosPathNameType_U(LPCWSTR);
BOOLEAN NTAPI RtlDoesFileExists_U(LPCWSTR);
BOOLEAN NTAPI RtlDosPathNameToNtPathName_U(LPCWSTR, PUNICODE_STRING,
    LPWSTR *, PRTL_PATH_NAME_INFO);
ULONG NTAPI RtlDosSearchPath_U(LPCWSTR, LPCWSTR, LPCWSTR, ULONG, LPWSTR,
    LPWSTR *);
NTSTATUS NTAPI RtlEnterCriticalSection(LPCRITICAL_SECTION);
BOOLEAN NTAPI RtlEqualString(PSTRING, PSTRING, BOOLEAN);
BOOLEAN NTAPI RtlEqualUnicodeString(PCUNICODE_STRING, PCUNICODE_STRING,
    BOOLEAN);
LARGE_INTEGER NTAPI RtlExtendedLargeIntegerDivide(LARGE_INTEGER, ULONG, PULONG);
VOID NTAPI RtlFillMemoryUlong(PVOID, SIZE_T, ULONG);
BOOLEAN NTAPI RtlFreeHandle(PHEAP_HANDLE_TABLE, PHEAP_HANDLE_ENTRY);
BOOLEAN NTAPI RtlFreeHeap(HANDLE, DWORD, LPVOID);
void NTAPI RtlFreeAnsiString(PANSI_STRING);
void NTAPI RtlFreeUnicodeString(PUNICODE_STRING);
DWORD NTAPI RtlGetCurrentDirectory_U(DWORD, LPWSTR);
ULONG NTAPI RtlGetFullPathName_U(LPCWSTR, DWORD, LPWSTR, LPWSTR *);
ULONG NTAPI RtlGetLongestNtPathLength(VOID);
DWORD NTAPI RtlGetNtGlobalFlags(void);
BOOL NTAPI RtlGetNtProductType(PDWORD);
DWORD NTAPI RtlGetProcessHeaps(DWORD, PHANDLE);
BOOLEAN NTAPI RtlGetUserInfoHeap(HANDLE, DWORD, LPCVOID, HGLOBAL *, PDWORD);
NTSTATUS NTAPI RtlGetVersion(LPOSVERSIONINFOW);
PVOID NTAPI RtlImageDirectoryEntryToData(HMODULE, BOOLEAN, WORD, PULONG);
PIMAGE_NT_HEADERS NTAPI RtlImageNtHeader(HMODULE);
PIMAGE_SECTION_HEADER NTAPI RtlImageRvaToSection(PIMAGE_NT_HEADERS, HMODULE,
    DWORD);
void NTAPI RtlInitAnsiString(PANSI_STRING, PCSTR);
NTSTATUS NTAPI RtlInitializeCriticalSection(LPCRITICAL_SECTION);
NTSTATUS NTAPI RtlInitializeCriticalSectionAndSpinCount(LPCRITICAL_SECTION,
    DWORD);
void NTAPI RtlInitString(PSTRING, PCSTR);
void NTAPI RtlInitUnicodeString(PUNICODE_STRING, PCWSTR);
DWORD NTAPI RtlIsDosDeviceName_U(LPCWSTR);
BOOLEAN NTAPI RtlIsNameLegalDOS8Dot3(PUNICODE_STRING, POEM_STRING, PBOOLEAN);
BOOLEAN NTAPI RtlIsValidHandle(PHEAP_HANDLE_TABLE, PHEAP_HANDLE_ENTRY);
NTSTATUS NTAPI RtlLeaveCriticalSection(LPCRITICAL_SECTION);
BOOLEAN WINAPI RtlLockHeap(HANDLE);
NTSTATUS NTAPI RtlMultiByteToUnicodeN(PWSTR, ULONG, PULONG, PSTR, ULONG);
NTSTATUS NTAPI RtlMultiByteToUnicodeSize(PULONG, PSTR, ULONG);
DWORD NTAPI RtlNtStatusToDosError(NTSTATUS);
ULONG NTAPI RtlOemStringToUnicodeSize(PANSI_STRING);
NTSTATUS NTAPI RtlOemStringToUnicodeString(PUNICODE_STRING, POEM_STRING,
    BOOLEAN);
BOOLEAN NTAPI RtlPrefixUnicodeString(PUNICODE_STRING, PUNICODE_STRING,
    BOOLEAN);
NTSTATUS NTAPI RtlQueryEnvironmentVariable_U(LPWSTR, PUNICODE_STRING,
    PUNICODE_STRING);
NTSTATUS NTAPI RtlQueryProcessDebugInformation(DWORD, DWORD, PVOID);
#if (_WIN32_WINNT >= 0x0500)	/* for WAITORTIMERCALLBACK */
NTSTATUS NTAPI RtlRegisterWait(PHANDLE, HANDLE, WAITORTIMERCALLBACK, PVOID,
    ULONG, ULONG);
#endif
NTSTATUS NTAPI RtlSetIoCompletionCallback(HANDLE,
    LPOVERLAPPED_COMPLETION_ROUTINE, ULONG);
void NTAPI RtlRaiseException(PEXCEPTION_RECORD);
void NTAPI RtlRaiseStatus(NTSTATUS);
LPVOID NTAPI RtlReAllocateHeap(HANDLE, DWORD, LPVOID, SIZE_T);
void NTAPI RtlReleasePebLock(void);
SIZE_T NTAPI RtlSizeHeap(HANDLE, DWORD, LPCVOID);
NTSTATUS NTAPI RtlSetCurrentDirectory_U(PUNICODE_STRING);
NTSTATUS NTAPI RtlSetEnvironmentVariable(LPWSTR *, PUNICODE_STRING,
    PUNICODE_STRING);
BOOLEAN NTAPI RtlSetUserValueHeap(HANDLE, DWORD, LPCVOID, HGLOBAL);
BOOLEAN NTAPI RtlTimeFieldsToTime(PTIME_FIELDS, PLARGE_INTEGER);
void NTAPI RtlTimeToTimeFields(PLARGE_INTEGER, PTIME_FIELDS);
ULONG NTAPI RtlUnicodeStringToAnsiSize(PUNICODE_STRING);
NTSTATUS NTAPI RtlUnicodeStringToAnsiString(PANSI_STRING, PUNICODE_STRING,
    BOOLEAN);
ULONG NTAPI RtlUnicodeStringToOemSize(PUNICODE_STRING);
NTSTATUS NTAPI RtlUnicodeStringToOemString(POEM_STRING, PUNICODE_STRING,
    BOOLEAN);
NTSTATUS NTAPI RtlUnicodeToMultiByteN(PSTR, ULONG, PULONG, PWSTR, ULONG);
NTSTATUS NTAPI RtlUnicodeToMultiByteSize(PULONG, LPCWSTR, ULONG);
WCHAR NTAPI RtlUpcaseUnicodeChar(WCHAR);
NTSTATUS NTAPI RtlUpdateTimer(HANDLE, HANDLE, ULONG, ULONG);
NTSTATUS NTAPI RtlUpcaseUnicodeString(PUNICODE_STRING, PCUNICODE_STRING,
    BOOLEAN);
NTSTATUS NTAPI RtlUpcaseUnicodeStringToCountedOemString(POEM_STRING,
    PUNICODE_STRING, BOOLEAN);
NTSTATUS NTAPI RtlUpdateTimer(HANDLE, HANDLE, ULONG, ULONG);
BOOL WINAPI RtlUnlockHeap(HANDLE);
CHAR NTAPI RtlUpperChar(CHAR);
void NTAPI RtlUpperString(PSTRING, PSTRING);
BOOL NTAPI RtlValidateHeap(HANDLE, DWORD, LPCVOID);
NTSTATUS WINAPI RtlWalkHeap(HANDLE, PRTL_PROCESS_HEAP_ENTRY);
NTSTATUS NTAPI RtlQueueWorkItem(LPTHREAD_START_ROUTINE, PVOID, ULONG);
void NTAPI RtlpUnWaitCriticalSection(LPCRITICAL_SECTION);
NTSTATUS NTAPI RtlVerifyVersionInfo(LPOSVERSIONINFOEXW, DWORD, DWORDLONG);
void NTAPI RtlpWaitForCriticalSection(LPCRITICAL_SECTION);
ULONG NTAPI RtlxAnsiStringToUnicodeSize(PANSI_STRING);
ULONG NTAPI RtlxOemStringToUnicodeSize(PANSI_STRING);
ULONG NTAPI RtlxUnicodeStringToAnsiSize(PUNICODE_STRING);
ULONG NTAPI RtlxUnicodeStringToOemSize(PUNICODE_STRING);

LONGLONG WINAPI _allmul(LONGLONG, LONGLONG);

/*
 * Undocumented KERNEL32 functions.
 */
BOOL WINAPI CloseConsoleHandle(HANDLE);
HANDLE WINAPI GetConsoleInputWaitHandle(void);
BOOLEAN WINAPI VerifyConsoleIoHandle(HANDLE);

/*
 * Win32 Native API prototypes.
 */

NTSTATUS NTAPI NtAcceptConnectPort(PHANDLE PortHandle, ULONG PortIdentifier,
    PPORT_MESSAGE Message, BOOLEAN Accept, PPORT_SECTION_WRITE WriteSection,
    PPORT_SECTION_READ ReadSection);
NTSTATUS NTAPI NtAccessCheck(PSECURITY_DESCRIPTOR SecurityDescriptor,
    HANDLE TokenHandle, ACCESS_MASK DesiredAccess,
    PGENERIC_MAPPING GenericMapping,
    PPRIVILEGE_SET PrivilegeSet, PULONG PrivilegeSetLength,
    PACCESS_MASK GrantedAccess, PBOOLEAN AccessStatus);
NTSTATUS NTAPI NtAccessCheckAndAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, PUNICODE_STRING ObjectTypeName,
    PUNICODE_STRING ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor,
    ACCESS_MASK DesiredAccess, PGENERIC_MAPPING GenericMapping,
    BOOLEAN ObjectCreation, PACCESS_MASK GrantedAccess,
    PBOOLEAN AccessStatus, PBOOLEAN GenerateOnClose);
NTSTATUS NTAPI NtAccessCheckByType(PSECURITY_DESCRIPTOR SecurityDescriptor,
    PSID PrincipalSelfSid, HANDLE TokenHandle,
    ULONG DesiredAccess, POBJECT_TYPE_LIST ObjectTypeList,
    ULONG ObjectTypeListLength, PGENERIC_MAPPING GenericMapping,
    PPRIVILEGE_SET PrivilegeSet, PULONG PrivilegeSetLength,
    PACCESS_MASK GrantedAccess, PULONG AccessStatus);
NTSTATUS NTAPI NtAccessCheckByTypeAndAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, PUNICODE_STRING ObjectTypeName, PUNICODE_STRING ObjectName,
    PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid,
    ACCESS_MASK DesiredAccess, AUDIT_EVENT_TYPE AuditType, ULONG Flags,
    POBJECT_TYPE_LIST ObjectTypeList, ULONG ObjectTypeListLength,
    PGENERIC_MAPPING GenericMapping, BOOLEAN ObjectCreation,
    PACCESS_MASK GrantedAccess, PULONG AccessStatus, PBOOLEAN GenerateOnClose);
NTSTATUS NTAPI NtAccessCheckByTypeResultList(
    PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid,
    HANDLE TokenHandle, ACCESS_MASK DesiredAccess,
    POBJECT_TYPE_LIST ObjectTypeList, ULONG ObjectTypeListLength,
    PGENERIC_MAPPING GenericMapping,
    PPRIVILEGE_SET PrivilegeSet, PULONG PrivilegeSetLength,
    PACCESS_MASK GrantedAccessList, PULONG AccessStatusList);
NTSTATUS NTAPI NtAccessCheckByTypeResultListAndAuditAlarm(
    PUNICODE_STRING SubsystemName, PVOID HandleId,
    PUNICODE_STRING ObjectTypeName, PUNICODE_STRING ObjectName,
    PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid,
    ACCESS_MASK DesiredAccess, AUDIT_EVENT_TYPE AuditType, ULONG Flags,
    POBJECT_TYPE_LIST ObjectTypeList, ULONG ObjectTypeListLength,
    PGENERIC_MAPPING GenericMapping, BOOLEAN ObjectCreation,
    PACCESS_MASK GrantedAccessList, PULONG AccessStatusList,
    PULONG GenerateOnClose);
NTSTATUS NTAPI NtAccessCheckByTypeResultListAndAuditAlarmByHandle(
    PUNICODE_STRING SubsystemName, PVOID HandleId,
    HANDLE TokenHandle, PUNICODE_STRING ObjectTypeName,
    PUNICODE_STRING ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor,
    PSID PrincipalSelfSid, ACCESS_MASK DesiredAccess,
    AUDIT_EVENT_TYPE AuditType, ULONG Flags, POBJECT_TYPE_LIST ObjectTypeList,
    ULONG ObjectTypeListLength, PGENERIC_MAPPING GenericMapping,
    BOOLEAN ObjectCreation, PACCESS_MASK GrantedAccessList,
    PULONG AccessStatusList, PULONG GenerateOnClose);
NTSTATUS NTAPI NtAddAtom(PWSTR String, ULONG StringLength, PUSHORT Atom);
NTSTATUS NTAPI NtAdjustGroupsToken(HANDLE TokenHandle, BOOLEAN ResetToDefault,
    PTOKEN_GROUPS NewState, ULONG BufferLength, PTOKEN_GROUPS PreviousState,
    PULONG ReturnLength);
NTSTATUS NTAPI NtAdjustPrivilegesToken(HANDLE TokenHandle,
    BOOLEAN DisableAllPrivileges, PTOKEN_PRIVILEGES NewState,
    ULONG BufferLength, PTOKEN_PRIVILEGES PreviousState, PULONG ReturnLength);
NTSTATUS NTAPI NtAlertResumeThread(HANDLE ThreadHandle,
    PULONG PreviousSuspendCount);
NTSTATUS NTAPI NtAlertThread(HANDLE ThreadHandle);
NTSTATUS NTAPI NtAllocateLocallyUniqueId(PLUID Luid);
NTSTATUS NTAPI NtAllocateUserPhysicalPages(HANDLE ProcessHandle,
    PULONG NumberOfPages, PULONG PageFrameNumbers);
NTSTATUS NTAPI NtAllocateUuids(PLARGE_INTEGER UuidLastTimeAllocated,
    PULONG UuidDeltaTime, PULONG UuidSequenceNumber, PUCHAR UuidSeed);
NTSTATUS NTAPI NtAllocateVirtualMemory(HANDLE ProcessHandle, PVOID *BaseAddress,
    ULONG ZeroBits, PULONG AllocationSize, ULONG AllocationType, ULONG Protect);
NTSTATUS NTAPI NtAreMappedFilesTheSame(PVOID Address1, PVOID Address2);
NTSTATUS NTAPI NtAssignProcessToJobObject(HANDLE JobHandle,
    HANDLE ProcessHandle);
NTSTATUS NTAPI NtCallbackReturn(PVOID Result, ULONG ResultLength,
    NTSTATUS Status);
NTSTATUS NTAPI NtCancelIoFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock);
NTSTATUS NTAPI NtCancelTimer(HANDLE TimerHandle, PBOOLEAN PreviousState);
NTSTATUS NTAPI NtCancelDeviceWakeupRequest(HANDLE DeviceHandle);
NTSTATUS NTAPI NtClearEvent(HANDLE EventHandle);
NTSTATUS NTAPI NtClose(HANDLE Handle);
NTSTATUS NTAPI NtCloseObjectAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, BOOLEAN GenerateOnClose);
NTSTATUS NTAPI NtCompleteConnectPort(HANDLE PortHandle);
NTSTATUS NTAPI NtConnectPort(PHANDLE PortHandle, PUNICODE_STRING PortName,
    PSECURITY_QUALITY_OF_SERVICE SecurityQos,
    PPORT_SECTION_WRITE WriteSection,
    PPORT_SECTION_READ ReadSection, PULONG MaxMessageSize,
    PVOID ConnectData, PULONG ConnectDataLength);
NTSTATUS NTAPI NtContinue(PCONTEXT Context, BOOLEAN TestAlert);
NTSTATUS NTAPI NtCreateDirectoryObject(PHANDLE DirectoryHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtCreateEvent(PHANDLE EventHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes,
    EVENT_TYPE EventType, BOOLEAN InitialState);
NTSTATUS NTAPI NtCreateEventPair(PHANDLE EventPairHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtCreateFile(PHANDLE FileHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PIO_STATUS_BLOCK IoStatusBlock,
    PLARGE_INTEGER AllocationSize, ULONG FileAttributes,
    ULONG ShareAccess, ULONG CreateDisposition,
    ULONG CreateOptions, PVOID EaBuffer, ULONG EaLength);
NTSTATUS NTAPI NtCreateIoCompletion(PHANDLE IoCompletionHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    ULONG NumberOfConcurrentThreads);
NTSTATUS NTAPI NtCreateJobObject(PHANDLE JobHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtCreateKey(PHANDLE KeyHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, ULONG TitleIndex,
    PUNICODE_STRING Class, ULONG CreateOptions, PULONG Disposition);
NTSTATUS NTAPI NtCreateMailslotFile(PHANDLE FileHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    PIO_STATUS_BLOCK IoStatusBlock, ULONG CreateOptions, ULONG Unknown,
    ULONG MaxMessageSize, PLARGE_INTEGER ReadTime);
NTSTATUS NTAPI NtCreateMutant(PHANDLE MutantHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, BOOLEAN InitialOwner);
NTSTATUS NTAPI NtCreateNamedPipeFile(PHANDLE FileHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    PIO_STATUS_BLOCK IoStatusBlock, ULONG ShareAccess, ULONG CreateDisposition,
    ULONG CreateOptions, BOOLEAN TypeMessage, BOOLEAN ReadmodeMessage,
    BOOLEAN Nonblocking, ULONG MaxInstances, ULONG InBufferSize,
    ULONG OutBufferSize, PLARGE_INTEGER DefaultTime);
NTSTATUS NTAPI NtCreatePagingFile(PUNICODE_STRING FileName,
    PULARGE_INTEGER InitialSize, PULARGE_INTEGER MaximumSize, ULONG Reserved);
NTSTATUS NTAPI NtCreatePort(PHANDLE PortHandle,
    POBJECT_ATTRIBUTES ObjectAttributes, ULONG MaxDataSize,
    ULONG MaxMessageSize, ULONG Reserved);
NTSTATUS NTAPI NtCreateProcess(PHANDLE ProcessHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, HANDLE InheritFromProcessHandle,
    BOOLEAN InheritHandles, HANDLE SectionHandle, HANDLE DebugPort,
    HANDLE ExceptionPort);
NTSTATUS NTAPI NtCreateProfile(PHANDLE ProfileHandle, HANDLE ProcessHandle,
    PVOID Base, ULONG Size, ULONG BucketShift, PULONG Buffer,
    ULONG BufferLength, KPROFILE_SOURCE Source, ULONG ProcessorMask);
NTSTATUS NTAPI NtCreateSection(PHANDLE SectionHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PLARGE_INTEGER SectionSize,
    ULONG Protect, ULONG Attributes, HANDLE FileHandle);
NTSTATUS NTAPI NtCreateSemaphore(PHANDLE SemaphoreHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    LONG InitialCount, LONG MaximumCount);
NTSTATUS NTAPI NtCreateSymbolicLinkObject(PHANDLE SymbolicLinkHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    PUNICODE_STRING TargetName);
NTSTATUS NTAPI NtCreateThread(PHANDLE ThreadHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, HANDLE ProcessHandle,
    PCLIENT_ID ClientId, PCONTEXT ThreadContext, PUSER_STACK UserStack,
    BOOLEAN CreateSuspended);
NTSTATUS NTAPI NtCreateTimer(PHANDLE TimerHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, TIMER_TYPE TimerType);
NTSTATUS NTAPI NtCreateToken(PHANDLE TokenHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, TOKEN_TYPE Type,
    PLUID AuthenticationId, PLARGE_INTEGER ExpirationTime,
    PTOKEN_USER User, PTOKEN_GROUPS Groups,
    PTOKEN_PRIVILEGES Privileges, PTOKEN_OWNER Owner,
    PTOKEN_PRIMARY_GROUP PrimaryGroup,
    PTOKEN_DEFAULT_DACL DefaultDacl, PTOKEN_SOURCE Source);
NTSTATUS NTAPI NtCreateWaitablePort(PHANDLE PortHandle,
    POBJECT_ATTRIBUTES ObjectAttributes, ULONG MaxDataSize,
    ULONG MaxMessageSize, ULONG Reserved);
NTSTATUS NTAPI NtDelayExecution(BOOLEAN Alertable, PLARGE_INTEGER Interval);
NTSTATUS NTAPI NtDeleteAtom(USHORT Atom);
NTSTATUS NTAPI NtDeleteFile(POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtDeleteKey(HANDLE KeyHandle);
NTSTATUS NTAPI NtDeleteObjectAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, BOOLEAN GenerateOnClose);
NTSTATUS NTAPI NtDeleteValueKey(HANDLE KeyHandle, PUNICODE_STRING ValueName);
NTSTATUS NTAPI NtDeviceIoControlFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, ULONG IoControlCode, PVOID InputBuffer,
    ULONG InputBufferLength, PVOID OutputBuffer, ULONG OutputBufferLength);
NTSTATUS NTAPI NtDisplayString(PUNICODE_STRING String);
NTSTATUS NTAPI NtDuplicateObject(HANDLE SourceProcessHandle,
    HANDLE SourceHandle, HANDLE TargetProcessHandle,
    PHANDLE TargetHandle, ACCESS_MASK DesiredAccess,
    ULONG Attributes, ULONG Options);
NTSTATUS NTAPI NtDuplicateToken(HANDLE ExistingTokenHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    BOOLEAN EffectiveOnly, TOKEN_TYPE TokenType, PHANDLE NewTokenHandle);
NTSTATUS NTAPI NtEnumerateKey(HANDLE KeyHandle, ULONG Index,
    KEY_INFORMATION_CLASS KeyInformationClass, PVOID KeyInformation,
    ULONG KeyInformationLength, PULONG ResultLength);
NTSTATUS NTAPI NtEnumerateValueKey(HANDLE KeyHandle, ULONG Index,
    KEY_VALUE_INFORMATION_CLASS KeyValueInformationClass,
    PVOID KeyValueInformation,
    ULONG KeyValueInformationLength, PULONG ResultLength);
NTSTATUS NTAPI NtExtendSection(HANDLE SectionHandle,
    PLARGE_INTEGER SectionSize);
NTSTATUS NTAPI NtFilterToken(HANDLE ExistingTokenHandle, ULONG Flags,
    PTOKEN_GROUPS SidsToDisable, PTOKEN_PRIVILEGES PrivilegesToDelete,
    PTOKEN_GROUPS SidsToRestricted, PHANDLE NewTokenHandle);
NTSTATUS NTAPI NtFindAtom(PWSTR String, ULONG StringLength, PUSHORT Atom);
NTSTATUS NTAPI NtFlushBuffersFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock);
NTSTATUS NTAPI NtFlushInstructionCache(HANDLE ProcessHandle,
    PCVOID BaseAddress, ULONG FlushSize);
NTSTATUS NTAPI NtFlushKey(HANDLE KeyHandle);
NTSTATUS NTAPI NtFlushVirtualMemory(HANDLE ProcessHandle, PVOID *BaseAddress,
    PULONG FlushSize, PIO_STATUS_BLOCK IoStatusBlock);
NTSTATUS NTAPI NtFlushWriteBuffer(VOID);
NTSTATUS NTAPI NtFreeUserPhysicalPages(HANDLE ProcessHandle,
    PULONG NumberOfPages, PULONG PageFrameNumbers);
NTSTATUS NTAPI NtFreeVirtualMemory(HANDLE ProcessHandle,
    PVOID *BaseAddress, PULONG FreeSize, ULONG FreeType);
NTSTATUS NTAPI NtFsControlFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, ULONG FsControlCode,
    PVOID InputBuffer, ULONG InputBufferLength,
    PVOID OutputBuffer, ULONG OutputBufferLength);
NTSTATUS NTAPI NtGetContextThread(HANDLE ThreadHandle, PCONTEXT Context);
NTSTATUS NTAPI NtGetDevicePowerState(HANDLE DeviceHandle,
    PDEVICE_POWER_STATE DevicePowerState);
NTSTATUS NTAPI NtGetPlugPlayEvent(ULONG Reserved1,
    ULONG Reserved2, PVOID Buffer, ULONG BufferLength);
NTSTATUS NTAPI NtGetTickCount(VOID);
NTSTATUS NTAPI NtGetWriteWatch(HANDLE ProcessHandle, ULONG Flags,
    PVOID BaseAddress, ULONG RegionSize, PVOID *Buffer,
    PULONG BufferEntries, PULONG Granularity);
NTSTATUS NTAPI NtImpersonateAnonymousToken(HANDLE ThreadHandle);
NTSTATUS NTAPI NtImpersonateClientOfPort(HANDLE PortHandle,
    PPORT_MESSAGE Message);
NTSTATUS NTAPI NtImpersonateThread(HANDLE ThreadHandle,
    HANDLE TargetThreadHandle, PSECURITY_QUALITY_OF_SERVICE SecurityQos);
NTSTATUS NTAPI NtInitializeRegistry(BOOLEAN Setup);
NTSTATUS NTAPI NtInitiatePowerAction(POWER_ACTION SystemAction,
    SYSTEM_POWER_STATE MinSystemState, ULONG Flags, BOOLEAN Asynchronous);
NTSTATUS NTAPI NtIsSystemResumeAutomatic(VOID);
NTSTATUS NTAPI NtListenPort(HANDLE PortHandle, PPORT_MESSAGE Message);
NTSTATUS NTAPI NtLoadDriver(PUNICODE_STRING DriverServiceName);
NTSTATUS NTAPI NtLoadKey(POBJECT_ATTRIBUTES KeyObjectAttributes,
    POBJECT_ATTRIBUTES FileObjectAttributes);
NTSTATUS NTAPI NtLoadKey2(POBJECT_ATTRIBUTES KeyObjectAttributes,
    POBJECT_ATTRIBUTES FileObjectAttributes, ULONG Flags);
NTSTATUS NTAPI NtLockFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock,
    PULARGE_INTEGER LockOffset, PULARGE_INTEGER LockLength,
    ULONG Key, BOOLEAN FailImmediately, BOOLEAN ExclusiveLock);
NTSTATUS NTAPI NtLockVirtualMemory(HANDLE ProcessHandle,
    PVOID *BaseAddress, PULONG LockSize, ULONG LockType);
NTSTATUS NTAPI NtMakeTemporaryObject(HANDLE Handle);
NTSTATUS NTAPI NtMapUserPhysicalPages(PVOID BaseAddress,
    ULONG_PTR NumberOfPages, PULONG_PTR PageFrameNumbers);
NTSTATUS NTAPI NtMapUserPhysicalPagesScatter(PVOID *BaseAddresses,
    ULONG_PTR NumberOfPages, PULONG_PTR PageFrameNumbers);
NTSTATUS NTAPI NtMapViewOfSection(HANDLE SectionHandle,
    HANDLE ProcessHandle, PVOID *BaseAddress, ULONG ZeroBits,
    ULONG CommitSize, PLARGE_INTEGER SectionOffset,
    PULONG ViewSize, SECTION_INHERIT InheritDisposition,
    ULONG AllocationType, ULONG Protect);
NTSTATUS NTAPI NtNotifyChangeDirectoryFile(HANDLE FileHandle,
    HANDLE Event, PIO_APC_ROUTINE ApcRoutine,
    PVOID ApcContext, PIO_STATUS_BLOCK IoStatusBlock,
    PFILE_NOTIFY_INFORMATION Buffer, ULONG BufferLength,
    ULONG NotifyFilter, BOOLEAN WatchSubtree);
NTSTATUS NTAPI NtNotifyChangeKey(HANDLE KeyHandle,
    HANDLE EventHandle, PIO_APC_ROUTINE ApcRoutine,
    PVOID ApcContext, PIO_STATUS_BLOCK IoStatusBlock,
    ULONG NotifyFilter, BOOLEAN WatchSubtree, PVOID Buffer,
    ULONG BufferLength, BOOLEAN Asynchronous);
NTSTATUS NTAPI NtNotifyChangeMultipleKeys(HANDLE KeyHandle,
    ULONG Flags, POBJECT_ATTRIBUTES KeyObjectAttributes,
    HANDLE EventHandle, PIO_APC_ROUTINE ApcRoutine,
    PVOID ApcContext, PIO_STATUS_BLOCK IoStatusBlock,
    ULONG NotifyFilter, BOOLEAN WatchSubtree, PVOID Buffer,
    ULONG BufferLength, BOOLEAN Asynchronous);
NTSTATUS NTAPI NtOpenDirectoryObject(PHANDLE DirectoryHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenEvent(PHANDLE EventHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenEventPair(PHANDLE EventPairHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenFile(PHANDLE FileHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PIO_STATUS_BLOCK IoStatusBlock,
    ULONG ShareAccess, ULONG OpenOptions);
NTSTATUS NTAPI NtOpenIoCompletion(PHANDLE IoCompletionHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenJobObject(PHANDLE JobHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenKey(PHANDLE KeyHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenMutant(PHANDLE MutantHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenObjectAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID *HandleId, PUNICODE_STRING ObjectTypeName, PUNICODE_STRING ObjectName,
    PSECURITY_DESCRIPTOR SecurityDescriptor, HANDLE TokenHandle,
    ACCESS_MASK DesiredAccess, ACCESS_MASK GrantedAccess,
    PPRIVILEGE_SET Privileges, BOOLEAN ObjectCreation, BOOLEAN AccessGranted,
    PBOOLEAN GenerateOnClose);
NTSTATUS NTAPI NtOpenProcess(PHANDLE ProcessHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PCLIENT_ID ClientId);
NTSTATUS NTAPI NtOpenProcessToken(HANDLE ProcessHandle,
    ACCESS_MASK DesiredAccess, PHANDLE TokenHandle);
NTSTATUS NTAPI NtOpenSection(PHANDLE SectionHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenSemaphore(PHANDLE SemaphoreHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenSymbolicLinkObject(PHANDLE SymbolicLinkHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtOpenThread(PHANDLE ThreadHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PCLIENT_ID ClientId);
NTSTATUS NTAPI NtOpenThreadToken(HANDLE ThreadHandle, ACCESS_MASK DesiredAccess,
    BOOLEAN OpenAsSelf, PHANDLE TokenHandle);
NTSTATUS NTAPI NtOpenTimer(PHANDLE TimerHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI NtPowerInformation(POWER_INFORMATION_LEVEL PowerInformationLevel,
    PVOID InputBuffer, ULONG InputBufferLength,
    PVOID OutputBuffer, ULONG OutputBufferLength);
NTSTATUS NTAPI NtPrivilegeCheck(HANDLE TokenHandle,
    PPRIVILEGE_SET RequiredPrivileges, PBOOLEAN Result);
NTSTATUS NTAPI NtPrivilegedServiceAuditAlarm(PUNICODE_STRING SubsystemName,
    PUNICODE_STRING ServiceName, HANDLE TokenHandle,
    PPRIVILEGE_SET Privileges, BOOLEAN AccessGranted);
NTSTATUS NTAPI NtPrivilegeObjectAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, HANDLE TokenHandle, ACCESS_MASK DesiredAccess,
    PPRIVILEGE_SET Privileges, BOOLEAN AccessGranted);
NTSTATUS NTAPI NtProtectVirtualMemory(HANDLE ProcessHandle, PVOID *BaseAddress,
    PULONG ProtectSize, ULONG NewProtect, PULONG OldProtect);
NTSTATUS NTAPI NtPulseEvent(HANDLE EventHandle, PULONG PreviousState);
NTSTATUS NTAPI NtQueryInformationAtom(USHORT Atom,
    ATOM_INFORMATION_CLASS AtomInformationClass,
    PVOID AtomInformation, ULONG AtomInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI NtQueryAttributesFile(POBJECT_ATTRIBUTES ObjectAttributes,
    PFILE_BASIC_INFORMATION FileInformation);
NTSTATUS NTAPI NtQueryDefaultLocale(BOOLEAN ThreadOrSystem, PLCID Locale);
NTSTATUS NTAPI NtQueryDefaultUILanguage(PLANGID LanguageId);
NTSTATUS NTAPI NtQueryDirectoryFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID FileInformation,
    ULONG FileInformationLength, FILE_INFORMATION_CLASS FileInformationClass,
    BOOLEAN ReturnSingleEntry, PUNICODE_STRING FileName,
    BOOLEAN RestartScan);
NTSTATUS NTAPI NtQueryDirectoryObject(HANDLE DirectoryHandle, PVOID Buffer,
    ULONG BufferLength, BOOLEAN ReturnSingleEntry, BOOLEAN RestartScan,
    PULONG Context, PULONG ReturnLength);
NTSTATUS NTAPI NtQueryEaFile(HANDLE FileHandle, PIO_STATUS_BLOCK IoStatusBlock,
    PFILE_FULL_EA_INFORMATION Buffer, ULONG BufferLength,
    BOOLEAN ReturnSingleEntry,
    PFILE_GET_EA_INFORMATION EaList, ULONG EaListLength,
    PULONG EaIndex, BOOLEAN RestartScan);
NTSTATUS NTAPI NtQueryEvent(HANDLE EventHandle,
    EVENT_INFORMATION_CLASS EventInformationClass, PVOID EventInformation,
    ULONG EventInformationLength, PULONG ResultLength);
NTSTATUS NTAPI NtQueryFullAttributesFile(POBJECT_ATTRIBUTES ObjectAttributes,
    PFILE_NETWORK_OPEN_INFORMATION FileInformation);
NTSTATUS NTAPI NtQueryInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID FileInformation,
    ULONG FileInformationLength, FILE_INFORMATION_CLASS FileInformationClass);
NTSTATUS NTAPI NtQueryInformationJobObject(HANDLE JobHandle,
    JOBOBJECTINFOCLASS JobInformationClass, PVOID JobInformation,
    ULONG JobInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI NtQueryIoCompletion(HANDLE IoCompletionHandle,
    IO_COMPLETION_INFORMATION_CLASS IoCompletionInformationClass,
    PVOID IoCompletionInformation, ULONG IoCompletionInformationLength,
    PULONG ResultLength);
NTSTATUS NTAPI NtQueryInformationPort(HANDLE PortHandle,
    PORT_INFORMATION_CLASS PortInformationClass, PVOID PortInformation,
    ULONG PortInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI NtQueryInformationProcess(HANDLE ProcessHandle,
    PROCESSINFOCLASS ProcessInformationClass, PVOID ProcessInformation,
    ULONG ProcessInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI NtQueryInformationThread(HANDLE ThreadHandle,
    THREADINFOCLASS ThreadInformationClass, PVOID ThreadInformation,
    ULONG ThreadInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI NtQueryInformationToken(HANDLE TokenHandle,
    TOKEN_INFORMATION_CLASS TokenInformationClass, PVOID TokenInformation,
    ULONG TokenInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI NtQueryInstallUILanguage(PLANGID LanguageId);
NTSTATUS NTAPI NtQueryIntervalProfile(KPROFILE_SOURCE Source, PULONG Interval);
NTSTATUS NTAPI NtQueryKey(HANDLE KeyHandle,
    KEY_INFORMATION_CLASS KeyInformationClass, PVOID KeyInformation,
    ULONG KeyInformationLength, PULONG ResultLength);
NTSTATUS NTAPI NtQueryMultipleValueKey(HANDLE KeyHandle,
    PKEY_VALUE_ENTRY ValueList, ULONG NumberOfValues,
    PVOID Buffer, PULONG Length, PULONG ReturnLength);
NTSTATUS NTAPI NtQueryMutant(HANDLE MutantHandle,
    MUTANT_INFORMATION_CLASS MutantInformationClass,
    PVOID MutantInformation, ULONG MutantInformationLength,
    PULONG ResultLength);
NTSTATUS NTAPI NtQueryObject(HANDLE ObjectHandle,
    OBJECT_INFORMATION_CLASS ObjectInformationClass,
    PVOID ObjectInformation, ULONG ObjectInformationLength,
    PULONG ReturnLength);
NTSTATUS NTAPI NtQueryOpenSubKeys(POBJECT_ATTRIBUTES KeyObjectAttributes,
    PULONG NumberOfKeys);
NTSTATUS NTAPI NtQueryPerformanceCounter(PLARGE_INTEGER PerformanceCount,
    PLARGE_INTEGER PerformanceFrequency);
NTSTATUS NTAPI NtQueryQuotaInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PFILE_USER_QUOTA_INFORMATION Buffer,
    ULONG BufferLength, BOOLEAN ReturnSingleEntry,
    PFILE_QUOTA_LIST_INFORMATION QuotaList, ULONG QuotaListLength,
    PSID ResumeSid, BOOLEAN RestartScan);
NTSTATUS NTAPI NtQuerySection(HANDLE SectionHandle,
    SECTION_INFORMATION_CLASS SectionInformationClass,
    PVOID SectionInformation, ULONG SectionInformationLength,
    PULONG ResultLength);
NTSTATUS NTAPI NtQuerySecurityObject(HANDLE Handle,
    SECURITY_INFORMATION RequestedInformation,
    PSECURITY_DESCRIPTOR SecurityDescriptor,
    ULONG SecurityDescriptorLength, PULONG ReturnLength);
NTSTATUS NTAPI NtQuerySemaphore(HANDLE SemaphoreHandle,
    SEMAPHORE_INFORMATION_CLASS SemaphoreInformationClass,
    PVOID SemaphoreInformation,
    ULONG SemaphoreInformationLength, PULONG ResultLength);
NTSTATUS NTAPI NtQuerySymbolicLinkObject(HANDLE SymbolicLinkHandle,
    PUNICODE_STRING TargetName, PULONG ReturnLength);
NTSTATUS NTAPI NtQuerySystemEnvironmentValue(
    PUNICODE_STRING Name, PVOID Value, ULONG ValueLength,
    PULONG ReturnLength);
NTSTATUS NTAPI NtQuerySystemInformation(
    SYSTEM_INFORMATION_CLASS SystemInformationClass,
    PVOID SystemInformation, ULONG SystemInformationLength,
    PULONG ReturnLength);
NTSTATUS NTAPI NtQuerySystemTime(PLARGE_INTEGER CurrentTime);
NTSTATUS NTAPI NtQueryTimer(HANDLE TimerHandle,
    TIMER_INFORMATION_CLASS TimerInformationClass,
    PVOID TimerInformation, ULONG TimerInformationLength,
    PULONG ResultLength);
NTSTATUS NTAPI NtQueryTimerResolution(PULONG CoarsestResolution,
    PULONG FinestResolution, PULONG ActualResolution);
NTSTATUS NTAPI NtQueryValueKey(HANDLE KeyHandle, PUNICODE_STRING ValueName,
    KEY_VALUE_INFORMATION_CLASS KeyValueInformationClass,
    PVOID KeyValueInformation,
    ULONG KeyValueInformationLength, PULONG ResultLength);
NTSTATUS NTAPI NtQueryVirtualMemory(HANDLE ProcessHandle, PVOID BaseAddress,
    MEMORY_INFORMATION_CLASS MemoryInformationClass,
    PVOID MemoryInformation, ULONG MemoryInformationLength,
    PULONG ReturnLength);
NTSTATUS NTAPI NtQueryVolumeInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID VolumeInformation,
    ULONG VolumeInformationLength,
    FS_INFORMATION_CLASS VolumeInformationClass);
NTSTATUS NTAPI NtQueueApcThread(HANDLE ThreadHandle,
    PKNORMAL_ROUTINE ApcRoutine, PVOID ApcContext, PVOID Argument1,
    PVOID Argument2);
NTSTATUS NTAPI NtRaiseException(PEXCEPTION_RECORD ExceptionRecord,
    PCONTEXT Context, BOOLEAN SearchFrames);
NTSTATUS NTAPI NtRaiseHardError(NTSTATUS Status, ULONG NumberOfArguments,
    ULONG StringArgumentsMask, PULONG Arguments,
    HARDERROR_RESPONSE_OPTION ResponseOption, PHARDERROR_RESPONSE Response);
NTSTATUS NTAPI NtReadFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID Buffer,
    ULONG Length, PLARGE_INTEGER ByteOffset, PULONG Key);
NTSTATUS NTAPI NtReadFileScatter(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PFILE_SEGMENT_ELEMENT Buffer,
    ULONG Length, PLARGE_INTEGER ByteOffset, PULONG Key);
NTSTATUS NTAPI NtReadRequestData(HANDLE PortHandle, PPORT_MESSAGE Message,
    ULONG Index, PVOID Buffer, ULONG BufferLength, PULONG ReturnLength);
NTSTATUS NTAPI NtReadVirtualMemory(HANDLE ProcessHandle, PCVOID BaseAddress,
    PVOID Buffer, ULONG BufferLength, PULONG ReturnLength);
NTSTATUS NTAPI NtRegisterThreadTerminatePort(HANDLE PortHandle);
NTSTATUS NTAPI NtReleaseMutant(HANDLE MutantHandle, PULONG PreviousState);
NTSTATUS NTAPI NtReleaseSemaphore(HANDLE SemaphoreHandle,
    LONG ReleaseCount, PLONG PreviousCount);
NTSTATUS NTAPI NtRemoveIoCompletion(HANDLE IoCompletionHandle,
    PULONG CompletionKey, PULONG CompletionValue,
    PIO_STATUS_BLOCK IoStatusBlock, PLARGE_INTEGER Time);
NTSTATUS NTAPI NtReplaceKey(POBJECT_ATTRIBUTES NewFileObjectAttributes,
    HANDLE KeyHandle, POBJECT_ATTRIBUTES OldFileObjectAttributes);
NTSTATUS NTAPI NtReplyPort(HANDLE PortHandle, PPORT_MESSAGE ReplyMessage);
NTSTATUS NTAPI NtReplyWaitReceivePort(HANDLE PortHandle, PULONG PortIdentifier,
    PPORT_MESSAGE ReplyMessage, PPORT_MESSAGE Message);
NTSTATUS NTAPI NtReplyWaitReceivePortEx(HANDLE PortHandle,
    PULONG PortIdentifier, PPORT_MESSAGE ReplyMessage, PPORT_MESSAGE Message,
    PLARGE_INTEGER Timeout);
NTSTATUS NTAPI NtReplyWaitReplyPort(HANDLE PortHandle,
    PPORT_MESSAGE ReplyMessage);
NTSTATUS NTAPI NtRequestDeviceWakeup(HANDLE DeviceHandle);
NTSTATUS NTAPI NtRequestPort(HANDLE PortHandle, PPORT_MESSAGE RequestMessage);
NTSTATUS NTAPI NtRequestWaitReplyPort(HANDLE PortHandle,
    PPORT_MESSAGE RequestMessage, PPORT_MESSAGE ReplyMessage);
NTSTATUS NTAPI NtRequestWakeupLatency(LATENCY_TIME Latency);
NTSTATUS NTAPI NtResetEvent(HANDLE EventHandle, PULONG PreviousState);
NTSTATUS NTAPI NtResetWriteWatch(HANDLE ProcessHandle,
    PVOID BaseAddress, ULONG RegionSize);
NTSTATUS NTAPI NtRestoreKey(HANDLE KeyHandle, HANDLE FileHandle, ULONG Flags);
NTSTATUS NTAPI NtResumeThread(HANDLE ThreadHandle, PULONG PreviousSuspendCount);
NTSTATUS NTAPI NtSaveKey(HANDLE KeyHandle, HANDLE FileHandle);
NTSTATUS NTAPI NtSaveMergedKeys(HANDLE KeyHandle1,
    HANDLE KeyHandle2, HANDLE FileHandle);
NTSTATUS NTAPI NtSecureConnectPort(PHANDLE PortHandle, PUNICODE_STRING PortName,
    PSECURITY_QUALITY_OF_SERVICE SecurityQos,
    PPORT_SECTION_WRITE WriteSection, PSID ServerSid,
    PPORT_SECTION_READ ReadSection, PULONG MaxMessageSize,
    PVOID ConnectData, PULONG ConnectDataLength);
NTSTATUS NTAPI NtSetIoCompletion(HANDLE IoCompletionHandle, ULONG CompletionKey,
    ULONG CompletionValue, NTSTATUS Status, ULONG Information);
NTSTATUS NTAPI NtSetContextThread(HANDLE ThreadHandle, const CONTEXT *Context);
NTSTATUS NTAPI NtSetDefaultHardErrorPort(HANDLE PortHandle);
NTSTATUS NTAPI NtSetDefaultLocale(BOOLEAN ThreadOrSystem, LCID Locale);
NTSTATUS NTAPI NtSetDefaultUILanguage(LANGID LanguageId);
NTSTATUS NTAPI NtSetEaFile(HANDLE FileHandle, PIO_STATUS_BLOCK IoStatusBlock,
    PFILE_FULL_EA_INFORMATION Buffer, ULONG BufferLength);
NTSTATUS NTAPI NtSetEvent(HANDLE EventHandle, PULONG PreviousState);
NTSTATUS NTAPI NtSetHighEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI NtSetHighWaitLowEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI NtSetInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock,
    PVOID FileInformation, ULONG FileInformationLength,
    FILE_INFORMATION_CLASS FileInformationClass);
NTSTATUS NTAPI NtSetInformationJobObject(HANDLE JobHandle,
    JOBOBJECTINFOCLASS JobInformationClass,
    PVOID JobInformation, ULONG JobInformationLength);
NTSTATUS NTAPI NtSetInformationKey(HANDLE KeyHandle,
    KEY_SET_INFORMATION_CLASS KeyInformationClass,
    PVOID KeyInformation, ULONG KeyInformationLength);
NTSTATUS NTAPI NtSetInformationObject(HANDLE ObjectHandle,
    OBJECT_INFORMATION_CLASS ObjectInformationClass,
    PVOID ObjectInformation, ULONG ObjectInformationLength);
NTSTATUS NTAPI NtSetInformationProcess(HANDLE ProcessHandle,
    PROCESSINFOCLASS ProcessInformationClass, PVOID ProcessInformation,
    ULONG ProcessInformationLength);
NTSTATUS NTAPI NtSetInformationThread(HANDLE ThreadHandle,
    THREADINFOCLASS ThreadInformationClass,
    PVOID ThreadInformation, ULONG ThreadInformationLength);
NTSTATUS NTAPI NtSetInformationToken(HANDLE TokenHandle,
    TOKEN_INFORMATION_CLASS TokenInformationClass,
    PVOID TokenInformation, ULONG TokenInformationLength);
NTSTATUS NTAPI NtSetIntervalProfile(ULONG Interval, KPROFILE_SOURCE Source);
NTSTATUS NTAPI NtSetLdtEntries(ULONG Selector1, LDT_ENTRY LdtEntry1,
    ULONG Selector2, LDT_ENTRY LdtEntry2);
NTSTATUS NTAPI NtSetLowEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI NtSetLowWaitHighEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI NtSetQuotaInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PFILE_USER_QUOTA_INFORMATION Buffer,
    ULONG BufferLength);
NTSTATUS NTAPI NtSetSecurityObject(HANDLE Handle,
    SECURITY_INFORMATION SecurityInformation,
    PSECURITY_DESCRIPTOR SecurityDescriptor);
NTSTATUS NTAPI NtSetSystemEnvironmentValue(PUNICODE_STRING Name,
    PUNICODE_STRING Value);
NTSTATUS NTAPI NtSetSystemInformation(
    SYSTEM_INFORMATION_CLASS SystemInformationClass,
    PVOID SystemInformation, ULONG SystemInformationLength);
NTSTATUS NTAPI NtSetSystemPowerState(POWER_ACTION SystemAction,
    SYSTEM_POWER_STATE MinSystemState, ULONG Flags);
NTSTATUS NTAPI NtSetSystemTime(PLARGE_INTEGER NewTime, PLARGE_INTEGER OldTime);
NTSTATUS NTAPI NtSetThreadExecutionState(EXECUTION_STATE ExecutionState,
    PEXECUTION_STATE PreviousExecutionState);
NTSTATUS NTAPI NtSetTimer(HANDLE TimerHandle, const LARGE_INTEGER *DueTime,
    PTIMERAPCROUTINE TimerApcRoutine, PVOID TimerContext,
    BOOLEAN Resume, LONG Period, PBOOLEAN PreviousState);
NTSTATUS NTAPI NtSetTimerResolution(ULONG RequestedResolution,
    BOOLEAN Set, PULONG ActualResolution);
NTSTATUS NTAPI NtSetUuidSeed(PUCHAR UuidSeed);
NTSTATUS NTAPI NtSetValueKey(HANDLE KeyHandle, PUNICODE_STRING ValueName,
    ULONG TitleIndex, ULONG Type, PVOID Data, ULONG DataSize);
NTSTATUS NTAPI NtSetVolumeInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID Buffer, ULONG BufferLength,
    FS_INFORMATION_CLASS VolumeInformationClass);
NTSTATUS NTAPI NtShutdownSystem(SHUTDOWN_ACTION Action);
NTSTATUS NTAPI NtSignalAndWaitForSingleObject(HANDLE HandleToSignal,
    HANDLE HandleToWait, BOOLEAN Alertable, PLARGE_INTEGER Time);
NTSTATUS NTAPI NtStartProfile(HANDLE ProfileHandle);
NTSTATUS NTAPI NtStopProfile(HANDLE ProfileHandle);
NTSTATUS NTAPI NtSuspendThread(HANDLE ThreadHandle,
    PULONG PreviousSuspendCount);
NTSTATUS NTAPI NtSystemDebugControl(DEBUG_CONTROL_CODE ControlCode,
    PVOID InputBuffer, ULONG InputBufferLength, PVOID OutputBuffer,
    ULONG OutputBufferLength, PULONG ReturnLength);
NTSTATUS NTAPI NtTerminateJobObject(HANDLE JobHandle, NTSTATUS ExitStatus);
NTSTATUS NTAPI NtTerminateProcess(HANDLE ProcessHandle, NTSTATUS ExitStatus);
NTSTATUS NTAPI NtTerminateThread(HANDLE ThreadHandle, NTSTATUS ExitStatus);
NTSTATUS NTAPI NtTestAlert(VOID);
NTSTATUS NTAPI NtUnloadDriver(PUNICODE_STRING DriverServiceName);
NTSTATUS NTAPI NtUnloadKey(POBJECT_ATTRIBUTES KeyObjectAttributes);
NTSTATUS NTAPI NtUnlockFile(HANDLE FileHandle, PIO_STATUS_BLOCK IoStatusBlock,
    PULARGE_INTEGER LockOffset, PULARGE_INTEGER LockLength, ULONG Key);
NTSTATUS NTAPI NtUnlockVirtualMemory(HANDLE ProcessHandle,
    PVOID *BaseAddress, PULONG LockSize, ULONG LockType);
NTSTATUS NTAPI NtUnmapViewOfSection(HANDLE ProcessHandle, PVOID BaseAddress);
NTSTATUS NTAPI NtVdmControl(ULONG ControlCode, PVOID ControlData);
NTSTATUS NTAPI NtWaitForMultipleObjects(ULONG HandleCount, PHANDLE Handles,
    WAIT_TYPE WaitType, BOOLEAN Alertable, PLARGE_INTEGER Time);
NTSTATUS NTAPI NtWaitForSingleObject(HANDLE Handle,
    BOOLEAN Alertable, PLARGE_INTEGER Time);
NTSTATUS NTAPI NtWaitHighEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI NtWaitLowEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI NtWriteFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID Buffer, ULONG Length,
    PLARGE_INTEGER ByteOffset, PULONG Key);
NTSTATUS NTAPI NtWriteFileGather(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PFILE_SEGMENT_ELEMENT Buffer,
    ULONG Length, PLARGE_INTEGER ByteOffset, PULONG Key);
NTSTATUS NTAPI NtWriteRequestData(HANDLE PortHandle,
    PPORT_MESSAGE Message, ULONG Index, PVOID Buffer,
    ULONG BufferLength, PULONG ReturnLength);
NTSTATUS NTAPI NtWriteVirtualMemory(HANDLE ProcessHandle, PVOID BaseAddress,
    PVOID Buffer, ULONG BufferLength, PULONG ReturnLength);
NTSTATUS NTAPI NtYieldExecution(VOID);
NTSTATUS NTAPI NtNoSyscall(VOID);

/*
 * Win32 Native APIs prefixed with Zw.
 */

NTSTATUS NTAPI ZwAcceptConnectPort(PHANDLE PortHandle, ULONG PortIdentifier,
    PPORT_MESSAGE Message, BOOLEAN Accept, PPORT_SECTION_WRITE WriteSection,
    PPORT_SECTION_READ ReadSection);
NTSTATUS NTAPI ZwAccessCheck(PSECURITY_DESCRIPTOR SecurityDescriptor,
    HANDLE TokenHandle, ACCESS_MASK DesiredAccess,
    PGENERIC_MAPPING GenericMapping,
    PPRIVILEGE_SET PrivilegeSet, PULONG PrivilegeSetLength,
    PACCESS_MASK GrantedAccess, PBOOLEAN AccessStatus);
NTSTATUS NTAPI ZwAccessCheckAndAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, PUNICODE_STRING ObjectTypeName,
    PUNICODE_STRING ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor,
    ACCESS_MASK DesiredAccess, PGENERIC_MAPPING GenericMapping,
    BOOLEAN ObjectCreation, PACCESS_MASK GrantedAccess,
    PBOOLEAN AccessStatus, PBOOLEAN GenerateOnClose);
NTSTATUS NTAPI ZwAccessCheckByType(PSECURITY_DESCRIPTOR SecurityDescriptor,
    PSID PrincipalSelfSid, HANDLE TokenHandle,
    ULONG DesiredAccess, POBJECT_TYPE_LIST ObjectTypeList,
    ULONG ObjectTypeListLength, PGENERIC_MAPPING GenericMapping,
    PPRIVILEGE_SET PrivilegeSet, PULONG PrivilegeSetLength,
    PACCESS_MASK GrantedAccess, PULONG AccessStatus);
NTSTATUS NTAPI ZwAccessCheckByTypeAndAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, PUNICODE_STRING ObjectTypeName, PUNICODE_STRING ObjectName,
    PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid,
    ACCESS_MASK DesiredAccess, AUDIT_EVENT_TYPE AuditType, ULONG Flags,
    POBJECT_TYPE_LIST ObjectTypeList, ULONG ObjectTypeListLength,
    PGENERIC_MAPPING GenericMapping, BOOLEAN ObjectCreation,
    PACCESS_MASK GrantedAccess, PULONG AccessStatus, PBOOLEAN GenerateOnClose);
NTSTATUS NTAPI ZwAccessCheckByTypeResultList(
    PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid,
    HANDLE TokenHandle, ACCESS_MASK DesiredAccess,
    POBJECT_TYPE_LIST ObjectTypeList, ULONG ObjectTypeListLength,
    PGENERIC_MAPPING GenericMapping,
    PPRIVILEGE_SET PrivilegeSet, PULONG PrivilegeSetLength,
    PACCESS_MASK GrantedAccessList, PULONG AccessStatusList);
NTSTATUS NTAPI ZwAccessCheckByTypeResultListAndAuditAlarm(
    PUNICODE_STRING SubsystemName, PVOID HandleId,
    PUNICODE_STRING ObjectTypeName, PUNICODE_STRING ObjectName,
    PSECURITY_DESCRIPTOR SecurityDescriptor, PSID PrincipalSelfSid,
    ACCESS_MASK DesiredAccess, AUDIT_EVENT_TYPE AuditType, ULONG Flags,
    POBJECT_TYPE_LIST ObjectTypeList, ULONG ObjectTypeListLength,
    PGENERIC_MAPPING GenericMapping, BOOLEAN ObjectCreation,
    PACCESS_MASK GrantedAccessList, PULONG AccessStatusList,
    PULONG GenerateOnClose);
NTSTATUS NTAPI ZwAccessCheckByTypeResultListAndAuditAlarmByHandle(
    PUNICODE_STRING SubsystemName, PVOID HandleId,
    HANDLE TokenHandle, PUNICODE_STRING ObjectTypeName,
    PUNICODE_STRING ObjectName, PSECURITY_DESCRIPTOR SecurityDescriptor,
    PSID PrincipalSelfSid, ACCESS_MASK DesiredAccess,
    AUDIT_EVENT_TYPE AuditType, ULONG Flags, POBJECT_TYPE_LIST ObjectTypeList,
    ULONG ObjectTypeListLength, PGENERIC_MAPPING GenericMapping,
    BOOLEAN ObjectCreation, PACCESS_MASK GrantedAccessList,
    PULONG AccessStatusList, PULONG GenerateOnClose);
NTSTATUS NTAPI ZwAddAtom(PWSTR String, ULONG StringLength, PUSHORT Atom);
NTSTATUS NTAPI ZwAdjustGroupsToken(HANDLE TokenHandle, BOOLEAN ResetToDefault,
    PTOKEN_GROUPS NewState, ULONG BufferLength, PTOKEN_GROUPS PreviousState,
    PULONG ReturnLength);
NTSTATUS NTAPI ZwAdjustPrivilegesToken(HANDLE TokenHandle,
    BOOLEAN DisableAllPrivileges, PTOKEN_PRIVILEGES NewState,
    ULONG BufferLength, PTOKEN_PRIVILEGES PreviousState, PULONG ReturnLength);
NTSTATUS NTAPI ZwAlertResumeThread(HANDLE ThreadHandle,
    PULONG PreviousSuspendCount);
NTSTATUS NTAPI ZwAlertThread(HANDLE ThreadHandle);
NTSTATUS NTAPI ZwAllocateLocallyUniqueId(PLUID Luid);
NTSTATUS NTAPI ZwAllocateUserPhysicalPages(HANDLE ProcessHandle,
    PULONG NumberOfPages, PULONG PageFrameNumbers);
NTSTATUS NTAPI ZwAllocateUuids(PLARGE_INTEGER UuidLastTimeAllocated,
    PULONG UuidDeltaTime, PULONG UuidSequenceNumber, PUCHAR UuidSeed);
NTSTATUS NTAPI ZwAllocateVirtualMemory(HANDLE ProcessHandle, PVOID *BaseAddress,
    ULONG ZeroBits, PULONG AllocationSize, ULONG AllocationType, ULONG Protect);
NTSTATUS NTAPI ZwAreMappedFilesTheSame(PVOID Address1, PVOID Address2);
NTSTATUS NTAPI ZwAssignProcessToJobObject(HANDLE JobHandle,
    HANDLE ProcessHandle);
NTSTATUS NTAPI ZwCallbackReturn(PVOID Result, ULONG ResultLength,
    NTSTATUS Status);
NTSTATUS NTAPI ZwCancelIoFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock);
NTSTATUS NTAPI ZwCancelTimer(HANDLE TimerHandle, PBOOLEAN PreviousState);
NTSTATUS NTAPI ZwCancelDeviceWakeupRequest(HANDLE DeviceHandle);
NTSTATUS NTAPI ZwClearEvent(HANDLE EventHandle);
NTSTATUS NTAPI ZwClose(HANDLE Handle);
NTSTATUS NTAPI ZwCloseObjectAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, BOOLEAN GenerateOnClose);
NTSTATUS NTAPI ZwCompleteConnectPort(HANDLE PortHandle);
NTSTATUS NTAPI ZwConnectPort(PHANDLE PortHandle, PUNICODE_STRING PortName,
    PSECURITY_QUALITY_OF_SERVICE SecurityQos,
    PPORT_SECTION_WRITE WriteSection,
    PPORT_SECTION_READ ReadSection, PULONG MaxMessageSize,
    PVOID ConnectData, PULONG ConnectDataLength);
NTSTATUS NTAPI ZwContinue(PCONTEXT Context, BOOLEAN TestAlert);
NTSTATUS NTAPI ZwCreateDirectoryObject(PHANDLE DirectoryHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwCreateEvent(PHANDLE EventHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes,
    EVENT_TYPE EventType, BOOLEAN InitialState);
NTSTATUS NTAPI ZwCreateEventPair(PHANDLE EventPairHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwCreateFile(PHANDLE FileHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PIO_STATUS_BLOCK IoStatusBlock,
    PLARGE_INTEGER AllocationSize, ULONG FileAttributes,
    ULONG ShareAccess, ULONG CreateDisposition,
    ULONG CreateOptions, PVOID EaBuffer, ULONG EaLength);
NTSTATUS NTAPI ZwCreateIoCompletion(PHANDLE IoCompletionHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    ULONG NumberOfConcurrentThreads);
NTSTATUS NTAPI ZwCreateJobObject(PHANDLE JobHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwCreateKey(PHANDLE KeyHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, ULONG TitleIndex,
    PUNICODE_STRING Class, ULONG CreateOptions, PULONG Disposition);
NTSTATUS NTAPI ZwCreateMailslotFile(PHANDLE FileHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    PIO_STATUS_BLOCK IoStatusBlock, ULONG CreateOptions, ULONG Unknown,
    ULONG MaxMessageSize, PLARGE_INTEGER ReadTime);
NTSTATUS NTAPI ZwCreateMutant(PHANDLE MutantHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, BOOLEAN InitialOwner);
NTSTATUS NTAPI ZwCreateNamedPipeFile(PHANDLE FileHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    PIO_STATUS_BLOCK IoStatusBlock, ULONG ShareAccess, ULONG CreateDisposition,
    ULONG CreateOptions, BOOLEAN TypeMessage, BOOLEAN ReadmodeMessage,
    BOOLEAN Nonblocking, ULONG MaxInstances, ULONG InBufferSize,
    ULONG OutBufferSize, PLARGE_INTEGER DefaultTime);
NTSTATUS NTAPI ZwCreatePagingFile(PUNICODE_STRING FileName,
    PULARGE_INTEGER InitialSize, PULARGE_INTEGER MaximumSize, ULONG Reserved);
NTSTATUS NTAPI ZwCreatePort(PHANDLE PortHandle,
    POBJECT_ATTRIBUTES ObjectAttributes, ULONG MaxDataSize,
    ULONG MaxMessageSize, ULONG Reserved);
NTSTATUS NTAPI ZwCreateProcess(PHANDLE ProcessHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, HANDLE InheritFromProcessHandle,
    BOOLEAN InheritHandles, HANDLE SectionHandle, HANDLE DebugPort,
    HANDLE ExceptionPort);
NTSTATUS NTAPI ZwCreateProfile(PHANDLE ProfileHandle, HANDLE ProcessHandle,
    PVOID Base, ULONG Size, ULONG BucketShift, PULONG Buffer,
    ULONG BufferLength, KPROFILE_SOURCE Source, ULONG ProcessorMask);
NTSTATUS NTAPI ZwCreateSection(PHANDLE SectionHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PLARGE_INTEGER SectionSize,
    ULONG Protect, ULONG Attributes, HANDLE FileHandle);
NTSTATUS NTAPI ZwCreateSemaphore(PHANDLE SemaphoreHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    LONG InitialCount, LONG MaximumCount);
NTSTATUS NTAPI ZwCreateSymbolicLinkObject(PHANDLE SymbolicLinkHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    PUNICODE_STRING TargetName);
NTSTATUS NTAPI ZwCreateThread(PHANDLE ThreadHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, HANDLE ProcessHandle,
    PCLIENT_ID ClientId, PCONTEXT ThreadContext, PUSER_STACK UserStack,
    BOOLEAN CreateSuspended);
NTSTATUS NTAPI ZwCreateTimer(PHANDLE TimerHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, TIMER_TYPE TimerType);
NTSTATUS NTAPI ZwCreateToken(PHANDLE TokenHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, TOKEN_TYPE Type,
    PLUID AuthenticationId, PLARGE_INTEGER ExpirationTime,
    PTOKEN_USER User, PTOKEN_GROUPS Groups,
    PTOKEN_PRIVILEGES Privileges, PTOKEN_OWNER Owner,
    PTOKEN_PRIMARY_GROUP PrimaryGroup,
    PTOKEN_DEFAULT_DACL DefaultDacl, PTOKEN_SOURCE Source);
NTSTATUS NTAPI ZwCreateWaitablePort(PHANDLE PortHandle,
    POBJECT_ATTRIBUTES ObjectAttributes, ULONG MaxDataSize,
    ULONG MaxMessageSize, ULONG Reserved);
NTSTATUS NTAPI ZwDelayExecution(BOOLEAN Alertable, PLARGE_INTEGER Interval);
NTSTATUS NTAPI ZwDeleteAtom(USHORT Atom);
NTSTATUS NTAPI ZwDeleteFile(POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwDeleteKey(HANDLE KeyHandle);
NTSTATUS NTAPI ZwDeleteObjectAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, BOOLEAN GenerateOnClose);
NTSTATUS NTAPI ZwDeleteValueKey(HANDLE KeyHandle, PUNICODE_STRING ValueName);
NTSTATUS NTAPI ZwDeviceIoControlFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, ULONG IoControlCode, PVOID InputBuffer,
    ULONG InputBufferLength, PVOID OutputBuffer, ULONG OutputBufferLength);
NTSTATUS NTAPI ZwDisplayString(PUNICODE_STRING String);
NTSTATUS NTAPI ZwDuplicateObject(HANDLE SourceProcessHandle,
    HANDLE SourceHandle, HANDLE TargetProcessHandle,
    PHANDLE TargetHandle, ACCESS_MASK DesiredAccess,
    ULONG Attributes, ULONG Options);
NTSTATUS NTAPI ZwDuplicateToken(HANDLE ExistingTokenHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes,
    BOOLEAN EffectiveOnly, TOKEN_TYPE TokenType, PHANDLE NewTokenHandle);
NTSTATUS NTAPI ZwEnumerateKey(HANDLE KeyHandle, ULONG Index,
    KEY_INFORMATION_CLASS KeyInformationClass, PVOID KeyInformation,
    ULONG KeyInformationLength, PULONG ResultLength);
NTSTATUS NTAPI ZwEnumerateValueKey(HANDLE KeyHandle, ULONG Index,
    KEY_VALUE_INFORMATION_CLASS KeyValueInformationClass,
    PVOID KeyValueInformation,
    ULONG KeyValueInformationLength, PULONG ResultLength);
NTSTATUS NTAPI ZwExtendSection(HANDLE SectionHandle,
    PLARGE_INTEGER SectionSize);
NTSTATUS NTAPI ZwFilterToken(HANDLE ExistingTokenHandle, ULONG Flags,
    PTOKEN_GROUPS SidsToDisable, PTOKEN_PRIVILEGES PrivilegesToDelete,
    PTOKEN_GROUPS SidsToRestricted, PHANDLE NewTokenHandle);
NTSTATUS NTAPI ZwFindAtom(PWSTR String, ULONG StringLength, PUSHORT Atom);
NTSTATUS NTAPI ZwFlushBuffersFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock);
NTSTATUS NTAPI ZwFlushInstructionCache(HANDLE ProcessHandle,
    PCVOID BaseAddress, ULONG FlushSize);
NTSTATUS NTAPI ZwFlushKey(HANDLE KeyHandle);
NTSTATUS NTAPI ZwFlushVirtualMemory(HANDLE ProcessHandle, PVOID *BaseAddress,
    PULONG FlushSize, PIO_STATUS_BLOCK IoStatusBlock);
NTSTATUS NTAPI ZwFlushWriteBuffer(VOID);
NTSTATUS NTAPI ZwFreeUserPhysicalPages(HANDLE ProcessHandle,
    PULONG NumberOfPages, PULONG PageFrameNumbers);
NTSTATUS NTAPI ZwFreeVirtualMemory(HANDLE ProcessHandle,
    PVOID *BaseAddress, PULONG FreeSize, ULONG FreeType);
NTSTATUS NTAPI ZwFsControlFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, ULONG FsControlCode,
    PVOID InputBuffer, ULONG InputBufferLength,
    PVOID OutputBuffer, ULONG OutputBufferLength);
NTSTATUS NTAPI ZwGetContextThread(HANDLE ThreadHandle, PCONTEXT Context);
NTSTATUS NTAPI ZwGetDevicePowerState(HANDLE DeviceHandle,
    PDEVICE_POWER_STATE DevicePowerState);
NTSTATUS NTAPI ZwGetPlugPlayEvent(ULONG Reserved1,
    ULONG Reserved2, PVOID Buffer, ULONG BufferLength);
NTSTATUS NTAPI ZwGetTickCount(VOID);
NTSTATUS NTAPI ZwGetWriteWatch(HANDLE ProcessHandle, ULONG Flags,
    PVOID BaseAddress, ULONG RegionSize, PULONG Buffer,
    PULONG BufferEntries, PULONG Granularity);
NTSTATUS NTAPI ZwImpersonateAnonymousToken(HANDLE ThreadHandle);
NTSTATUS NTAPI ZwImpersonateClientOfPort(HANDLE PortHandle,
    PPORT_MESSAGE Message);
NTSTATUS NTAPI ZwImpersonateThread(HANDLE ThreadHandle,
    HANDLE TargetThreadHandle, PSECURITY_QUALITY_OF_SERVICE SecurityQos);
NTSTATUS NTAPI ZwInitializeRegistry(BOOLEAN Setup);
NTSTATUS NTAPI ZwInitiatePowerAction(POWER_ACTION SystemAction,
    SYSTEM_POWER_STATE MinSystemState, ULONG Flags, BOOLEAN Asynchronous);
NTSTATUS NTAPI ZwIsSystemResumeAutomatic(VOID);
NTSTATUS NTAPI ZwListenPort(HANDLE PortHandle, PPORT_MESSAGE Message);
NTSTATUS NTAPI ZwLoadDriver(PUNICODE_STRING DriverServiceName);
NTSTATUS NTAPI ZwLoadKey(POBJECT_ATTRIBUTES KeyObjectAttributes,
    POBJECT_ATTRIBUTES FileObjectAttributes);
NTSTATUS NTAPI ZwLoadKey2(POBJECT_ATTRIBUTES KeyObjectAttributes,
    POBJECT_ATTRIBUTES FileObjectAttributes, ULONG Flags);
NTSTATUS NTAPI ZwLockFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock,
    PULARGE_INTEGER LockOffset, PULARGE_INTEGER LockLength,
    ULONG Key, BOOLEAN FailImmediately, BOOLEAN ExclusiveLock);
NTSTATUS NTAPI ZwLockVirtualMemory(HANDLE ProcessHandle,
    PVOID *BaseAddress, PULONG LockSize, ULONG LockType);
NTSTATUS NTAPI ZwMakeTemporaryObject(HANDLE Handle);
NTSTATUS NTAPI ZwMapUserPhysicalPages(PVOID BaseAddress,
    PULONG NumberOfPages, PULONG PageFrameNumbers);
NTSTATUS NTAPI ZwMapUserPhysicalPagesScatter(PVOID *BaseAddresses,
    PULONG NumberOfPages, PULONG PageFrameNumbers);
NTSTATUS NTAPI ZwMapViewOfSection(HANDLE SectionHandle,
    HANDLE ProcessHandle, PVOID *BaseAddress, ULONG ZeroBits,
    ULONG CommitSize, PLARGE_INTEGER SectionOffset,
    PULONG ViewSize, SECTION_INHERIT InheritDisposition,
    ULONG AllocationType, ULONG Protect);
NTSTATUS NTAPI ZwNotifyChangeDirectoryFile(HANDLE FileHandle,
    HANDLE Event, PIO_APC_ROUTINE ApcRoutine,
    PVOID ApcContext, PIO_STATUS_BLOCK IoStatusBlock,
    PFILE_NOTIFY_INFORMATION Buffer, ULONG BufferLength,
    ULONG NotifyFilter, BOOLEAN WatchSubtree);
NTSTATUS NTAPI ZwNotifyChangeKey(HANDLE KeyHandle,
    HANDLE EventHandle, PIO_APC_ROUTINE ApcRoutine,
    PVOID ApcContext, PIO_STATUS_BLOCK IoStatusBlock,
    ULONG NotifyFilter, BOOLEAN WatchSubtree, PVOID Buffer,
    ULONG BufferLength, BOOLEAN Asynchronous);
NTSTATUS NTAPI ZwNotifyChangeMultipleKeys(HANDLE KeyHandle,
    ULONG Flags, POBJECT_ATTRIBUTES KeyObjectAttributes,
    HANDLE EventHandle, PIO_APC_ROUTINE ApcRoutine,
    PVOID ApcContext, PIO_STATUS_BLOCK IoStatusBlock,
    ULONG NotifyFilter, BOOLEAN WatchSubtree, PVOID Buffer,
    ULONG BufferLength, BOOLEAN Asynchronous);
NTSTATUS NTAPI ZwOpenDirectoryObject(PHANDLE DirectoryHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenEvent(PHANDLE EventHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenEventPair(PHANDLE EventPairHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenFile(PHANDLE FileHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PIO_STATUS_BLOCK IoStatusBlock,
    ULONG ShareAccess, ULONG OpenOptions);
NTSTATUS NTAPI ZwOpenIoCompletion(PHANDLE IoCompletionHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenJobObject(PHANDLE JobHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenKey(PHANDLE KeyHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenMutant(PHANDLE MutantHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenObjectAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID *HandleId, PUNICODE_STRING ObjectTypeName, PUNICODE_STRING ObjectName,
    PSECURITY_DESCRIPTOR SecurityDescriptor, HANDLE TokenHandle,
    ACCESS_MASK DesiredAccess, ACCESS_MASK GrantedAccess,
    PPRIVILEGE_SET Privileges, BOOLEAN ObjectCreation, BOOLEAN AccessGranted,
    PBOOLEAN GenerateOnClose);
NTSTATUS NTAPI ZwOpenProcess(PHANDLE ProcessHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PCLIENT_ID ClientId);
NTSTATUS NTAPI ZwOpenProcessToken(HANDLE ProcessHandle,
    ACCESS_MASK DesiredAccess, PHANDLE TokenHandle);
NTSTATUS NTAPI ZwOpenSection(PHANDLE SectionHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenSemaphore(PHANDLE SemaphoreHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenSymbolicLinkObject(PHANDLE SymbolicLinkHandle,
    ACCESS_MASK DesiredAccess, POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwOpenThread(PHANDLE ThreadHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes, PCLIENT_ID ClientId);
NTSTATUS NTAPI ZwOpenThreadToken(HANDLE ThreadHandle, ACCESS_MASK DesiredAccess,
    BOOLEAN OpenAsSelf, PHANDLE TokenHandle);
NTSTATUS NTAPI ZwOpenTimer(PHANDLE TimerHandle, ACCESS_MASK DesiredAccess,
    POBJECT_ATTRIBUTES ObjectAttributes);
NTSTATUS NTAPI ZwPowerInformation(POWER_INFORMATION_LEVEL PowerInformationLevel,
    PVOID InputBuffer, ULONG InputBufferLength,
    PVOID OutputBuffer, ULONG OutputBufferLength);
NTSTATUS NTAPI ZwPrivilegeCheck(HANDLE TokenHandle,
    PPRIVILEGE_SET RequiredPrivileges, PBOOLEAN Result);
NTSTATUS NTAPI ZwPrivilegedServiceAuditAlarm(PUNICODE_STRING SubsystemName,
    PUNICODE_STRING ServiceName, HANDLE TokenHandle,
    PPRIVILEGE_SET Privileges, BOOLEAN AccessGranted);
NTSTATUS NTAPI ZwPrivilegeObjectAuditAlarm(PUNICODE_STRING SubsystemName,
    PVOID HandleId, HANDLE TokenHandle, ACCESS_MASK DesiredAccess,
    PPRIVILEGE_SET Privileges, BOOLEAN AccessGranted);
NTSTATUS NTAPI ZwProtectVirtualMemory(HANDLE ProcessHandle, PVOID *BaseAddress,
    PULONG ProtectSize, ULONG NewProtect, PULONG OldProtect);
NTSTATUS NTAPI ZwPulseEvent(HANDLE EventHandle, PULONG PreviousState);
NTSTATUS NTAPI ZwQueryInformationAtom(USHORT Atom,
    ATOM_INFORMATION_CLASS AtomInformationClass,
    PVOID AtomInformation, ULONG AtomInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryAttributesFile(POBJECT_ATTRIBUTES ObjectAttributes,
    PFILE_BASIC_INFORMATION FileInformation);
NTSTATUS NTAPI ZwQueryDefaultLocale(BOOLEAN ThreadOrSystem, PLCID Locale);
NTSTATUS NTAPI ZwQueryDefaultUILanguage(PLANGID LanguageId);
NTSTATUS NTAPI ZwQueryDirectoryFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID FileInformation,
    ULONG FileInformationLength, FILE_INFORMATION_CLASS FileInformationClass,
    BOOLEAN ReturnSingleEntry, PUNICODE_STRING FileName,
    BOOLEAN RestartScan);
NTSTATUS NTAPI ZwQueryDirectoryObject(HANDLE DirectoryHandle, PVOID Buffer,
    ULONG BufferLength, BOOLEAN ReturnSingleEntry, BOOLEAN RestartScan,
    PULONG Context, PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryEaFile(HANDLE FileHandle, PIO_STATUS_BLOCK IoStatusBlock,
    PFILE_FULL_EA_INFORMATION Buffer, ULONG BufferLength,
    BOOLEAN ReturnSingleEntry,
    PFILE_GET_EA_INFORMATION EaList, ULONG EaListLength,
    PULONG EaIndex, BOOLEAN RestartScan);
NTSTATUS NTAPI ZwQueryEvent(HANDLE EventHandle,
    EVENT_INFORMATION_CLASS EventInformationClass, PVOID EventInformation,
    ULONG EventInformationLength, PULONG ResultLength);
NTSTATUS NTAPI ZwQueryFullAttributesFile(POBJECT_ATTRIBUTES ObjectAttributes,
    PFILE_NETWORK_OPEN_INFORMATION FileInformation);
NTSTATUS NTAPI ZwQueryInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID FileInformation,
    ULONG FileInformationLength, FILE_INFORMATION_CLASS FileInformationClass);
NTSTATUS NTAPI ZwQueryInformationJobObject(HANDLE JobHandle,
    JOBOBJECTINFOCLASS JobInformationClass, PVOID JobInformation,
    ULONG JobInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryIoCompletion(HANDLE IoCompletionHandle,
    IO_COMPLETION_INFORMATION_CLASS IoCompletionInformationClass,
    PVOID IoCompletionInformation, ULONG IoCompletionInformationLength,
    PULONG ResultLength);
NTSTATUS NTAPI ZwQueryInformationPort(HANDLE PortHandle,
    PORT_INFORMATION_CLASS PortInformationClass, PVOID PortInformation,
    ULONG PortInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryInformationProcess(HANDLE ProcessHandle,
    PROCESSINFOCLASS ProcessInformationClass, PVOID ProcessInformation,
    ULONG ProcessInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryInformationThread(HANDLE ThreadHandle,
    THREADINFOCLASS ThreadInformationClass, PVOID ThreadInformation,
    ULONG ThreadInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryInformationToken(HANDLE TokenHandle,
    TOKEN_INFORMATION_CLASS TokenInformationClass, PVOID TokenInformation,
    ULONG TokenInformationLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryInstallUILanguage(PLANGID LanguageId);
NTSTATUS NTAPI ZwQueryIntervalProfile(KPROFILE_SOURCE Source, PULONG Interval);
NTSTATUS NTAPI ZwQueryKey(HANDLE KeyHandle,
    KEY_INFORMATION_CLASS KeyInformationClass, PVOID KeyInformation,
    ULONG KeyInformationLength, PULONG ResultLength);
NTSTATUS NTAPI ZwQueryMultipleValueKey(HANDLE KeyHandle,
    PKEY_VALUE_ENTRY ValueList, ULONG NumberOfValues,
    PVOID Buffer, PULONG Length, PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryMutant(HANDLE MutantHandle,
    MUTANT_INFORMATION_CLASS MutantInformationClass,
    PVOID MutantInformation, ULONG MutantInformationLength,
    PULONG ResultLength);
NTSTATUS NTAPI ZwQueryObject(HANDLE ObjectHandle,
    OBJECT_INFORMATION_CLASS ObjectInformationClass,
    PVOID ObjectInformation, ULONG ObjectInformationLength,
    PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryOpenSubKeys(POBJECT_ATTRIBUTES KeyObjectAttributes,
    PULONG NumberOfKeys);
NTSTATUS NTAPI ZwQueryPerformanceCounter(PLARGE_INTEGER PerformanceCount,
    PLARGE_INTEGER PerformanceFrequency);
NTSTATUS NTAPI ZwQueryQuotaInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PFILE_USER_QUOTA_INFORMATION Buffer,
    ULONG BufferLength, BOOLEAN ReturnSingleEntry,
    PFILE_QUOTA_LIST_INFORMATION QuotaList, ULONG QuotaListLength,
    PSID ResumeSid, BOOLEAN RestartScan);
NTSTATUS NTAPI ZwQuerySection(HANDLE SectionHandle,
    SECTION_INFORMATION_CLASS SectionInformationClass,
    PVOID SectionInformation, ULONG SectionInformationLength,
    PULONG ResultLength);
NTSTATUS NTAPI ZwQuerySecurityObject(HANDLE Handle,
    SECURITY_INFORMATION RequestedInformation,
    PSECURITY_DESCRIPTOR SecurityDescriptor,
    ULONG SecurityDescriptorLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwQuerySemaphore(HANDLE SemaphoreHandle,
    SEMAPHORE_INFORMATION_CLASS SemaphoreInformationClass,
    PVOID SemaphoreInformation,
    ULONG SemaphoreInformationLength, PULONG ResultLength);
NTSTATUS NTAPI ZwQuerySymbolicLinkObject(HANDLE SymbolicLinkHandle,
    PUNICODE_STRING TargetName, PULONG ReturnLength);
NTSTATUS NTAPI ZwQuerySystemEnvironmentValue(
    PUNICODE_STRING Name, PVOID Value, ULONG ValueLength,
    PULONG ReturnLength);
NTSTATUS NTAPI ZwQuerySystemInformation(
    SYSTEM_INFORMATION_CLASS SystemInformationClass,
    PVOID SystemInformation, ULONG SystemInformationLength,
    PULONG ReturnLength);
NTSTATUS NTAPI ZwQuerySystemTime(PLARGE_INTEGER CurrentTime);
NTSTATUS NTAPI ZwQueryTimer(HANDLE TimerHandle,
    TIMER_INFORMATION_CLASS TimerInformationClass,
    PVOID TimerInformation, ULONG TimerInformationLength,
    PULONG ResultLength);
NTSTATUS NTAPI ZwQueryTimerResolution(PULONG CoarsestResolution,
    PULONG FinestResolution, PULONG ActualResolution);
NTSTATUS NTAPI ZwQueryValueKey(HANDLE KeyHandle, PUNICODE_STRING ValueName,
    KEY_VALUE_INFORMATION_CLASS KeyValueInformationClass,
    PVOID KeyValueInformation,
    ULONG KeyValueInformationLength, PULONG ResultLength);
NTSTATUS NTAPI ZwQueryVirtualMemory(HANDLE ProcessHandle, PVOID BaseAddress,
    MEMORY_INFORMATION_CLASS MemoryInformationClass,
    PVOID MemoryInformation, ULONG MemoryInformationLength,
    PULONG ReturnLength);
NTSTATUS NTAPI ZwQueryVolumeInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID VolumeInformation,
    ULONG VolumeInformationLength,
    FS_INFORMATION_CLASS VolumeInformationClass);
NTSTATUS NTAPI ZwQueueApcThread(HANDLE ThreadHandle,
    PKNORMAL_ROUTINE ApcRoutine, PVOID ApcContext, PVOID Argument1,
    PVOID Argument2);
NTSTATUS NTAPI ZwRaiseException(PEXCEPTION_RECORD ExceptionRecord,
    PCONTEXT Context, BOOLEAN SearchFrames);
NTSTATUS NTAPI ZwRaiseHardError(NTSTATUS Status, ULONG NumberOfArguments,
    ULONG StringArgumentsMask, PULONG Arguments,
    HARDERROR_RESPONSE_OPTION ResponseOption, PHARDERROR_RESPONSE Response);
NTSTATUS NTAPI ZwReadFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID Buffer,
    ULONG Length, PLARGE_INTEGER ByteOffset, PULONG Key);
NTSTATUS NTAPI ZwReadFileScatter(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PFILE_SEGMENT_ELEMENT Buffer,
    ULONG Length, PLARGE_INTEGER ByteOffset, PULONG Key);
NTSTATUS NTAPI ZwReadRequestData(HANDLE PortHandle, PPORT_MESSAGE Message,
    ULONG Index, PVOID Buffer, ULONG BufferLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwReadVirtualMemory(HANDLE ProcessHandle, PVOID BaseAddress,
    PVOID Buffer, ULONG BufferLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwRegisterThreadTerminatePort(HANDLE PortHandle);
NTSTATUS NTAPI ZwReleaseMutant(HANDLE MutantHandle, PULONG PreviousState);
NTSTATUS NTAPI ZwReleaseSemaphore(HANDLE SemaphoreHandle,
    LONG ReleaseCount, PLONG PreviousCount);
NTSTATUS NTAPI ZwRemoveIoCompletion(HANDLE IoCompletionHandle,
    PULONG CompletionKey, PULONG CompletionValue,
    PIO_STATUS_BLOCK IoStatusBlock, PLARGE_INTEGER Time);
NTSTATUS NTAPI ZwReplaceKey(POBJECT_ATTRIBUTES NewFileObjectAttributes,
    HANDLE KeyHandle, POBJECT_ATTRIBUTES OldFileObjectAttributes);
NTSTATUS NTAPI ZwReplyPort(HANDLE PortHandle, PPORT_MESSAGE ReplyMessage);
NTSTATUS NTAPI ZwReplyWaitReceivePort(HANDLE PortHandle, PULONG PortIdentifier,
    PPORT_MESSAGE ReplyMessage, PPORT_MESSAGE Message);
NTSTATUS NTAPI ZwReplyWaitReceivePortEx(HANDLE PortHandle,
    PULONG PortIdentifier, PPORT_MESSAGE ReplyMessage, PPORT_MESSAGE Message,
    PLARGE_INTEGER Timeout);
NTSTATUS NTAPI ZwReplyWaitReplyPort(HANDLE PortHandle,
    PPORT_MESSAGE ReplyMessage);
NTSTATUS NTAPI ZwRequestDeviceWakeup(HANDLE DeviceHandle);
NTSTATUS NTAPI ZwRequestPort(HANDLE PortHandle, PPORT_MESSAGE RequestMessage);
NTSTATUS NTAPI ZwRequestWaitReplyPort(HANDLE PortHandle,
    PPORT_MESSAGE RequestMessage, PPORT_MESSAGE ReplyMessage);
NTSTATUS NTAPI ZwRequestWakeupLatency(LATENCY_TIME Latency);
NTSTATUS NTAPI ZwResetEvent(HANDLE EventHandle, PULONG PreviousState);
NTSTATUS NTAPI ZwResetWriteWatch(HANDLE ProcessHandle,
    PVOID BaseAddress, ULONG RegionSize);
NTSTATUS NTAPI ZwRestoreKey(HANDLE KeyHandle, HANDLE FileHandle, ULONG Flags);
NTSTATUS NTAPI ZwResumeThread(HANDLE ThreadHandle, PULONG PreviousSuspendCount);
NTSTATUS NTAPI ZwSaveKey(HANDLE KeyHandle, HANDLE FileHandle);
NTSTATUS NTAPI ZwSaveMergedKeys(HANDLE KeyHandle1,
    HANDLE KeyHandle2, HANDLE FileHandle);
NTSTATUS NTAPI ZwSecureConnectPort(PHANDLE PortHandle, PUNICODE_STRING PortName,
    PSECURITY_QUALITY_OF_SERVICE SecurityQos,
    PPORT_SECTION_WRITE WriteSection, PSID ServerSid,
    PPORT_SECTION_READ ReadSection, PULONG MaxMessageSize,
    PVOID ConnectData, PULONG ConnectDataLength);
NTSTATUS NTAPI ZwSetIoCompletion(HANDLE IoCompletionHandle, ULONG CompletionKey,
    ULONG CompletionValue, NTSTATUS Status, ULONG Information);
NTSTATUS NTAPI ZwSetContextThread(HANDLE ThreadHandle, const CONTEXT *Context);
NTSTATUS NTAPI ZwSetDefaultHardErrorPort(HANDLE PortHandle);
NTSTATUS NTAPI ZwSetDefaultLocale(BOOLEAN ThreadOrSystem, LCID Locale);
NTSTATUS NTAPI ZwSetDefaultUILanguage(LANGID LanguageId);
NTSTATUS NTAPI ZwSetEaFile(HANDLE FileHandle, PIO_STATUS_BLOCK IoStatusBlock,
    PFILE_FULL_EA_INFORMATION Buffer, ULONG BufferLength);
NTSTATUS NTAPI ZwSetEvent(HANDLE EventHandle, PULONG PreviousState);
NTSTATUS NTAPI ZwSetHighEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI ZwSetHighWaitLowEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI ZwSetInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock,
    PVOID FileInformation, ULONG FileInformationLength,
    FILE_INFORMATION_CLASS FileInformationClass);
NTSTATUS NTAPI ZwSetInformationJobObject(HANDLE JobHandle,
    JOBOBJECTINFOCLASS JobInformationClass,
    PVOID JobInformation, ULONG JobInformationLength);
NTSTATUS NTAPI ZwSetInformationKey(HANDLE KeyHandle,
    KEY_SET_INFORMATION_CLASS KeyInformationClass,
    PVOID KeyInformation, ULONG KeyInformationLength);
NTSTATUS NTAPI ZwSetInformationObject(HANDLE ObjectHandle,
    OBJECT_INFORMATION_CLASS ObjectInformationClass,
    PVOID ObjectInformation, ULONG ObjectInformationLength);
NTSTATUS NTAPI ZwSetInformationProcess(HANDLE ProcessHandle,
    PROCESSINFOCLASS ProcessInformationClass, PVOID ProcessInformation,
    ULONG ProcessInformationLength);
NTSTATUS NTAPI ZwSetInformationThread(HANDLE ThreadHandle,
    THREADINFOCLASS ThreadInformationClass,
    PVOID ThreadInformation, ULONG ThreadInformationLength);
NTSTATUS NTAPI ZwSetInformationToken(HANDLE TokenHandle,
    TOKEN_INFORMATION_CLASS TokenInformationClass,
    PVOID TokenInformation, ULONG TokenInformationLength);
NTSTATUS NTAPI ZwSetIntervalProfile(ULONG Interval, KPROFILE_SOURCE Source);
NTSTATUS NTAPI ZwSetLdtEntries(ULONG Selector1, LDT_ENTRY LdtEntry1,
    ULONG Selector2, LDT_ENTRY LdtEntry2);
NTSTATUS NTAPI ZwSetLowEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI ZwSetLowWaitHighEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI ZwSetQuotaInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PFILE_USER_QUOTA_INFORMATION Buffer,
    ULONG BufferLength);
NTSTATUS NTAPI ZwSetSecurityObject(HANDLE Handle,
    SECURITY_INFORMATION SecurityInformation,
    PSECURITY_DESCRIPTOR SecurityDescriptor);
NTSTATUS NTAPI ZwSetSystemEnvironmentValue(PUNICODE_STRING Name,
    PUNICODE_STRING Value);
NTSTATUS NTAPI ZwSetSystemInformation(
    SYSTEM_INFORMATION_CLASS SystemInformationClass,
    PVOID SystemInformation, ULONG SystemInformationLength);
NTSTATUS NTAPI ZwSetSystemPowerState(POWER_ACTION SystemAction,
    SYSTEM_POWER_STATE MinSystemState, ULONG Flags);
NTSTATUS NTAPI ZwSetSystemTime(PLARGE_INTEGER NewTime, PLARGE_INTEGER OldTime);
NTSTATUS NTAPI ZwSetThreadExecutionState(EXECUTION_STATE ExecutionState,
    PEXECUTION_STATE PreviousExecutionState);
NTSTATUS NTAPI ZwSetTimer(HANDLE TimerHandle, const LARGE_INTEGER *DueTime,
    PTIMERAPCROUTINE TimerApcRoutine, PVOID TimerContext,
    BOOLEAN Resume, LONG Period, PBOOLEAN PreviousState);
NTSTATUS NTAPI ZwSetTimerResolution(ULONG RequestedResolution,
    BOOLEAN Set, PULONG ActualResolution);
NTSTATUS NTAPI ZwSetUuidSeed(PUCHAR UuidSeed);
NTSTATUS NTAPI ZwSetValueKey(HANDLE KeyHandle, PUNICODE_STRING ValueName,
    ULONG TitleIndex, ULONG Type, PVOID Data, ULONG DataSize);
NTSTATUS NTAPI ZwSetVolumeInformationFile(HANDLE FileHandle,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID Buffer, ULONG BufferLength,
    FS_INFORMATION_CLASS VolumeInformationClass);
NTSTATUS NTAPI ZwShutdownSystem(SHUTDOWN_ACTION Action);
NTSTATUS NTAPI ZwSignalAndWaitForSingleObject(HANDLE HandleToSignal,
    HANDLE HandleToWait, BOOLEAN Alertable, PLARGE_INTEGER Time);
NTSTATUS NTAPI ZwStartProfile(HANDLE ProfileHandle);
NTSTATUS NTAPI ZwStopProfile(HANDLE ProfileHandle);
NTSTATUS NTAPI ZwSuspendThread(HANDLE ThreadHandle,
    PULONG PreviousSuspendCount);
NTSTATUS NTAPI ZwSystemDebugControl(DEBUG_CONTROL_CODE ControlCode,
    PVOID InputBuffer, ULONG InputBufferLength, PVOID OutputBuffer,
    ULONG OutputBufferLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwTerminateJobObject(HANDLE JobHandle, NTSTATUS ExitStatus);
NTSTATUS NTAPI ZwTerminateProcess(HANDLE ProcessHandle, NTSTATUS ExitStatus);
NTSTATUS NTAPI ZwTerminateThread(HANDLE ThreadHandle, NTSTATUS ExitStatus);
NTSTATUS NTAPI ZwTestAlert(VOID);
NTSTATUS NTAPI ZwUnloadDriver(PUNICODE_STRING DriverServiceName);
NTSTATUS NTAPI ZwUnloadKey(POBJECT_ATTRIBUTES KeyObjectAttributes);
NTSTATUS NTAPI ZwUnlockFile(HANDLE FileHandle, PIO_STATUS_BLOCK IoStatusBlock,
    PULARGE_INTEGER LockOffset, PULARGE_INTEGER LockLength, ULONG Key);
NTSTATUS NTAPI ZwUnlockVirtualMemory(HANDLE ProcessHandle,
    PVOID *BaseAddress, PULONG LockSize, ULONG LockType);
NTSTATUS NTAPI ZwUnmapViewOfSection(HANDLE ProcessHandle, PVOID BaseAddress);
NTSTATUS NTAPI ZwVdmControl(ULONG ControlCode, PVOID ControlData);
NTSTATUS NTAPI ZwWaitForMultipleObjects(ULONG HandleCount, PHANDLE Handles,
    WAIT_TYPE WaitType, BOOLEAN Alertable, PLARGE_INTEGER Time);
NTSTATUS NTAPI ZwWaitForSingleObject(HANDLE Handle,
    BOOLEAN Alertable, PLARGE_INTEGER Time);
NTSTATUS NTAPI ZwWaitHighEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI ZwWaitLowEventPair(HANDLE EventPairHandle);
NTSTATUS NTAPI ZwWriteFile(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PVOID Buffer, ULONG Length,
    PLARGE_INTEGER ByteOffset, PULONG Key);
NTSTATUS NTAPI ZwWriteFileGather(HANDLE FileHandle, HANDLE Event,
    PIO_APC_ROUTINE ApcRoutine, PVOID ApcContext,
    PIO_STATUS_BLOCK IoStatusBlock, PFILE_SEGMENT_ELEMENT Buffer,
    ULONG Length, PLARGE_INTEGER ByteOffset, PULONG Key);
NTSTATUS NTAPI ZwWriteRequestData(HANDLE PortHandle,
    PPORT_MESSAGE Message, ULONG Index, PVOID Buffer,
    ULONG BufferLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwWriteVirtualMemory(HANDLE ProcessHandle, PVOID BaseAddress,
    PVOID Buffer, ULONG BufferLength, PULONG ReturnLength);
NTSTATUS NTAPI ZwYieldExecution(VOID);

#endif	/* !_NTDLL_H */

