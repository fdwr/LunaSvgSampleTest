; Resource Extractor
; 2003-12-19
;
; Created because Resource Hacker (great program) does not export filenames
; based on their resource name, only a number - which was none too helpful
; when looking through the 552 bitmaps of various GUI parts contained in
; in the Luna theme. Plus, it was very slow on the old P90 I was working on
; over winter break and often froze the entire system hard for an unknown
; reason when viewing certain bitmaps.

; line:1584 col:105 wrap:128 BLUE_BUTTON

[section code code]
[section data data]
[section text data]
[section bss bss]

%define UseFileSystem
%define UseTextConsole
%define UseResources
%define UseWindowGfx
%define ConVer
%include "..\win\mywininc.asm"

section data
align 4, db 0
dummy:      dd 0                ;dword to waste unused values
hout:       dd 0                ;standard output handle (text console)
;hin:       dd 0                ;standard input handle (keyboard)

ResModule:  dd 0
ResType:    dd RT_BITMAP
ResName:    dd 0
ResLang:    dd 0                ;language
ResBlock:   dd 0                ;ptr to information block
ResSize:    dd 0                ;byte size
ResGmem:    dd 0                ;memory handle
ResExt:     dd ResExtBmp        ;filename extension

BitmapFileHeader:
db "BM" ;bfType
dd 0    ;bfSize
dw 0,0  ;bfReserved1&2
dd 0    ;bfOffBits

section bss
;LibFileName:    resb MAX_PATH
MsgBuffer:      resb MAX_PATH
ResTypeStr:     resb MAX_PATH
ResNameStr:     resb MAX_PATH
ResFileStr:     resb MAX_PATH
;-<temp hacks>-
section text
LibFileName:    db "D:\sort\res\luna.msstyles",0
;LibFileName:    db "C:\windows\system\shell32.dll",0
ResOutPath:     db "D:\sort\res\luna",0
ResExtBmp:      db "%s.bmp",0
ResExtIco:      db "%s.ico",0
ResExtCur:      db "%s.cur",0
ResExtUnk:      db "%s.bin",0

section text
ProgramTitle:   db "ResEx .01 (alpha)",0
ProgramTitleEx: db "- Quick and dirty Resource Extractor",13,10,0
ErmLoadResLib:  db "Could not load resource file :(",13,10,0
ErmInvalidDir:  db "Output directory is invalid :(",13,10,0
MsgLoadResLib:  db "Loading resource file...",13,10,0
MsgEnumResTypes:db "Enumerating resource types...",13,10,0
MsgEnumResNames:db "Enumerating resource names...",13,10,0
MsgResNameNum:  db "%05d",0
MsgResNameText: db "%s",0
MsgResModule:   db "[module@%X]",13,10,0
;MsgResInfo:    db "<block@%X,%d bytes,+%X>",0
MsgResInfo:     db ",%d bytes",13,10,0
;MsgResData:    db "<data@%X>",0
MsgAddEol:      db "%s",13,10,0
MsgFinished:    db "Finished :)",13,10,0



;=============================================================================
; MAIN ENTRY POINT
;=============================================================================

section code
global Main

Main:
    api SetConsoleTitle, ProgramTitle
    api GetStdHandle, STD_OUTPUT_HANDLE
    test eax,eax
    js near .Terminate
    mov [hout],eax
    mov edx,ProgramTitle
    call WriteString
    mov edx,ProgramTitleEx
    call WriteString

    ;call CheckStartParams
    ;jc .TerminateWithMsg
    ;test dword [PlayOptions],PlayOptions.FileGiven
    ;mov edx,Text.About
    ;jz .TerminateWithMsg        ;no file was given

    ; load module
    mov edx,MsgLoadResLib
    call WriteString
    api LoadLibraryEx, LibFileName, NULL, LOAD_LIBRARY_AS_DATAFILE
    test eax,eax
    mov edx,ErmLoadResLib
    jz near .TerminateWithMsg
    mov [ResModule],eax

    ; print module base
    api wsprintf, MsgBuffer, MsgResModule,eax
    add esp,byte 3*4
    mov edx,MsgBuffer
    call WriteString

    ; !@#$? Windows can not find a module name if loaded as data
    ;api GetModuleFileName, [ResModule],MsgBuffer,MAX_PATH
    ;api GetLastError
    ;api wsprintf, MsgBuffer, MsgResModule,eax
    ;add esp,byte 3*4
    ;mov edx,MsgBuffer
    ;call WriteString

    ;api FindResource, [ResModule], name, type
    ;api LoadResource
    ;api FreeLibrary

    api SetCurrentDirectory, ResOutPath
    test eax,eax
    mov edx,ErmInvalidDir
    jz .TerminateWithMsg

    ;hack starts here
    mov edx,MsgEnumResNames
    call WriteString
    api EnumResourceNames, [ResModule], [ResType], EnumResNameProc,0

    mov edx,MsgFinished
.TerminateWithMsg: ;(edx=msg ptr)
    call WriteString
.Terminate:
    extern ExitProcess
    jmp [ExitProcess]
    ;ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
EnumResNameProc:
    paramsrel 4+12, .Module, .Type, .Name, .Param
    push ebx,esi,edi

    mov eax,[esp+.Name]
    mov esi,MsgResNameNum
    cmp eax,65536               ; numeric if 16bit ID, string if ptr
    jb .NumericName
    mov esi,MsgResNameText
.NumericName:
    api wsprintf, ResNameStr, esi,eax
    add esp,byte 12
    mov edx,ResNameStr
    call WriteString

    ;api wsprintf, MsgBuffer, MsgAddEol,ResNameStr
    ;add esp,byte 12
    ;mov edx,MsgBuffer
    ;call WriteString

    ;api FindResource, [esp+.Module], [esp+.Type], [esp+.Name];, [ResLang]
    api FindResource, [ResModule],[esp+.Name+4],[ResType];, [ResLang]
    ;api GetLastError
    test eax,eax
    jz near .NoFind
    mov [ResBlock],eax

    ; print info block ptr, size, data offset
    ; (eax=res block ptr)
    ;;api SizeofResource, [ResModule],eax
    ;;mov edx,[eax+IMAGE_RESOURCE_DATA_ENTRY.OffsetToData]
    mov ecx,[eax+IMAGE_RESOURCE_DATA_ENTRY.Size]
    mov [ResSize],ecx
    api wsprintf, MsgBuffer, MsgResInfo,ecx
    add esp,byte 3*4
    mov edx,MsgBuffer
    call WriteString

    ; load resource
    api LoadResource, [ResModule],[ResBlock]
    test eax,eax
    jz near .NoLoad
    mov [ResGmem],eax
    ;api wsprintf, MsgBuffer, MsgResData,eax
    ;add esp,byte 3*4
    ;mov edx,MsgBuffer
    ;call WriteString

    ; lock resource not necessary
    ;api LockResource,[ResGmem]
    ;api wsprintf, MsgBuffer, MsgResData,eax
    ;add esp,byte 12
    ;mov edx,MsgBuffer
    ;call WriteString

    mov eax,[ResType]
    cmp eax,RT_BITMAP
    je .TypeBitmap
    ;cmp eax,RT_ICON
    ;je .TypeIcon
    ;cmp eax,RT_CURSOR
    ;je .TypeCursor
    jmp .TypeUnknown

.TypeBitmap:
    ; build bitmap header
    mov eax,[ResSize]
    mov esi,[ResGmem]
    add eax,byte 14             ;add size of pointless file header
    mov edx,[esi+BITMAPINFOHEADER.biClrUsed]
    mov [BitmapFileHeader+BITMAPFILEHEADER.bfSize],eax
    test edx,edx
    jnz .ColorsGiven
    ; else figure palette size manually
    mov cl,[esi+BITMAPINFOHEADER.biBitCount]
    cmp cl,8
    ja .ColorsGiven
    mov edx,1
    shl edx,cl
.ColorsGiven: ;(edx=palette colors)
    lea edx,[edx*4+14]          ;*4 because 4 bytes per color, +14 byte header
    add edx,[esi+BITMAPINFOHEADER.biSize]
    mov [BitmapFileHeader+BITMAPFILEHEADER.bfOffBits],edx
    jmp .OutputResource

;.TypeIcon:
;.TypeCursor:
.TypeUnknown:
    ;jmp .OutputResource

.OutputResource:
; (esi=resource data)
%if 1
    ; form name and create file
    api wsprintf, ResFileStr, [ResExt],ResNameStr
    add esp,byte 12
    ;mov edx,ResFileStr
    ;call WriteString
    api CreateFile, ResFileStr, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_FLAG_SEQUENTIAL_SCAN, NULL
    cmp eax,INVALID_FILE_HANDLE
    je near .NoFile
    push eax

    ; write resource headers if any
    cmp dword [ResType],RT_BITMAP
    jne .NoBitmapHeader
    api WriteFile, eax,BitmapFileHeader, 14,dummy, NULL
.NoBitmapHeader:

    ; write resource data
    api WriteFile, [esp+4*4],esi, [ResSize],dummy, NULL
    api CloseHandle;,[esp]
.NoFile:
%endif

    ; free resource not necessary either
    ;api FreeResource, []

    ;mov edx,MsgAddEol
    ;call WriteString

.NoFind:
.NoLoad:
    pop ebx,esi,edi
    mov eax,TRUE
    ret 16


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
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
    api WriteFile, [hout],edx,ecx,dummy,NULL
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
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
; 2002-09-03
; (eax=number, ?edi=destination, ?ecx=maximum length, ?ebx=radix)
; (esi=ptr to first significant digit, ebx=radix used; none)
NumToString:
    mov edi,.Buffer
;(edi=destination)
.UseDest:
    mov ecx,[.MaxLen]       ;default maximum of ten characters, since the largest 32bit number is 4 gigabytes
;(edi=destination, ecx=number of digits)
.UseDLen:
	mov ebx,10              ;base of the decimal system
;(edi=destination, ecx=number of digits, ebx=radix)
.UseDLRadix:                ;for hexadecimal and binary (even octal)
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
    lea esi,[edi+1]         ;return ptr to first significant character
	ret

.FillInBlanks:
    mov al,[.FillChar]      ;fill in with spaces, zeroes, asterisks
    lea esi,[edi+1]         ;return ptr to first significant character
    dec ecx                 ;one less than current count
    ;mov edx,ecx
    std                     ;move backwards
    rep stosb               ;for number of characters remaining
    ;mov ecx,edx            ;return offset of first digit
    cld                     ;for dumb Windows sake (so it doesn't crash)
    ret

section data
align 4
%ifndef .DefMaxLen
%define .DefMaxLen 10
%endif
.MaxLen:        dd .DefMaxLen
.FillChar:      db '0'
.NumberTable:   db "0123456789ABCDEF"
section bss
.Buffer:        resb .DefMaxLen
section code
