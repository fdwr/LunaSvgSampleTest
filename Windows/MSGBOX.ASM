; Windows Test Program

[section code code]
[section data data]
[section bss bss]

[extern ExitProcess]
[extern MessageBox]
[extern OutputDebugString]
[extern wvsprintf]

global Main

MB_ICONINFORMATION  equ 000040h

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

section data

Text:
.title: db "Windows Message Box Test",0
.msg:   db "This is a test and only a test",13
        db "Had this been a real emergency,",13
        db "the little MessageBox would have",13
        db "been followed by a MessageBeep",13
        db 13
        db "Compiled with NASM and linked with ALINK",13
        db "By Peekin on 2002-02-26",0

.eax:   db "eax",0
.ebx:   db "ebx",0
.ecx:   db "ecx",0
.edx:   db "edx",0
.esi:   db "esi",0
.edi:   db "edi",0
.ebp:   db "ebp",0
.esp:   db "esp",0
.flags: db "flags",0
.cr0:   db "cr0",0
.cr2:   db "cr2",0
.cr3:   db "cr3",0
.cr4:   db "cr4",0
.eip:   db "eip",0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

; Used to call standard API functions contained in DLLs
%macro api 1-*
    %rep %0 -1
      %rotate -1
      push dword %1
    %endrep
    %rotate -1
    call [%1]                   ;call indirectly through function pointer
%endmacro

; Used to call COM functions
%macro com 2-*
    %rep %0 -2
      %rotate -1
      push dword %1
    %endrep
    %rotate -2
    %ifid
      mov edx,[%2]              ;get ptr to function table
    %else
      mov eax,[%2]              ;get ptr to COM object
      mov edx,[eax]             ;get ptr to function table
      push eax
    %endif
    call [edx+%1]               ;call very indirectly through function table
%endmacro

%macro debugmsg 1-9
    %rep %0
      %rotate -1
      %ifstr %1
        section data
        %%Msg: db %1,0
        section code
        push dword %%Msg
      %else
        push dword %1
      %endif
    %endrep
    push dword %0*4
    call SendDebugMsg
%endmacro

Main:
%if 0
    push esp
    push dword Text.esp
    push ebp
    push dword Text.ebp
    push edi
    push dword Text.edi
    push esi
    push dword Text.esi
    push edx
    push dword Text.edx
    push ecx
    push dword Text.ecx
    push ebx
    push dword Text.ebx
    push eax
    push dword Text.eax
    pushfd
    push dword Text.flags

    call ShowRegValue
    call ShowRegValue
    call ShowRegValue
    call ShowRegValue
    call ShowRegValue
    call ShowRegValue
    call ShowRegValue
    call ShowRegValue
    call ShowRegValue

    mov eax,cr4
    push eax
    push dword Text.cr4
    mov eax,cr3
    push eax
    push dword Text.cr3
    mov eax,cr2
    push eax
    push dword Text.cr2
    mov eax,cr0
    push eax
    push dword Text.cr0

    call ShowRegValue
    call ShowRegValue
    call ShowRegValue
    call ShowRegValue
    call .GetIp
.GetIp:
    push dword Text.eip
    call ShowRegValue
%endif

    ;debugmsg "You should see a number here: %d ?", 123
    ;api MessageBox, 0, NumToString.Buffer, title, 0

    debugmsg "MessageBox:%X wvsprintf:%X OutputDebugString:%X ExitProcess:%X", MessageBox,wvsprintf,OutputDebugString,ExitProcess

    ;api MessageBox, 0, Text.msg, Text.title, MB_ICONINFORMATION
    api MessageBox, 0, Text.msg, 0, 0;MB_ICONINFORMATION

    jmp [ExitProcess]

; The full way to do the above call:
;
;   push dword 0
;   push dword title
;   push dword NumToString.Buffer;msg
;   push dword 0
;   call [MessageBoxA]
;
;   Each 32bit parameter is passed onto stack, and then the linked DLL
;   function is called indirectly through the import table pointer.

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SendDebugMsg:
    pop dword [.RetAdr]
    pop dword [.StackCount]     ;get bytes used by parameters passed
    pushf
    pusha
    lea esi,[esp+40]            ;ptr to array of values
    api wvsprintf, .FormatBuffer, [esp+40], esi
    api OutputDebugString, .FormatBuffer
    popa
    popf
    add esp,[.StackCount]       ;adjust stack before returning
    jmp dword [.RetAdr]

section bss
.RetAdr:        resd 1
.StackCount:    resd 1
.FormatBuffer:  resb 1024
section code

%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ShowRegValue:
    pop edx                     ;get return address
    pop esi                     ;get value name to show in title bar
    pop eax                     ;get register value
    push dword 0                ;simple OK
    push esi
    push dword NumToString.Buffer
    push dword 0                ;no modal hwnd
    push edx                    ;return address
    call NumToString
    jmp [MessageBoxA]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Turns a 32bit number into a decimal (or other) string, writing it to edi.
; By default, it converts a number to a decimal string, maximum of ten
; characters, stored in NumToString.Buffer. To change where the string is
; stored, the length, or radix, these variables can be passed to a different
; entry point. If an alternate destination is supplied, the default is a
; decimal number up to ten characters. If a length is supplied, so must the
; destination; and if the radix, so must both destination and length be given.
;
; (eax=number, edi=destination, ?ecx=maximum length, ?ebx=radix)
; (ecx=offset of first significant digit, ebx=radix used; esi)
NumToString:
    mov edi,.Buffer
;(edi=destination)
.UsingDest:
    ;mov ecx,[.MaxLen]       ;default maximum of ten characters, since the largest 32bit number is 4 gigabytes
    mov ecx,.DefMaxLen
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
    mov ecx,edx             ;return offset of first digit
    cld
	ret

section data
.DefMaxLen      equ 10
;.MaxLen:       dd .DefMaxLen
.FillChar:      db ' '
.NumberTable:   db "0123456789ABCDEF"
section bss
.Buffer:        resb .DefMaxLen
%endif
