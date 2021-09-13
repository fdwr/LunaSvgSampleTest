; This is the dynamically loaded microcode that deletes its parent.
; Since all memory addressing in Win32 is flat linear, and since
; the OS does not automatically adjust all the references in this
; chunk of code, this program must know where it is loaded and offset
; all accesses by a base register. In this case, I chose esi.
; Upon last check (2002-01-06), the compiled code is 272 bytes.

bits 32

NULL equ 0
MAX_PATH equ 260

; Call standard API functions contained in DLLs
; using indirect function ptr from import table
;
; (function name ptr, parameters...)
%macro api 1-*
    %rep %0 -1
      %rotate -1
      %ifstr %1
[section .data]
        %%Text: db %1,0
__SECT__
        push dword %%Text       ;window text
      %else
        push dword %1
      %endif
    %endrep
    %rotate -1
    call [%1]                   ;call indirectly through function pointer
%endmacro

; (ASCIIZ function name,
;  function import ptr,
;  esi=code base,
;  edi=kernel module base)
%macro GetApiProcAddress 2
  %ifstr %1
[section .data]
    %%Text: db %1,0
__SECT__
	lea edx,[%%Text+esi]
  %else
	lea edx,[%1+esi]
  %endif
	push edx
	push edi
	call [GetProcAddress+esi]
	mov [%2+esi],eax
%endmacro

%macro SetErrorStrCode 1
  %ifstr %1
[section .data]
    %%Text: db %1,0
__SECT__
	push dword %%Text
  %else
	push dword %1
  %endif
	call SetErrorStrCode_
%endmacro

;-------------------------------------------------------------------------------
section .text

Main:
	; get base address
	call .Base
.Base:
	pop esi
	sub esi,byte .Base-Main
	; esi nows points to base of code memory (Main label)

	; assume these all work (they SHOULD!)
	mov edi,[KernelModule+esi]
	GetApiProcAddress "ExitProcess", ExitProcess
	GetApiProcAddress "DeleteFileA", DeleteFile
	GetApiProcAddress "GetModuleHandleA", GetModuleHandle
	GetApiProcAddress "GetModuleFileNameA", GetModuleFileName
	GetApiProcAddress "FreeLibrary", FreeLibrary
	GetApiProcAddress "GetLastError", GetLastError
	GetApiProcAddress "Sleep", Sleep

	lea edi,[ParentPath+esi]
	api GetModuleFileName+esi, NULL, edi, MAX_PATH
	SetErrorStrCode "GetModuleFileName failed"
	test eax,eax
	jz .Error

.FreeNext:
	api GetModuleHandle+esi, edi
	test eax,eax
	jz .FreeSucceed
	api FreeLibrary+esi, eax
	SetErrorStrCode "FreeLibrary failed"
	test eax,eax
	jz .Error
	jmp short .FreeNext

.FreeSucceed:
	api Sleep+esi, 2000

	api DeleteFile+esi,	edi
	SetErrorStrCode "DeleteFile failed"
	test eax,eax
	jz .Error
	;push dword 0 (return code irrelavant)
	jmp [ExitProcess+esi]

.Error:
	ret

SetErrorStrCode_:
	push eax
	;mov edx,[fs:60h]
	call [GetLastError+esi]
	mov ecx,eax
	mov edx,[esp+8]
	pop eax
	add edx,esi
	ret 4

;-------------------------------------------------------------------------------
section .data
align 4, db 0

; these variables MUST stay here at the bottom
KernelModule:		dd 0
GetProcAddress:		dd 0
align 4, db 0					; dword alignment MUST be kept

;-------------------------------------------------------------------------------
section .bss
ParentPath:	resb MAX_PATH

; imported function addresses
alignb 4
ExitProcess:		resd 1
DeleteFile:			resd 1
GetModuleHandle:	resd 1
GetModuleFileName:	resd 1
FreeLibrary:		resd 1
GetLastError:		resd 1
Sleep:				resd 1
