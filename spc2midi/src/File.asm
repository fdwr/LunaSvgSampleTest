; Spc2Midi - Anything File Related (load/saving/parsing filenames)
;-----------------------------------------------------------------------------

section data

ZstFile:;relative positions of registers within the savestate's spc portion
.Pc     equ 0
.A      equ 4
.X      equ 8
.Y      equ 12
.Flags  equ 16
.NZ     equ 20
.Sp     equ 24

SpcFile:;relative positions of registers
.Pc     equ 0
.A      equ 2
.X      equ 3
.Y      equ 4
.Flags  equ 5
.Sp     equ 6
;0002Eh-0004Dh - SubTitle/Song Name
;0004Eh-0006Dh - Title of Game
;0006Eh-0007Dh - Name of Dumper
;0007Eh-0009Dh - Comments
;0009Eh-000A4h - Date of SPC Dumped in decimal (DD/MM/YYYY)
;000A9h-000ABh - Time in seconds for the spc to play before fading
;000ACh-000AFh - Fade out time in milliseconds
;000B0h-000CFh - Author of Song
;000D0h        - Default Channel Disables (0 = enable, 1 = disable)
;000D1h        - Emulator used to dump .spc file
;                 (0 = UNKNOWN, 1 = ZSNES, 2 = SNES9X)

;absolute file positions in the SPC and lengths of each piece
align 4
SpcFile.Parts:
dd FileSpcRegs,25h,7            ;Registers
dd FileSpcRam ,100h,65536       ;RAM
dd FileDspRam ,10100h,128       ;DSP
dd FileSpcEram,101C0h,64        ;Extra RAM
dd 0

;absolute file positions in the savestate and lengths of each piece
ZstFile.Parts:
dd LoadSpcState.SpcSaved,36,1   ;flags whether savestate has sound emulation
dd FileSpcRam ,199699,65536     ;RAM
dd FileSpcRegs,265251,48        ;Registers
dd FileSpcEram,265299,64        ;Extra RAM
dd FileDspRam ,266623,128       ;DSP memory (128 registers)
dd 0
section code

;-----------------------------------------------------------------------------
; Reads in a savestate or spc, registers, flags, memory...
; This routine ONLY loads the necessary data from the file, and does not
; initialize any of the emulation variables.
;
; Ends if:
;   The filetype has an unknown extension
;   The file does not exist or can not be opened
;   It is corrupt
;   If the savestate was not saved with sound data
;
; () (cf=error, edx=error msg ptr; none)
LoadSpcState:
    mov esi,SpcFileName
    cmp dword [esi],'bios'      ;special filename
    jne .NotBios
    cmp byte [esi+4],0
    je near .LoadBios
.NotBios:
    call GetFileExtension
    mov ebx,'SPC'
    call CheckFileExtensionMatch
    je near .Spc
    mov ebx,'ZST'
    call CheckFileExtensionMatch
    je .Zst
    mov ebx,'ZMV'
    call CheckFileExtensionMatch
    je .Zst
.FileTypeError:
    mov edx,Text.FileTypeBad    ;don't know how to load it
.FileError:   ;(edx=msg)
    stc
.FileErrorCf: ;(cf=1, edx=msg)
.FileNoError: ;(cf=0)
	ret

;-------------------
.Zst:
    mov esi,Text.LoadingZstFile
    call StatusMessage

    mov byte [.SpcSaved],0
    mov esi,ZstFile.Parts
    call .ReadParts
    jc .FileErrorCf
    mov edx,Text.NoSpcFileData  ;set msg in case error
    test byte [.SpcSaved],1     ;check that sound was enabled
    jz .FileError               ;when the savestate was saved

	;Convert flags
    movzx eax,byte [FileSpcRegs+ZstFile.Flags]  ;get flags
    mov al,[SpcEmu.FlagTable+eax]           ;remap flags
    mov bl,byte [FileSpcRegs+ZstFile.NZ]    ;get SpcNZ
	and al,~(SpcFlag.N|SpcFlag.Z)           ;mask out N and Z
	test bl,bl
    jnz .ZeroFlagNotSet
    or al,SpcFlag.Z             ;set zero flag if NZ is zero
.ZeroFlagNotSet:
    and bl,SpcFlag.N            ;isolate N
    or al,bl                    ;combine N with flags

    ; Copy registers
    mov si,[FileSpcRegs+ZstFile.Pc]
    mov bl,[FileSpcRegs+ZstFile.A]
    mov cl,[FileSpcRegs+ZstFile.X]
    mov bh,[FileSpcRegs+ZstFile.Y]
    mov dl,[FileSpcRegs+ZstFile.Sp]
    jmp short .RemapRegs

;-------------------
.Spc:
    mov esi,Text.LoadingSpcFile
    call StatusMessage

    mov esi,SpcFile.Parts
    call .ReadParts
    jc near .FileErrorCf

    ; Copy registers
    movzx eax,byte [FileSpcRegs+SpcFile.Flags]  ;get flags
    mov si,[FileSpcRegs+SpcFile.Pc]
    mov bl,[FileSpcRegs+SpcFile.A]
    mov al,[SpcEmu.FlagTable+eax]  ;remap flags
    mov cl,[FileSpcRegs+SpcFile.X]
    mov bh,[FileSpcRegs+SpcFile.Y]
    mov dl,[FileSpcRegs+SpcFile.Sp]
    ;jmp short .RemapRegs

;-------------------
; Either spc or zst, both share the same code below.
; (al=flags, bx=AY, cl=X, dl=Sp, si=Pc)
.RemapRegs:

    mov [SpcEmu.FilePc],si
    mov [SpcEmu.FileAY],bx
    mov [SpcEmu.FileFlags],al
    mov [SpcEmu.FileX],cl
    mov [SpcEmu.FileSp],dl
    clc
    ret

;-------------------
; () (cf=0; none)
.LoadBios:
    mov esi,Text.LoadingBios
    call StatusMessage

    cld
    mov edi,FileSpcRam
    xor eax,eax
    mov ecx,(65536+128)/4
   %if FileSpcRam+65536 != FileDspRam
    %error "DSP RAM is expected to come immediately after SPC RAM"
   %endif
    rep stosd
    mov esi,SpcEmu.Rom
    mov edi,FileSpcEram         ;SpcEmu.Init will later copy this to 0FFC0h
    mov ecx,64/4
    rep movsd
    mov esi,SpcEmu.ResetRegs
    mov edi,SpcEmu.FileRegs
    mov ecx,SpcEmu.RegsSizeOf/4
    rep movsd
    clc                         ;return no error
    ret

;-------------------
; Opens the file, reads in the main parts of spc or savestate, then closes it.
; (esi=part table)
; (cf=error reading part)
.ReadParts:
%ifdef DosVer
    mov eax,3D40h               ;open for read with full sharing
    mov edx,SpcFileName
    int 21h
    mov edx,Text.FileOpenError
    jc .FileOpenError
%else
    xor eax,eax
    api CreateFile, SpcFileName, GENERIC_READ,FILE_SHARE_READ, eax, OPEN_EXISTING, eax,eax
    cmp eax,INVALID_HANDLE_VALUE
    stc
    mov edx,Text.FileOpenError
    je .FileOpenError
%endif
    mov ebx,eax                 ;copy returned file handle
    jmp short .FirstPart

.NextPart:
%ifdef DosVer
    mov edx,[esi+4]             ;get file position source
    shld ecx,edx,16             ;upper word into cx
    mov eax,4200h               ;get/set file position
    int 21h

    mov edx,edi                 ;get destination to read into memory
    mov ecx,[esi+8]             ;get length of piece
    add esi,byte 12
    mov ah,3Fh                  ;DOS: Read file
    int 21h
    ;mov edx,Text.SpcReadError
    ;cmp eax,ecx                 ;check that the full amount was read in
    ;jb .ReadPartError           ;end if amount read was less than it should be
%else
    api SetFilePointer, ebx, [esi+4],NULL,FILE_BEGIN
    api ReadFile, ebx,edi,[esi+8],dummy,NULL
    add esi,byte 12
%endif

.FirstPart:
    mov edi,[esi]               ;get next memory destination
    test edi,edi
    jnz .NextPart
.CloseFile:
%ifdef DosVer
    mov ah,3Eh
    int 21h
%else
    api CloseHandle, ebx
%endif
    clc                         ;should already be clear
.FileOpenError:
.ReadPartError: ;(cf=1)
    ret

section bss
.SpcSaved:  resb 1  ;flags whether or not savestate contains SPC info
section code

;-----------------------------------------------------------------------------
; Saves only header information; registers, flags, and memory; or both.
; Can also be used for converting savestates to SPCs.
; Ends if:
;   The file does not already exist using partial write mode
;   The file can be written to
%if 0
SaveSpcState:
    ; open existing or create new one
    mov ebx,3D41h               ;open for write with full sharing
    mov edx,SpcFileName
    int 21h
    mov edx,Text.FileOpenError
    jc .FileOpenError
    push eax                    ;save returned file handle
    mov esi,Text.SavingFile
    call StatusMessage
    pop ebx
.CloseFile:
    mov ah,3Eh
    int 21h
    ret

; Writes out the main parts of the spc.
; (esi=part table)
;.WriteParts:
;    jmp short .FirstPart
.NextPart:
    mov edx,[esi+4]             ;get file position destination
    shld ecx,edx,16             ;upper word into cx
    mov eax,4200h               ;get/set file position
    int 21h
    mov edx,edi                 ;get source to read from memory
    mov ecx,[esi+8]             ;get length of piece
    add esi,byte 12
    mov ah,40h                  ;DOS: Write file
    int 21h
    cmp eax,ecx                 ;check that the full amount was read in
    jb .WritePartError          ;end if amount written was less than it should be
.WriteParts:
.FirstPart:
    mov edi,[esi]               ;get next memory source
    test edi,edi
    jnz .NextPart
.FileOpenError:
    ret

.WritePartError:
    mov edx,Text.SpcReadError
    stc
    ret
%endif

;==============================
; Returns pointer to first character of filename, after path.
;
; (esi=filename zstring)
; (esi=first character of filename, edi=original filename)
GetFileName:
    mov edi,esi     ;copy source for string length search
    mov ecx,FilePathMaxLen
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
    cmp al,'/'      ;if forslash is encountered, then there was no extension
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


;==============================
; Returns extension without period and top byte null.
;
; (esi=filename zstring)
; (eax=extension, zf=no extension; esi=filename)
GetFileExtension:
    mov edi,esi     ;copy source for string length search
    mov ecx,FilePathMaxLen
    xor eax,eax     ;look for null
    cld
    repne scasb     ;edi will point to one after end of string
    dec edi         ;step backwards to null
    xor eax,eax     ;default is null if no extension
    ;cmp byte [edi-1],'"'
    ;jne .Next
    ;dec edi         ;skip quote

.Next:
    dec edi         ;step back one character
    shl eax,8       ;shift next character in extension
    cmp edi,esi     ;check that it's still in the string
    jbe .End

    mov al,[edi]    ;get character
    cmp al,'.'      ;if period, then it found the extension
    je .Done
    cmp al,':'      ;if drive letter colon encountered, there is no extension
    je .End
    cmp al,'\'      ;if backslash encountered, there is no extension
    je .End
    cmp al,'/'      ;if forslash is encountered, then there was no extension
    je .End

    cmp al,'a'
    jb .Next
    cmp al,'z'
    ja .Next
    and al,~32      ;capitalize character
    jmp short .Next

.Done:
    shr eax,8       ;zero flag should be clear here, unless there is no ext.
    ret

.End:
    xor eax,eax     ;clear extension and set zero flag
    ret


;==============================
; Checks if a file extension is a valid zst, zmv, or spc, which must start
; with the first two letters and either end in the third letter or a number
; 1-9. Sets zero flag (equal) if file extension matches given pattern. Does
; not change either eax or ebx for the purpose of multiple calls with
; different filename extensions.
;
; (eax=extension, ebx=mask)
; (zf=match or equal; eax,ebx)
CheckFileExtensionMatch:
    cmp eax,ebx         ;compare extension to entire mask
    je .Done            ;match, end
    cmp ax,bx           ;compare first two digits
    jne .Done           ;mismatch, end
    shld ecx,eax,16     ;get final extension digit to see if it's a number
    cmp cl,'0'          ;if less than zero or greater than nine
    jb .Done            ;then mismatch
    cmp cl,'9'
    ja .Done
    cmp eax,eax         ;set zero flag for caller to use je
.Done:
    ret


;-----------------------------------------------------------------------------
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
    api WriteFile, [hout],edx,ecx,dummy,NULL
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
    api WriteFile, [hout],edx,1,dummy,NULL
%endif
    pop edx
.FormatHex:
    mov edi,NumToString.Buffer
    mov ecx,NumToString.DefMaxLen
    mov ebx,16
    jmp NumToString.UseDLRadix
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
