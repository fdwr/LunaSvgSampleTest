; RIFF Size (c)PeekinSoft
; 2002-08-10 / 2002-08-10
; Dwayne Robinson (FDwR@hotmail.com)
;
; Purpose:
;   Simply displays the correct length of a RIFF structured media file, for
;   it is ripped out of a larger data file, executable, or library.
;
; Reason:
;   How possibly can the Windows shell (shell32.dll) be nearly 1MB in size.
;   It really doesn't do THAT much. I found the real reason to be, not
;   functionality, but a ton of data. In addition to all the icons, there
;   were 8 AVIs and even a MIDI file in there!?
;
;   After exporting them, I had playable files but a little larger than
;   necessary for safe padding (didn't want to delete part of the AVI).
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

[section code code]
[section data data]
[section text data]
[section bss bss]
global Main

; Include Windows definitions/constants/macros
;%define debug
%define UseFileSystem
%define UseTextConsole
%define UseConsoleDebug
%include "mywininc.asm"         ;standard Windows constants, structs...

section data
StdOut:         dd INVALID_FILE_HANDLE
FileSize:       dd 0
CorrectSize:    dd 0
SetFileSize:    dd FALSE

section bss
MediaFileName:  resb MAX_PATH
MediaHeader:    resb 20
MediaHeader_size equ $-MediaHeader
dummy:          resd 1
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Main:
    debugwrite "program start"

    api GetStdHandle, STD_OUTPUT_HANDLE
    mov [StdOut],eax
    mov edx,.MsgTitle
    call WriteString

    mov byte [MediaFileName],0
    call CheckStartParams
    push dword .End
    jc .ParamErr

    cmp byte [MediaFileName],0
    jne .NoParamErr
.ParamErr:
    jmp WriteString
.NoParamErr:

    mov eax,GENERIC_READ
    cmp dword [SetFileSize],TRUE
    jne .NoFileWrite
    mov eax,GENERIC_READ|GENERIC_WRITE
.NoFileWrite:

    api CreateFile, MediaFileName, eax, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL
    debugwrite "Source file handle=%X",eax
    cmp eax,INVALID_FILE_HANDLE
    mov edx,.MsgErrOpen         ;set error message in case jump is taken
    je near WriteString
    mov ebx,eax

    api ReadFile, eax,MediaHeader, MediaHeader_size,dummy, NULL
    api SetFilePointer, ebx, 0,NULL, FILE_END
    mov [FileSize],eax

    mov eax,[MediaHeader]       ;get four character code
    mov ecx,4
.NextCc:
    cmp al,32                   ;ensure there are no control characters
    jae .CcValid
    mov al,32
.CcValid:
    rol eax,8
    dec ecx
    jg .NextCc
    mov [.HeaderType],eax

    ; eax=four CC
    ;cmp eax,'RIFF'

    mov ecx,[MediaHeader+4]
    lea edx,[ecx+8+3]
    and edx,~3
    mov [CorrectSize],edx

    ;cmp eax,'MThd'

    ; edx=correct size
    cmp dword [SetFileSize],TRUE
    jne .NoSetFileSize
    api SetFilePointer, ebx, edx,NULL, FILE_BEGIN
    api SetEndOfFile, ebx
.NoSetFileSize:

    api CloseHandle, ebx

    api wvsprintf, .TextBuffer, .HeaderInfo, esp, [FileSize],[MediaHeader+4],[CorrectSize]
    add esp,byte 12
    mov edx,.TextBuffer
    call WriteString

.End:
    api ExitProcess;,0

section text
.MsgTitle:      db "RIFF Size 1.0 2002-08-10 PeekinSoft",13,10
                db 10,0
.MsgErrOpen:    db "Error opening media file",0
.HeaderInfo:    db "Four CC type id: "
.HeaderType:    db "xxxx",13,10
                db "File size:       %lu bytes",13,10
                db "Data size is:    %lu bytes",13,10
                db "File should be:  %lu bytes",13,10
                db 0
section bss
.TextBuffer:    resb 256
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Checks the command line parameters and sets options accordingly.
; Can return text with error.
; Does not directly end the program, but returns carry to tell the caller to
; end it.
;
; () (cf=error, edx=error message)
CheckStartParams:
    push ebp
    mov ebp,esp

%ifdef DosVer
    mov eax,0006h               ;get segment base address
    mov bx,[Program.PspSelector]
    int 31h
    mov esi,ecx
    shl esi,16
    mov si,dx                   ;CX:DX = 32-bit linear base address of segment

    movzx ecx,byte [esi+80h]
    add esi,81h
%else
    api GetCommandLine
    mov esi,eax
    call .GetWordLen
    mov esi,ebx
    call GetStringLength
    ;debugwrite "command line = %s length = %d",esi,ecx
%endif

    add ecx,esi
    mov [.EndPtr],ecx
    call .GetNextParam          ;skip any initial space
.NextParam:
    jae .End                    ;cf=0
    push dword .NextParam
    push dword .CheckNextParam
    cmp byte [esi],'/'          ;is it an DOS switch?
    je .Option
    cmp byte [esi],'-'          ;is it an Unix switch?
    jne near .NonSwitchParam    ;if not, assume it might be a filename
.Option:
    mov ebx,.List
    inc esi                     ;skip '/'
    call .MatchWord
    mov edx,.MsgInvalidParameter
    jc .End
    jmp dword [.Jtbl+eax*4]
; (edx=error message ptr)
.Err:
    stc
; (edx=error message ptr if carry set)
.End:
    mov esp,ebp
    pop ebp
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Verifies the next parameter is separated properly by either a space, slash,
; null, or some other valid character.
; If all is okay, it will skip any separating space and return the new ptr.
; If there is an error in the parameter line, this routine will NOT return,
; but instead abort with an error message.
; (esi=param char ptr) (esi=new ptr)
.CheckNextParam:
    movzx eax,byte [esi]
    bt dword [.SepChars],eax
    mov edx,.MsgInvalidParameter ;just in case invalid parameter
    jc .End                     ;cf=1

; skip any separating space and return the new ptr
; (esi=param char ptr) (esi=new ptr, ae=past end; *)
.GetNextParam:
    dec esi
.SkipSpace:
    inc esi
    cmp byte [esi],' '
    je .SkipSpace
    cmp esi,[.EndPtr]
    ;jae .End                    ;cf=0
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Searches through a string list for given text and returns matching index.
; Mainly used to match switch parameters, but can actually be used for any.
; (esi=search text, ebx=string list) (cf=error no match, eax=index)
.MatchWord:
    xor eax,eax                 ;start with first word in string list
    xor ecx,ecx
    ;cld
    jmp short .MwFirstCompare
.MwNextCompare:
    mov edx,ecx                 ;copy word length
    mov edi,ebx                 ;set to word in list for comparison
    rep cmpsb
    je .MwMatch                 ;word matched (cf=0)
    add esi,ecx                 ;compensate for change in esi after search
    add ebx,edx                 ;advance next string in list
    inc eax                     ;next word in list
    sub esi,edx
.MwFirstCompare:
    mov cl,[ebx]                ;get of length compare string
    inc ebx                     ;skip length byte to first character
    test ecx,ecx
    jnz .MwNextCompare          ;continue until word length = 0
    stc                         ;no words left, none matched
.MwMatch:                       ;match from above (cf=0)
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Determines length of word, up to next space, or within quotes.
; Mainly used to get filename, but can also be used for words following
; parameters.
; (esi=char ptr) (ecx=char length, ebx=ptr to following char; esi)
.GetWordLen:
    xor ecx,ecx
    cmp byte [esi],'"'
    mov ah,' '
    jne .GwlUnquoted
    inc esi
    mov ah,'"'
.GwlUnquoted:
    mov ebx,esi                 ;copy parameter char ptr
.GwlNext:
    mov al,[ebx]                ;get char
    test al,al                  ;is null? for when in Windows or Wudebug
    jz .GwlEnd
  %ifdef DosVer
    cmp al,13                   ;for when normal command line start
    je .GwlEnd
  %endif
    cmp al,ah                   ;is space or ending quote
    je .GwlEnd
    inc ebx
    inc ecx                     ;count another character in word
    jmp short .GwlNext
.GwlEnd:
    cmp al,'"'
    jne .GwlNoLastQuote
    inc ebx                     ;skip closing quote
.GwlNoLastQuote:
    ret

%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns a number from the current parameter, adjusted char ptr to the
; character immediately after the last number.
; If the number is missing, this routine will NOT return, but instead abort
; with an error message.
; (esi=ptr to number)
; (eax=value, esi=first character after number)
.GetNumber:
    mov ebx,10                  ;default is decimal numbers
; (ebx=alternate radix)
.GetNumberOfRadix:
    call .GetNextParam          ;skip any initial space
    mov edx,Text.MissingParameter ;set message in case error
    jae near .Err
    ;movzx eax,byte [esi]
    ;bt dword [.SepChars],eax
    ;jc near .Err                ;no number so end

    mov ecx,StringToNum.DefMaxLen
    call StringToNum.UsingLRadix
    mov edx,Text.MissingParameter ;set message in case error
    jz near .Err                ;no number so end
    ret
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.NonSwitchParam:
    ;cld
    ;cmp byte [MediaFileName],0
    ;mov edx,Text.MultipleParameters
    ;jne near .Err
    call .GetWordLen
    mov edi,MediaFileName
    xor eax,eax
    rep movsb
    stosb                       ;put null on end of filename
    mov esi,ebx                 ;skip trailing " or space
    ret
.Help:
    call .CheckNextParam
    mov edx,.MsgAbout
    jmp .Err
.SetSize:
    mov dword [SetFileSize],TRUE
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text
.MsgInvalidParameter:
    db "Invalid parameter",0
.MsgAbout:
    db "Usage: RIFFSIZE [mediafile]",13,10
    db 0

section data
align 4, db 0
.EndPtr:    dd 0
.SepChars:  ;characters that can separate parameters
    dd 11111111111111111101101111111110b  ;(control characters)
    dd 11111111111111110111111111111110b  ;?>=<;:9876543210/.-,+*)('&%$#"! 
    dd 11101111111111111111111111111111b  ;_^]\[ZYXWVUTSRQPONMLKJIHGFEDCBA@
    dd 11111111111111111111111111111111b  ;~}|{zyxwvutsrqponmlkjihgfedcba`
    dd 11111111111111111111111111111111b  ;Ÿžœ›š™˜—–•”“’‘ŽŒ‹Š‰ˆ‡†…„ƒ‚€
    dd 11111111111111111111111111111111b  ;¿¾½¼»º¹¸·¶µ´³²±°¯®­¬«ª©¨§¦¥¤£¢¡ 
    dd 11111111111111111111111111111111b  ;ßÞÝÜÛÚÙØ×ÖÕÔÓÒÑÐÏÎÍÌËÊÉÈÇÆÅÄÃÂÁÀ
    dd 11111111111111111111111111111111b  ;ÿþýüûúùø÷öõôóòñðïîíìëêéèçæåäãâáà

.Jtbl:      ;jump table for parameters
    dd .Help
    dd .Help
    dd .SetSize
.List:      ;parameter word strings
    ;first byte is length of string
    ;following bytes are characters of parameter string (1-255)
    ;last length of list is zero
    db 1,"h"
    db 1,"?"
    db 1,"s"
    db 0
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes an ASCIIZ string to screen, not terminated by stupid "$"
;
; (edx=ptr to string)
; (; esi)
WriteString:
    mov ecx,2048            ;maximum length of characters
	mov edi,edx             ;copy source for string length search
	mov eax,ecx             ;make a copy of max length for later and set al to null
    ;xor al,al              ;;look for null
    cld
    repne scasb             ;search for the end
    ;neg ecx                ;;get negative count
    ;dec ecx                ;;minus the null at the end
	not ecx                 ;negate count and subtract null at the end
	add ecx,eax             ;get length
; (edx=ptr to string, ecx=count)
.OfLength:
%ifdef DosVer
    mov ebx,1               ;console output handle
    mov ah,40h              ;DOS: Write to file
	int 21h
%else
    api WriteFile, [StdOut],edx,ecx,dummy,NULL
%endif
    ret

%if 0
; Writes ASCIIZ string and appends end of line
; (edx=ptr to string)
.WithEol:
    mov ecx,2048            ;maximum length of characters
	mov edi,edx             ;copy source for string length search
	mov eax,ecx             ;make a copy of max length for later and set al to null
    ;xor al,al              ;;look for null
    cld
    repne scasb             ;search for the end
	not ecx                 ;negate count and subtract null at the end
    dec edi
    lea ecx,[ecx+eax+2]     ;get length
    push dword [edi]
    mov dword [edi],120A0Dh
    call .OfLength
    pop dword [edi]
    ret

; (edx=formatted string, dwords Number1, Number2...)
.Formatted:
    lea esi,[esp+4]         ;set number parameter ptr to first one

.FormattedNext:
    ; get length of string part up to either next % or end
    mov ecx,2048|"%"        ;maximum length of characters
	mov edi,edx             ;copy source for string length search
    mov eax,ecx             ;make a copy of max length for later and set al to null
    ;xor al,al              ;look for null
    cld
    repne scasb             ;search for the end
	not ecx                 ;negate count and subtract null at the end
    add ecx,eax             ;part length = previous length - remaining length
    call .OfLength
    mov bl,[edi]
    lea edx,[edi+1]          ;advance to next section of string
    test bl,bl
    je near .FormattedEnd

    ; check if number is pointed to in string or on stack
    cmp bl,'p'
    je .FormattedPtr
    mov eax,[esi]
    add esi,byte 4
    jmp short .FormattedStack
.FormattedPtr:
    mov ebx,[edx]               ;indirect pointer
    mov eax,[ebx]               ;get number
    add edx,byte 5
    mov bl,[edx-1]
.FormattedStack:

    ; determine number type and print accordingly
    push edx                ;save text ptr
    push dword .FormattedNum
    cmp bl,'b'
    je .FormatByte
    cmp bl,'d'
    je near NumToString
    cmp bl,'h'
    je .FormatHex
    cmp bl,'%'              ;two % in a row means not a control code
    jne .FormatNone
    push edx
%ifdef DosVer
    mov dl,bl
    mov ah,2
    int 21h
%else
    api WriteFile, [StdOut],edx,1,dummy,NULL
%endif
    pop edx
.FormatHex:
    mov edi,NumToString.Buffer
    mov ecx,NumToString.DefMaxLen
    mov ebx,16
    jmp NumToString.UsingDLRadix
.FormatByte:
    movzx eax,al
    jmp NumToString
.FormattedNum:
    lea edx,[NumToString.Buffer+ecx]
    neg ecx
    add ecx,NumToString.DefMaxLen
    call .OfLength
.FormatNone:

    pop edx                 ;retrieve text ptr
    mov ecx,[esp]           ;retrieve total remaining string length
    jmp .FormattedNext

.FormattedEnd:
    ret
%endif


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


%if 0
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
    cld                     ;for dumb Windows sake (so it doesn't crash)
    ret

section data
.DefMaxLen      equ 10
;.MaxLen:       dd .DefMaxLen
.FillChar:      db ' '
.NumberTable:   db "0123456789ABCDEF"
section bss
.Buffer:        resb .DefMaxLen
section code
%endif
