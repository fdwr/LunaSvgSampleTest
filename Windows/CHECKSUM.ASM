; Checksum (c)PeekinSoft
; 2003-02-04 / 2003-12-16
; Dwayne Robinson (FDwR@hotmail.com)
;
; Purpose:
;   Calculates dword addition checksum of a file. The top most bits (if file
;   byte length not multiple of 4) are zeroed.
;
; Reason:
;   Can identify errors in or changes to the file.
;
; Future:
;   Match multiple filemasks (*.exe;*.dll;*.cpl) (*.mpg;*.avi;*.mp3)
;   Scan subdirectories, recurse from current path
;   Accept input filenames from a redirected text file
;   Compare files with existing csum list and display differences
;
; 2003-02-04 Birth of progam. Copy most code from RiffSize.
; 2003-02-06 Add filemasks to support multiple checksumming.
;            Add long print format to redirect listing to files
;            Can detect whether started from console or GUI and wait for key
; 2003-02-11 Add full path option.
;            Changed print order to print csum:csum, file, size.
;            Commented simple add/xor checksums. Use prime (7 & 13) bit rolls.
; 2003-05-16 Add show current path option. Will be useful later for when
;            path recursing is added.
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

[section code code]
[section data data]
[section text data]
[section bss bss]
global Main

%ifndef ConVer
%error "Compile with ConVer defined (-dConVer)"
%endif

; Include Windows definitions/constants/macros
;%define debug
%define UseFileSystem
%define UseTextConsole
%define UseConsoleDebug
%define UseProcess
%include "mywininc.asm"         ;standard Windows constants, structs...

section data
StdOut:         dd INVALID_FILE_HANDLE
StdErr:         dd INVALID_FILE_HANDLE
FileHandle:     dd 0
FilesOpened:    dd 0            ;count of files opened
FileNamePart:   dd FileMask     ;ptr to name portion
Options:        dd 0
.PrintLong      equ 1
.FullPath       equ 2
.ShowPath       equ 4

section bss
FileBuffer_size equ 65536*2
alignb 512
FileBuffer:     resb FileBuffer_size+4 ;(+4 for extra dword)
FileName:       resb MAX_PATH
FileMask:       resb MAX_PATH
FilePos:        resd 1
BytesRead:      resd 1
BytesWritten:   resd 1
StartTime:      resd 1
PrintTime:      resd 1
FindHandle:     resd 1
FileFindData:   resb WIN32_FIND_DATA_size
;FileSize:      resd 1
FileSize equ FileFindData+WIN32_FIND_DATA.nFileSizeLow
ProcessStartup: resb STARTUPINFO_size

ChecksumAdd:    resd 1
ChecksumXor:    resd 1
ChecksumMul:    resd 1
ChecksumRol:    resd 1
ChecksumRol2:   resd 1

section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Main:
    debugwrite "program start"

    ; get console output handle and disable cursor
    api GetStdHandle, STD_ERROR_HANDLE
    mov [StdErr],eax
    api GetStdHandle, STD_OUTPUT_HANDLE
    mov [StdOut],eax
    push dword FALSE            ;cursor invisible
    push dword 1                ;dummy size percentage
    api SetConsoleCursorInfo, eax, esp
    add esp,byte 8              ;free PCONSOLE_CURSOR_INFO

    ;api SetConsoleTextAttribute, [StdOut],FOREGROUND_GREEN|FOREGROUND_INTENSITY

    ; check command line parameters
    mov byte [FileName],0
    call CheckStartParams
    jc .ParamErr
    cmp byte [FileName],0
    jne .FileGiven
    mov edx,CheckStartParams.MsgAbout
.ParamErr:

    push edx
    mov edx,.MsgTitle
    call WriteErrorString
    mov edx,.MsgTitleBreak
    call WriteErrorString
    pop edx

    ; if started from command line, end now
    ; if started from GUI (and inherited no console), wait for key
    call WriteString
    api GetStartupInfo, ProcessStartup
    cmp dword [ProcessStartup+STARTUPINFO.hStdOutput],0
    jne near .End
    mov edx,.MsgWaitForKey
    call WriteString
    api GetStdHandle, STD_INPUT_HANDLE
    api ReadConsole, eax,BytesRead, 1,BytesRead, NULL
    jmp .End

.FileGiven:
    api SetConsoleTitle, .MsgTitle

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.MainLoop:

    api GetTickCount
    mov [StartTime],eax
    mov [PrintTime],eax

    api GetFullPathName, FileName, MAX_PATH,FileMask, FileNamePart
    test dword [Options],Options.ShowPath
    jz .NoShowPath
    mov edx,FileMask
    call WriteErrorString
    mov edx,.MsgTitleBreak
    call WriteErrorString
.NoShowPath:
    api FindFirstFile, FileMask,FileFindData
    debugwrite "find first file %s",FileFindData+WIN32_FIND_DATA.cFileName
    cmp eax,INVALID_HANDLE_VALUE
    je near .LastFile
    mov [FindHandle],eax

;<- top of loop

.ChecksumFile:
    test dword [FileFindData+WIN32_FIND_DATA.dwFileAttributes],FILE_ATTRIBUTE_DIRECTORY|FILE_ATTRIBUTE_TEMPORARY|8
    jnz near .NextFile
    ;cmp dword [FileFindData+WIN32_FIND_DATA.nFileSizeLow],0
    ;je .NextFile

    ; initialize vars for this checksum loop
    xor eax,eax
    mov [ChecksumAdd],eax
    mov [ChecksumXor],eax
    mov [ChecksumMul],eax
    mov [ChecksumRol],eax
    mov [ChecksumRol2],eax
    mov [FilePos],eax
    inc dword [FilesOpened]

    ;cld
    mov esi,FileFindData+WIN32_FIND_DATA.cFileName
    mov ecx,FileMask+MAX_PATH
    mov edi,[FileNamePart]
    sub ecx,edi
    rep movsb

    ; open file and get size
    ; open with seq scan and no buffering, 7% faster on hard drive files, %1 slower on CD drives
    mov eax,GENERIC_READ
    api CreateFile, FileMask, eax, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN|FILE_FLAG_NO_BUFFERING, NULL
    debugwrite "Source file handle=%X",eax
    cmp eax,INVALID_FILE_HANDLE
    jne .OpenSuccess
    api wsprintf, .TextBuffer,.MsgOpenError, FileMask
    add esp,byte 3*4
    mov edx,.TextBuffer
    call WriteErrorString
    jmp .NextFile
.OpenSuccess:
    mov [FileHandle],eax
    ;api GetFileSize, eax,NULL
    ;mov [FileSize],eax

    ;api SetFilePointer, [FileHandle], 0,NULL, FILE_BEGIN

.NextRead:
    ; read chunk from file, filling buffer
    api ReadFile, [FileHandle],FileBuffer, FileBuffer_size,BytesRead, NULL
    dec eax
    jz .ReadSuccess
    mov edx,.MsgReadError
    call WriteErrorString
    jmp .CloseFile
.ReadSuccess:

    ; enter checksum loop
    mov esi,[BytesRead]
    add [FilePos],esi
    mov dword [FileBuffer+esi],0 ;zero top unused bits
    dec esi                     ;bytes read --
    jl near .CloseFile          ;end if zero read
    and esi,~3                  ;nearest lower even multiple of 4
.NextDword:
    mov eax,[FileBuffer+esi]
    ;add [ChecksumAdd],eax
    ;xor [ChecksumXor],eax
    ;mov ecx,eax
    ;rol dword [ChecksumRol],cl

    rol dword [ChecksumRol],3
    add [ChecksumRol],eax
    ror dword [ChecksumRol2],7
    add [ChecksumRol2],eax

    ;imul dword [ChecksumMul]
    ;inc edx
    ;add dword [ChecksumMul],edx
    sub esi,byte 4
    jge .NextDword

    ; print file position every 1/4 second
    ; print to standard error instead of standard output so that if redirected,
    ;  progress numbers will still be sent to screen, not the file.
    api GetTickCount
    sub eax,[PrintTime]
    cmp eax,250
    jl .SkipPrint
    add [PrintTime],eax
    api wsprintf, .TextBuffer, .MsgFilePos, [FilePos],[FileSize]
    add esp,byte 4*4
    mov edx,.TextBuffer
    call WriteErrorString
.SkipPrint:

    ; continue if full buffer was read
    cmp dword [BytesRead],FileBuffer_size
    je near .NextRead

.CloseFile:
    api CloseHandle, [FileHandle]

    ; print file info

    test dword [Options],Options.FullPath
    mov esi,FileMask
    jnz .FullPath
    mov esi,[FileNamePart]
.FullPath:
    test dword [Options],Options.PrintLong
    mov edx,.FileInfoLong
    jnz .PrintLong
    mov edx,.FileInfo
.PrintLong:
    ;api wsprintf, .TextBuffer,edx, esi,[FileSize],[ChecksumAdd],[ChecksumXor],[ChecksumRol]
    api wsprintf, .TextBuffer,edx, [ChecksumRol],[ChecksumRol2],esi,[FileSize]
    add esp,byte 6*4
    mov edx,.TextBuffer
    call WriteString

.NextFile:
    api FindNextFile, [FindHandle],FileFindData
    debugwrite "find next file %s",FileFindData+WIN32_FIND_DATA.cFileName
    dec eax
    je near .ChecksumFile
    api FindClose, [FindHandle]

;<- bottom of loop

    ; print total time
    test dword [Options],Options.PrintLong
    jnz .SkipTime
    api GetTickCount
    sub eax,[StartTime]
    api wsprintf, .TextBuffer, .TotalTime, eax
    add esp,byte 3*4
    mov edx,.TextBuffer
    call WriteString
.SkipTime:

.LastFile:
    cmp dword [FilesOpened],0
    jne .SomeFilesOpened
    mov edx,.MsgNoFiles
    call WriteErrorString
.SomeFilesOpened:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.End:
    api ExitProcess;,0


section text
.MsgTitle:      db "Checksum 1.2 2003-02-11 PeekinSoft",0
.MsgTitleBreak: db 13,10,10,0
.MsgFilePos:    db "%u / %u",13,0
.MsgOpenError:  db "Error opening - %s",13,10,0
.MsgNoFiles:    db "No matching files found",13,10,0
.FileInfo:      db "Csum: %08X-%08X",13,10
                db "Name: %s",13,10
                db "Size: %u bytes",13,10
                ;db "Add:  %08X",13,10
                ;db "Xor:  %08X",13,10
                ;db "Rol:  %08X",13,10
                ;db "Mul: %08X",13,10
                db 10
                db 0
.FileInfoLong:  ;db 34,"%s",34,",%u,%X,%X,%X",13,10,0
                db "%08X:%08X,",34,"%s",34,",%u",13,10,0
.TotalTime:     db "Total time: %u milliseconds",13,10,0
                db 0
.MsgReadError:  db "!Read error",13,10,0
.MsgWaitForKey: db 13,10,"Press Enter key to end",0
section bss
.TextBuffer:    resb 1024
section code


%if 0
Dumb MS - there is a bug in their code that CLOSE event is never received
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ConsoleHandler:
    xor eax,eax
    ret 4
%endif

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
    ;cmp byte [FileName],0
    ;mov edx,Text.MultipleParameters
    ;jne near .Err
    call .GetWordLen
    mov edi,FileName
    xor eax,eax
    rep movsb
    stosb                       ;put null on end of filename
    mov esi,ebx                 ;skip trailing " or space
    ret
.Help:
    call .CheckNextParam
    mov edx,.MsgAbout
    jmp .Err
.PrintLong:
    or dword [Options],Options.PrintLong
    ret
.FullPath:
    or dword [Options],Options.FullPath
    ret
.ShowPath:
    or dword [Options],Options.ShowPath
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text
.MsgInvalidParameter:
    db "Invalid parameter",0
.MsgAbout:
    db "Usage: CHECKSUM [/options] [sourcefile]",13,10
    db 10
    db "Checksums file(s) using dword addition. Each iteration, the left part is rolled",13,10
    db "left three, then added to the total. The right part is rolled right seven and",13,10
    db "added. Any trailing bytes not a multiple of 4 are zero extended.",13,10
    db 10
    db "    sourcefile  can include full paths and wildcards",13,10
    db "    /l          print long listing suitable for list",13,10
    db "    /f          show full file path (not just name)",13,10
    db "    /p          show current path",13,10
    db 0

section data
align 4, db 0
.EndPtr:    dd 0
.SepChars:  ;characters that can separate parameters
    dd 11111111111111111101101111111110b  ;(control characters)
    dd 11111111111111110111111111111110b  ;?>=<;:9876543210/.-,+*)('&%$#"! 
    dd 11101111111111111111111111111111b  ;_^]\[ZYXWVUTSRQPONMLKJIHGFEDCBA@
    dd 11111111111111111111111111111111b  ;~}|{zyxwvutsrqponmlkjihgfedcba`
    dd 11111111111111111111111111111111b  ;Ÿœ›š™˜—–•”“’‘Œ‹Š‰ˆ‡†…„ƒ‚€
    dd 11111111111111111111111111111111b  ;¿¾½¼»º¹¸·¶µ´³²±°¯®­¬«ª©¨§¦¥¤£¢¡ 
    dd 11111111111111111111111111111111b  ;ßŞİÜÛÚÙØ×ÖÕÔÓÒÑĞÏÎÍÌËÊÉÈÇÆÅÄÃÂÁÀ
    dd 11111111111111111111111111111111b  ;ÿşıüûúùø÷öõôóòñğïîíìëêéèçæåäãâáà

.Jtbl:      ;jump table for parameters
    dd .Help
    dd .Help
    dd .PrintLong
    dd .FullPath
    dd .ShowPath
.List:      ;parameter word strings
    ;first byte is length of string
    ;following bytes are characters of parameter string (1-255)
    ;last length of list is zero
    db 1,"h"
    db 1,"?"
    db 1,"l"
    db 1,"f"
    db 1,"p"
    ;db [more options here...]
    db 0
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes an ASCIIZ string to error out.
;
; (edx=ptr to string)
; (; esi)
WriteErrorString:
    push esi
    mov esi,edx
    call GetStringLength
    api WriteFile, [StdErr],esi,ecx,BytesWritten,NULL
    pop esi
    ret

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
    api WriteFile, [StdOut],edx,ecx,BytesWritten,NULL
%endif
    ret

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

%if 0
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
    api WriteFile, [StdOut],edx,1,BytesWritten,NULL
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
