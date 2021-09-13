; Preload File (c)PeekinSoft
; Dwayne Robinson (FDwR@hotmail.com)
; 2002-06-28 Born
; 2002-06-28 Updated
;
; Purpose:
;   Preloads a file into memory to minimize disk clicking.


[section code code]
[section data data]
[section text data]
[section bss bss]
global Main


; Include Windows definitions/constants/macros
%define debug
%define UseWindowStyles
;%define UseWindowControls
%define UseWindowMsgs
%define UseMemory
%define UseFileSystem
%include "mywininc.asm"         ;standard Windows constants, structs...


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
align 4, db 0
hwnd:   dd 0                    ;window handle

wc:
.BaseAddress                    equ 400000h ;base address of program (Windows module handle)
istruc WNDCLASS
at WNDCLASS.style,              dd CS_CLASSDC
at WNDCLASS.lpfnWndProc,        dd MsgProc
at WNDCLASS.cbClsExtra,         dd 0
at WNDCLASS.cbWndExtra,         dd 0
at WNDCLASS.hInstance,          dd .BaseAddress ;(default image base is at 4MB)
at WNDCLASS.hIcon,              dd NULL
at WNDCLASS.hCursor,            dd NULL
at WNDCLASS.hbrBackground,      dd COLOR_BTNFACE + 1
at WNDCLASS.lpszMenuName,       dd NULL
at WNDCLASS.lpszClassName,      dd ClassNames.Program
iend

;rect:
;point:
;dd 0,            0             ;left,top
;dd Screen.Width, Screen.Height ;right,bottom

section bss
msg:    resb MSG_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:   db "Preload File 1.0 (Beta)" ;,0
NullString:     db 0

ClassNames:
.Program:       db "PknPreloadFile",0
;.Button:       db "BUTTON",0
;.Label:        db "STATIC",0
;.Edit:         db "EDIT",0
;.Progress:     db "msctls_progress32",0

ErrMsg:
.NoWindow:      db "Failed to create window.",0
.FileCode:      db "File Error #0000",0
.FileOpen:      db "Could not open file",0
.FileRead:      db "Could not read file",0
.NotEnoughMem:  db "Not enough memory",0

Text:
.NoFilename:    db "(drag & drop file)",0
.About:         db "Preloads a file into memory to minimize disk clicking."
                db 10,10
                db "Dwayne Robinson",10
                db "FDwR@hotmail.com",10
                db "PeekinSoft 2002-05-11"
                db 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; global program variables

section data
align 4, db 0
FileHandle: dd 0                ;source file's handle
FileHmem:   dd 0
FileLen:    dd 0

section bss
alignb 8
FileName:   resb MAX_PATH


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

Main:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create window

    api LoadCursor, 0,IDC_ARROW
    mov [wc+WNDCLASS.hCursor],eax
    api LoadIcon, wc.BaseAddress,1
    mov [wc+WNDCLASS.hIcon],eax

    ; register window class
    debugwrite "registering class"
    api RegisterClass, wc
    debugwrite "register result=%X", eax
    test eax,eax
    mov esi,ErrMsg.NoWindow
    jz near EndWithErrMsg

    ; create instance of window
    debugwrite "creating window"
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_MINIMIZEBOX|WS_VISIBLE|WS_SYSMENU, 0,0, 220,60, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    mov [hwnd],eax


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Message Loop

    debugwrite "entering main loop"
    jmp short .Next

.Top:
    mov eax,[msg+MSG.message]
    debugwinmsg "process msg=%X %s W=%X L=%X", eax,edx,[msg+MSG.wParam],[msg+MSG.lParam]
    api IsDialogMessage, [hwnd],msg
    ;api DispatchMessage, msg ;(IsDialogMessage does this)
.Next:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    ;js .MsgError (don't bother checking for errors)
    jnz .Top

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Termination

.EndAndClose:
    api CloseHandle, [FileHandle]
.End:
    debugpause "ending"
    api DestroyWindow, [hwnd]
    api ExitProcess, [msg+MSG.wParam]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section bss
alignb 4
.BytesRead:     resd 1
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]

    cmp eax,WM_COMMAND
    jne .NotCommand
    cmp word [esp+.wParam],IDCANCEL ;|(BN_CLICKED<<16)
    je near .EscPress
.NotCommand:
    ;cmp eax,WM_CREATE
    ;je near .Create
    cmp eax,WM_WINDOWPOSCHANGED
    je .RetFalse
    cmp eax,WM_WINDOWPOSCHANGING
    je .RetFalse
    cmp eax,WM_DROPFILES
    je .FileDropped
    cmp eax,WM_DESTROY
    je .Destroy

.DefProc:
    jmp [DefWindowProc]

.RetTrue:
    mov eax,TRUE
    ret 16

.Destroy:
    debugpause "destroying window"
    mov dword [hwnd],0
.EscPress:
    api PostQuitMessage,0
.RetFalse:
    xor eax,eax
    ret 16

.FileDropped:
    debugpause "File dropped"
    api DragQueryFile, [esp+.wParam+12],0, FileName,MAX_PATH
    api DragFinish, [esp+.wParam]
    debugpause "Source file name = %s",FileName

    push ebx,esi,edi

    ; free previous file
    api CloseHandle, [FileHandle]
    api LocalFree, [FileHmem]
    xor eax,eax
    mov [FileHandle],eax
    mov [FileHmem],eax

    ; load file
    api CreateFile, FileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL
    cmp eax,INVALID_FILE_HANDLE
    mov esi,ErrMsg.FileOpen     ;set error message in case jump is taken
    je near .FileError
    debugpause "file handle=%X",eax
    mov [FileHandle],eax

    ; get source file size
    api SetFilePointer, eax, 0,NULL,FILE_END
    debugpause "file end pointer=%d",eax
    mov [FileLen],eax

    ; allocate memory
    api LocalAlloc, LMEM_FIXED,eax
    test eax,eax
    jz .FileError
    debugpause "memory handle=%X",eax
    mov [FileHmem],eax

    ; read file
    api ReadFile, [FileHandle], eax,[FileLen],FileLen, NULL
    debugpause "read file result=%X",eax

.FileDropRet:
    debugpause "End File dropped"
    pop ebx,esi,edi
    xor eax,eax
    ret 16


.FileError: ;(esi=text message)
    api GetLastError
    call FormatFileError
    api MessageBox, [hwnd],esi,ErrMsg.FileCode,MB_ICONEXCLAMATION|MB_SETFOREGROUND
    api CloseHandle, [FileHandle]
    mov dword [FileHandle],NULL
    jmp short .FileDropRet

%if 0
.Create:
    mov eax,[esp+.hwnd]
    mov [hwnd],eax
    mov [FocusHwnd],eax
    api GetDC, eax              ;get window class display handle
    debugwrite "get hdc=%X",eax
    mov [hdc],eax
    api GetStockObject, DEFAULT_GUI_FONT
    mov [hfont],eax

    ; create labels
    push dword lblFilenameTxt
    call CreateChildWindow
    push dword lblFileSizeTxt
    call CreateChildWindow
    push dword lblProgressTxt
    call CreateChildWindow
    push dword lblErrorsTxt
    call CreateChildWindow
    push dword lblSectorSizeTxt
    call CreateChildWindow

    xor eax,eax
    ret 16
%endif


%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Copies a control structure onto parameter stack and calls CreateWindowEx.
; Sets the font for each control, assumes the standard GUI font has already
; been obtained.
CreateChildWindow:
    push esi,edi
    mov esi,[esp+12]
    xor eax,eax                 ;null window creation data
    push eax
    push dword wc.BaseAddress
    push dword [esi+WndControlStruct.hId]
    push dword [hwnd]
    ;cld
    sub esp,byte 7*4
    add esi,byte WndControlStruct.lpClassName
    mov ecx,7
    mov edi,esp
    rep movsd
    ;push eax                    ;no ex style
    push dword WS_EX_NOPARENTNOTIFY
    api CreateWindowEx
    mov [esi+WndControlStruct.hwnd-WndControlStruct_size],eax
    api SendMessage, eax,WM_SETFONT,[hfont],FALSE
    pop esi,edi
    ret 4
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=error message ptr)
EndWithErrMsg:
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBox, [hwnd],esi,ProgramTitle,MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL ;|MB_SETFOREGROUND
    api DestroyWindow, [hwnd]
    api ExitProcess, -1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; () (!ebx,edi)
FormatFileError:
    api GetLastError
    debugpause "File error",eax
    mov edi,ErrMsg.FileOpen+12
    mov ecx,4
    jmp NumToString.UsingDLen
    ;ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Turns a 32bit number into a decimal (or other) string, writing it to edi.
; By default, it converts a number to a decimal string, maximum of ten
; characters, stored in NumToString.Buffer. To change where the string is
; stored, the length, or radix, these variables can be passed to a different
; entry point. However, all variables before that point must also be defined.
; For example, changing the destination alone is fine, but to change the
; default max length, you must also pass the buffer ptr. To change the radix,
; all three variables must be passed.
;
; If number to be converted would exceed the default buffer size (this would
; only happen with a low radix like binary) a different buffer must be given.
; If a series of numbers will all share the same max character length, the
; .MaxLen variable can be set rather than passing it everytime.
;
; (eax=number, ?ecx=maximum length, ?edi=destination, ?ebx=radix)
; (ecx=offset of first significant digit, ebx=radix used; esi)
NumToString:
    mov edi,.Buffer
;(edi=destination)
.UsingDest:
    mov ecx,[.MaxLen]       ;default maximum of ten characters, since the largest 32bit number is 4 gigabytes
;(edi=destination, ecx=number of digits)
.UsingDLen:
	mov ebx,10              ;base of the decimal system
;(edi=destination, ecx=number of digits, ebx=radix)
.UsingDLRadix:              ;for hexadecimal and binary (even octal)
	xor edx,edx             ;set top 32 bits of quotient to zero
    lea edi,[edi+ecx-1]     ;start from rightmost character in number
.NextChar:
	div ebx                 ;divide number by the decimal base
    mov dl,[.NumberTable+edx] ;get ASCII character from table
    ;add dl,'0'             ;make remainder into an ASCII character
	mov [edi],dl            ;output result
    dec edi                 ;move backwards one character
	test eax,eax            ;see if we are done with the number
	jz .FillInBlanks        ;nothing but zeroes left
	xor edx,edx             ;set edx to zero again for next division
	dec ecx                 ;one less character to output
	jnz .NextChar
	ret

.FillInBlanks:
    mov al,[.FillChar]      ;fill in with spaces, zeroes, asterisks
    dec ecx                 ;one less than current count
    mov edx,ecx
    std                     ;move backwards
    rep stosb               ;for number of characters remaining
    cld                     ;clear df so dumb Windows doesn't crash
    mov ecx,edx             ;return offset of first digit
    ret

section data
align 4
.DefMaxLen      equ 10
.MaxLen:        dd .DefMaxLen
.FillChar:      db ' '
.NumberTable:   db "0123456789ABCDEF"
section bss
.Buffer:        resb .DefMaxLen+1
section code


%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=source)
; (ecx=length, zf=zero length; esi,edx)
GetStringLength:
    mov eax,1024            ;maximum length of characters
; (al=character to search for, eax=maximum length of characters to search)
.UntilChar:
    mov ecx,eax             ;make a copy of max length for later
    mov edi,esi             ;copy source for string length search
    cld                     ;as always, look forward
    repne scasb             ;search for the end, until character is found
    ;neg ecx                ;;get negative count
    ;dec ecx                ;;minus the character at the end
    not ecx                 ;negate count and subtract character at the end
    add ecx,eax             ;get length (conveniently sets zf)
    ret
%endif


%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns pointer to first character of filename, after path.
;
; (esi=filename zstring)
; (esi=first character of filename, edi=original filename)
GetFileName:
    mov edi,esi     ;copy source for string length search
    mov ecx,MAX_PATH;FilePathMaxLen
    xor eax,eax     ;look for null
    cld
    repne scasb     ;edi will point to one after end of string
    dec edi         ;skip backwards over null
.Next:
    dec edi         ;step back one character
    cmp edi,esi     ;check that it's still in the string
    jbe .End
    mov al,[edi]    ;get character
    cmp al,'\'      ;if backslash is encountered, then there was no extension
    je .Done
    cmp al,':'      ;if colon after drive letter
    jne .Next
.Done:
    inc edi
    xchg esi,edi
    ret
.End:
    mov edi,esi
    ret
%endif
