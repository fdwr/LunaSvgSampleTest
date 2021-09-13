; Spc2Midi - Loading and saving settings
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Notes on settings files

; Unlike the usual .ini file which is only divided into sections, these files
; can have nested levels. Each one is started with an opening bracket "{" and
; ended with a closing bracket "}". Lines can contain either a key name
; opening a section, a key=value statement, or data formatted specifically
; for the current section, all depending on the current level. For example,
; the main level can contain key statements or key sections (which open
; sublevels). Inside the Settings section, all lines are keys (the title for
; those saved settings). Then inside one of those keys (maybe "Opening tune")
; are only data statements. Any sublevels within them would be ignored.

; All these characters are special:  { } = , ;
; and may not be used in any key names unless enclosed within quotation
; marks. They may all be used in values though. All spaces before a key name
; will be considered indentation and stripped. Preceding or trailing spaces
; within a quotation will be preserved. Blank lines are allowed. Control
; characters are treated as comments, unless within quotes, but should not be
; used anyway.

; Reading:
;   Able to read keys/values in any random order (most efficient if in expected order)
;   Ignores unknown keys, values, and unexpected sublevels
;   Ignores duplicate keys
;
; Writing:
;   Writes keys/values in a specific order
;   Ignores but keeps unknown keys, values, and unexpected sublevels
;   Deletes duplicate keys

section code

LoadMainSettings:

    mov esi,Text.LoadingSettings
    call StatusMessage

    ; open file
    mov edx,.IniFile
    call SettingsFile.OpenRead
    jc .OpenError

    push dword .KeyList
    push dword .KeyJtbl
    call SettingsFile.ReadKeys
    add esp,byte 8

%if 0 ;debug
    ; read all lines
    call SettingsFile.RestartRead
.NextLine:
    call SettingsFile.ReadLine
    ;cmp al,SettingsFile.LineClose
    ;jne .NextLine
    mov edx,esi
    call WriteString.WithEol
    cmp dword [SettingsFile.Indent],0
    jge .NextLine
%endif

    ; close file
  %ifdef DosVer
    mov ebx,[SettingsFile.SrcFileHnd]
    mov ah,3Eh
    int 21h
  %elifdef WinVer
    api CloseHandle,[SettingsFile.SrcFileHnd]
  %endif
.OpenError:
    ret

.Samples:
    jc .SamplesEnd
    push dword 11   ;items per line
    push dword GlobalSample.Max ;max number of keys
    push dword GlobalSample.Used
    push dword .ValueJtbl
    call SettingsFile.ReadValues
    add esp,byte 16
.SamplesEnd:
.Version:
.Games:
.SpcFiles:
    ret

; just in case someone messed with the file
.SampleIndex:
    cmp [GlobalSample.LastEntry],eax
    jae .SampleIndexLow
.SampleIndexLow:
    mov [GlobalSample.LastEntry],eax
    ret

.SampleName:
    push ebx
    push esi
    push ecx
    mov edx,esi
    add esi,ecx
    push dword [esi]
    add ecx,byte 3
    mov dword [esi],0A0DF9h ;write cr/lf
    call WriteString.OfLength
    pop dword [esi]
    pop ecx
    pop esi
    pop ebx

    mov edi,ebx
    shl edi,GlobalSample.NameShl
    add edi,GlobalSample.Name
    cmp cl,GlobalSample.NameMaxLen
    jbe .SampleNameLenOk
    mov ecx,GlobalSample.NameMaxLen
.SampleNameLenOk:
    mov [edi],cl
    inc edi
    rep movsb                   ;copy name, from file buffer to sample table
    ret

.SampleLength:
    push ebx
    call StringToNum
    pop ebx
    cmp eax,116048
    jbe .SampleLengthSet
    mov eax,116048
.SampleLengthSet:
    mov [GlobalSample.Length+ebx*4],eax
    ret

.SampleLoopLen:
    push ebx
    call StringToNum
    pop ebx
    cmp eax,116048
    jbe .SampleLoopLenSet
.SampleLoopLenSet:
    mov [GlobalSample.LoopLen+ebx*4],eax
    ret

.SampleChecksum:
    push ebx
    mov ecx,8
    mov ebx,16
    call StringToNum.UseRLength
    pop ebx
    mov [GlobalSample.Checksum+ebx*4],eax
    ret

.SamplePitch:
    jc .SamplePitchNull
    push ebx
    call StringToNum
    pop ebx
    cmp eax,MaxHertz
    jbe .SamplePitchSet
    mov eax,MaxHertz
    jmp short .SamplePitchSet
.SamplePitchNull:
    mov eax,[GlobalSample.Freq]
.SamplePitchSet:
    mov [GlobalSample.Freq+ebx*4],eax
    ret

.SampleVolume:
    jc .SampleVolumeNull
    push ebx
    call StringToNum
    pop ebx
    ;cmp eax,???
    jmp short .SampleVolumeSet
.SampleVolumeNull:
    mov eax,[GlobalSample.Volume]
.SampleVolumeSet:
    mov [GlobalSample.Volume+ebx*4],eax
    ret

.SamplePatch:
    jc .SamplePatchNull
    push ebx
    call StringToNum
    pop ebx
    cmp eax,127
    jbe .SamplePatchSet
.SamplePatchNull:
    mov al,[GlobalSample.Instrument]
.SamplePatchSet:
    mov [GlobalSample.Instrument+ebx*4],al
    ret

.SampleDrum:
    jc .SampleDrumNull
    push ebx
    call StringToNum
    pop ebx
    cmp eax,127
    jbe .SampleDrumSet
.SampleDrumNull:
    mov al,[GlobalSample.Instrument+1]
.SampleDrumSet:
    mov [GlobalSample.Instrument+ebx*4+1],al
    ret

.SampleBank:
    jc .SampleBankNull
    push ebx
    call StringToNum
    pop ebx
    cmp eax,16383
    jbe .SampleBankSet
.SampleBankNull:
    mov ax,[GlobalSample.Instrument+2]
.SampleBankSet:
    mov [GlobalSample.Instrument+ebx*4+2],ax
    ret

.SampleFlags:
    ;...
    ret

section data
align 4,db 0
.KeyJtbl:
dd .Version
db -1,0,0,0
dd .Samples
db -1,1,0,0
dd .Games
db -1,1,0,0
dd .SpcFiles
db -1,1,0,0

.ValueJtbl:
dd .SampleIndex
dd .SampleName
dd .SampleLength
dd .SampleLoopLen
dd .SampleChecksum
dd .SamplePitch
dd .SampleVolume
dd .SamplePatch
dd .SampleDrum
dd .SampleBank
dd .SampleFlags

.KeyList:
db 4,7,"Version",7,"Samples",5,"Games",8,"SpcFiles",0
.IniFile:       db "SPC2MIDI.INI",0

section bss
alignb 4
.Index:
.Counter:   resd 1              ;miscellaneous variable
section code

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Constants
;
SettingsFile:
.LineKey        equ 0   ;line of plain text, such as a key=value statement
.LineOpen       equ 1   ;begin key section
.LineClose      equ 2   ;end key section
.LineComment    equ 3   ;comment ";" or blank line

.FileBufferSize equ 200
.MaxLineWidth   equ 82

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Variables
;
section data
align 4,db 0
.FilePos:   dd 0
.BasePos:   dd -1       ;base file buffer position
.NextPos:   dd 0        ;position of next line to read
.BufferEnd: dd 0        ;total bytes in buffer
.LineNum:   dd 0        ;current line in file
.Indent:    dd 0        ;parenthesis level
.SrcFileHnd:dd 0        ;file handle read from
;.DestFileHnd:dd 0        ;file handle written to

;.ClosingBracket: db "}",13,10

;------------------------------
section bss
alignb 4
.FileBufferIn:      resb .FileBufferSize+2 ;(two extra bytes for cr/lf)

section code

;==============================
; Routines
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; (edx=filename ptr) (cf=error)
.OpenRead:
    ; open file
%ifdef DosVer
    mov eax,3D00h | 10100000b   ;open for read with only read sharing
    int 21h
    jc .OpenError
%elifdef WinVer
    xor eax,eax
    api CreateFile, edx, GENERIC_READ,FILE_SHARE_READ, eax, OPEN_EXISTING, eax,eax
    cmp eax,INVALID_HANDLE_VALUE
    stc
    je .OpenError
%endif
    mov [SettingsFile.SrcFileHnd],eax ;save returned file handle
.RestartRead:
    xor eax,eax
    mov [.FilePos],eax
    mov [.BasePos],dword -1
    mov [.NextPos],eax
    mov [.LineNum],eax
    mov [.Indent],eax
    ;clc (XOR clears cf)
.OpenError:
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
%if 0
.OpenWrite:
Upon open:
%ifdef DosVer
    mov eax,3D00h | 10100000b   ;open for read with only read sharing
    int 21h
    jc .OpenError
%elifdef WinVer
    xor eax,eax
    api CreateFile, esi, GENERIC_WRITE,FILE_SHARE_READ, eax, OPEN_ALWAYS, eax,eax
    cmp eax,INVALID_HANDLE_VALUE
    stc
    je .OpenError
%endif

    mov ah,5Ah
    xor ecx,ecx
    dx=temp path

    open source file, read
    create destination file, write
    merge original file to temp file


.CloseWrite:
Upon close:
    mov ah,40h
    xor ecx,ecx

    truncate original file to current position
    close original file
    delete temp file

    mov ah,68h                  ;flush buffer
    bx=handle
    int 21h

%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Read Line from Settings File
; () (esi=text line, eax=type)
;
; Reads the next line in the source file, and returns a ptr to the first
; nonspace character of text and the type of line, whether a key, opening
; bracket, closing bracket, comment, or empty line.
;
; Every call to this function moves the file ptr to the following line.
; Calling it after reaching the end of file only returns closing brackets.
; For each leve of indentation, it adjust SettingsFile.Indent accordingly.
;
; if next file position < base position
;   complete buffer refill (buffersize)
; elif file position - base position >= buffersize
;   complete buffer refill (buffersize)
; elif next file position - base position > buffersize - maxlinewidth
;   else
;     adjust buffer
;     partial buffer refill (position - base)
;   endif
; (else already in buffer)
; endif
; buffer offset = file position - base position
; if buffer offset >= buffer end then return line close
; search for cr/lf and set NextPos to offset + 2
; search for first nonspace character and return address
;
.ReadLine:
    ; check that next line is within buffer, refill if not
    cld
    mov eax,[.NextPos]
    mov ebx,[.SrcFileHnd]       ;get file handle
    sub eax,[.BasePos]          ;(FilePos - BasePos)
    jb .RlRefill                ;file position is before base, complete refill
    cmp eax,.FileBufferSize-.MaxLineWidth
    jb near .RlInBuffer         ;line is already in buffer
    cmp eax,.FileBufferSize     ;FilePos - BasePos > BufferSize ?
    jae .RlRefill               ;file position far after base, complete refill
    cmp dword [.BufferEnd],.FileBufferSize ;do not read past end of buffer
    jb .RlInBuffer
    mov ecx,.FileBufferSize
    lea esi,[.FileBufferIn+eax] ;otherwise adjust the bytes already in the
    sub ecx,eax                 ;bytes to move = buffer size - old bytes
    mov edi,.FileBufferIn       ;towards the front
    push ecx
    rep movsb                   ;shift old text down towards front of buffer
    pop edi                     ;retrieve buffer offset
    mov ecx,eax                 ;bytes to read = buffer size - old bytes
    add [.BasePos],eax
    jmp short .RlReadFile

  .RlRefill: ; set file position (eax=offset in buffer, ebx=file handle)
    mov edx,[.NextPos]
    mov [.BasePos],edx
   %ifdef DosVer
    shld ecx,edx,16             ;upper word into cx
    mov eax,4200h               ;get/set file position
    int 21h
   %elifdef WinVer
    api SetFilePointer, ebx, edx,NULL,FILE_BEGIN
   %endif
    ; read new bytes
    xor edi,edi                 ;start at front of buffer for full refill
    mov ecx,.FileBufferSize     ;length = buffer size - old bytes

  .RlReadFile: ; (ebx=file handle, edi=buffer offset, ecx=bytes to read)
    lea edx,[.FileBufferIn+edi] ;dest = buffer start + old bytes
   %ifdef DosVer
    mov ah,3Fh                  ;DOS: Read file
    int 21h
   %elifdef WinVer
    api ReadFile, ebx,edx, ecx,dummy, NULL
    mov eax,[dummy]
   %endif
    ; set buffer size to bytes actually read (if less than BufferSize)
    add eax,edi                 ;total buffer size = old bytes + new bytes
    mov [.BufferEnd],eax
    mov word [.FileBufferIn+eax],0A0Dh ;append cr/lf in case end of file does not have one
    xor eax,eax                 ;buffer offset = 0
 
  .RlInBuffer: ; (eax=offset in buffer)
    cmp [.BufferEnd],eax        ;do not read past end of buffer
    ja .RlNotBfrEnd
    mov eax,.LineClose          ;return Close if tried
    dec dword [SettingsFile.Indent]
    ret
  .RlNotBfrEnd:

    ; search for first nonspace character to return ptr in esi
    lea edi,[.FileBufferIn+eax]
    mov ecx,.MaxLineWidth
    mov al,32
    repe scasb                  ;find first nonspace character
    dec edi
    mov esi,edi
    ; search for cr/lf
    mov al,13                   ;find end of line
    repne scasb
    mov byte [edi-1],0
    ; set both current and next file position
    sub edi,.FileBufferIn-1     ;+2 for the cr/lf, -1 for overshot by scasb
    mov ebx,[.NextPos]
    add edi,[.BasePos]
    mov [.FilePos],ebx
    mov [.NextPos],edi
    inc dword [.LineNum]

    ; determine line type and return value
    mov bl,[esi]                ;get first nonspace character on line
    cmp bl,'{'
    jne .RlNotOpen
    mov eax,.LineOpen
    inc dword [.Indent]
    ;jmp short .RlTypeFound
    ret
  .RlNotOpen:
    cmp bl,'}'                  ;check if close
    jne .RlNotClose
    mov eax,.LineClose
    dec dword [.Indent]         ;indent may go negative
    ;jns .RlTypeFound
    ;mov dword [.Indent],0       ;don't allow indent to go negative
    ;jmp short .RlTypeFound
    ret
  .RlNotClose:
    mov eax,.LineComment
    cmp bl,';'                  ;check if comment
    je .RlTypeFound
    cmp bl,13                   ;check if blank line
    jbe .RlTypeFound
    xor eax,eax                 ;else must be a key
    ;mov eax,.LineKey
  .RlTypeFound:

    ;pusha
    ;mov edx,[.TypeMsgs+eax*4]
    ;mov ebx,[.Indent]
    ;add bl,'0'
    ;mov [edx],bl
    ;mov ah,9
    ;int 21h
    ;popa

    ret

;.TypeMsgs:
;dd .MsgKey,.MsgOpen,.MsgClose,.MsgComment
;.MsgKey:     db "# Key",13,10,"$"
;.MsgOpen:    db "# Open",13,10,"$"
;.MsgClose:   db "# Close",13,10,"$"
;.MsgComment: db "# Comment",13,10,"$"


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Read Keys
; (function table ptr, keyname list ptr) ()
;
; Given a list of keys to find and function table, it will read a section of
; a setting file, calling the appropriate functions for each key. The keyname
; list is simply a list of strings preceded by a length byte. The function
; table consists of the function address, index of any other key dependancies,
; and a flag specifying if the key expects a sublevel.
;
; table format:
;   dd FunctionPtr
;   db KeyDependancy    (-1 if none)
;   db ExpectsSublevel  (1 if expects key, 0 if value)
;   db 0,0              (alignment)
;
; When a key function is called, it can safely assume that any other keys it
; depends have already been called. If it is a value, esi points to first
; byte after the equal sign. If it is a key, NextLine points to the first
; line in the file after the opening line. ReadLine must then be called to
; read the following lines as many times as needed, until the function
; reaches the section closing bracket and returns.
;
; Regs passed to key function: (eax=key index, esi=character ptr)
;
; Game="Zelda"
;       esi points here for value
; Settings
; {
;   0="Harp",0,69,8...
;    NextLine points here for key
;
; Although this routine works most efficiently when all the keys are
; sequential (so that only a single pass is needed), it is able to handle
; keys out of sequence by doing multiple passes. This only necessary when a
; key depends on another key farther in the file. The total number of keys
; per section are limited to 32, since it uses dword bit flags. Do not pass
; it any keys with circular references (which would be dumb anyway) because
; it is not written to detect such complexity and will loop infinitely ;-)
;
; set all keys as unread
; set last key read to zero
; do
;  .ReadNextLine:
;   read next line
;   loop if file parenthesis level > desired level
;  .LineJustRead:
;   if a key was read (whether single line equate or section key)
;     search through table for key name match
;     if no matching keyname then goto skip all subkeys
;     if key was already called then goto skip all subkeys
;     flag key as read
;     if key is dependant on another key not already called
;       (come back to it later)
;       if file position not already set to a previous key
;         save file position, line number, indent
;       endif
;       goto skip all subkeys          
;     else
;       (call the appropriate function)
;       goto call key handler
;     endif
;
;     flag key as called
;     if section key
;       do
;         read next line
;       loop until not comment
;       if not opening parenthesis then set error
;     else value
;       find equal sign
;       if none found then set error
;     endif
;     call key function
;     goto read next line
;
;   elif opening parenthesis (unexpected)
;     goto skip all subkeys
;
;   elif comment or blank
;     ignore and loop, goto .ReadNextLine
;
;   else closing parenthesis or anything else
;     do until all handlers called
;       call handler for any keys not found
;       flag key as being called
;     loop
;     if predependant keys remain then
;       restore current key, file location, line number
;     else
;       return
;     endif
;   endif
; loop

.ReadKeys:

;certain code depends on these variables being in this order
.RkStkList      equ 12          ;string list of keynames
.RkStkJtbl      equ 8           ;function table
.RkStkRead      equ -4          ;keys remaining to be read
.RkStkCall      equ -8          ;keys to call yet, all keys are done when zero
.RkStkIndent    equ -12
.RkStkLine      equ -16
.RkStkFilePos   equ -20

    ; set all keys unread, all keys uncalled, no dependant key position
    push ebp
    mov ebp,esp
    mov ebx,[ebp+.RkStkList]    ;get ptr to key list
    mov eax,1
    mov cl,[ebx]                ;get total entries in list
    shl eax,cl                  ;1 << total keys
    dec eax                     ;set bits for all keys
    push dword eax              ;keys to read
    push dword eax              ;keys to call
    push dword [.Indent]        ;save current level of indent
    push dword [.LineNum]       ;save current line number
    push dword -1               ;default dependant key file position (none)

    ;do
    ;  if comment or blank
    ;    ignore and loop, goto .ReadNextLine
    ;

.RkNextLine:
    call .ReadLine
.RkLineRead:
    mov edx,[ebp+.RkStkIndent]
    cmp [.Indent],edx
    jg .RkNextLine              ;inside subkey so loop
    jl near .RkClose            ;moved outside current section
    cmp al,.LineKey             ;just read next key
    jne .RkNextLine             ;loop while comment or opening parenthesis

.RkKey:
    ; find length of key, up to end of line or equal sign
    cld
    push esi
    xor edx,edx
  .RkFindKeyLen:
    lodsb
    inc edx
    cmp al,'='
    je .RkFoundKeyLen
    cmp al,32
    ja .RkFindKeyLen
  .RkFoundKeyLen:
    pop esi
    dec edx
    jz near .RkNextLine     ;key name was null

    ; search through table for match, the index will be in eax if found
    xor ecx,ecx
    mov ebx,[ebp+.RkStkList] ;get ptr to keyname list
    inc ebx                 ;skip total keynames byte
    mov eax,-1              ;initial key index (none found)

  .RkNextCompare:
    mov cl,[ebx]            ;get string length
    inc ebx                 ;point to first character in keyname
    inc eax                 ;next index
    mov edi,ebx
    add ebx,ecx             ;advance next key in list
    cmp ecx,edx
    jne .RkDifLen
    repe cmpsb
    je .RkMatch
    add esi,ecx             ;compensate for change in esi after search
    sub esi,edx             ;restore esi to beginning of text
    jmp short .RkNextCompare
  .RkDifLen:
    test ecx,ecx
    jnz .RkNextCompare      ;loop while more strings to compare with
    jmp .RkNextLine         ;no match was found

  .RkMatch:
    ; (esi=ptr to end of keyname, eax=index)
    bt dword [ebp+.RkStkCall],eax
    jnc near .RkNextLine    ;skip if key has already been called
    mov ebx,[ebp+.RkStkJtbl]
    lea ebx,[ebx+eax*8]
    btr dword [ebp+.RkStkRead],eax ;clear unread flag
    mov cl,[ebx+4]          ;get dependant key (ecx is still zero)
    test cl,cl
    js .RkCallKey           ;no key dependancy if -1
    bt dword [ebp+.RkStkCall],ecx
    jnc .RkCallKey          ;depended key already called

    ; key is dependant on another that has not been read yet
    ; so store its file position and come back to it later
    cmp dword [ebp+.RkStkFilePos],-1
    jb near .RkNextLine     ;already dependant on a previous key
    add esp,byte 8
    push dword [.LineNum]
    push dword [.FilePos]   ;save file position, line number, indent
    jmp .RkNextLine

  .RkCallKey:
    ; (ebx=table ptr, eax=index of matching key,
    ;  esi=first character after keyname)

    btr [ebp+.RkStkCall],eax
    test byte [ebx+5],1
    jnz .RkCallSubkey

    inc esi
    cmp byte [esi-1],"="
    je .RkCallOk
    stc
    call dword [ebx]
    jmp .RkNextLine

  .RkCallSubkey:
    push eax
    push ebx
  .RkCallNext:
    call .ReadLine
    cmp al,.LineComment         ;skip any comments between key and opening
    je .RkCallNext
    cmp al,.LineOpen            ;if anything besides opening parenthesis was
    pop ebx                     ;read, then call handler with error, and jump
    je .RkCallValueOk           ;back to main loop, just before comparison
    xchg [esp],eax              ;swap line type with key index
    push esi                    ;save character ptr for next line
    stc
    call [ebx]
    pop esi
    pop eax                     ;restore line type
    jmp .RkLineRead

  .RkCallValueOk:
    pop eax                     ;retrieve key index
  .RkCallOk:
    clc
    call dword [ebx]
    jmp .RkNextLine


.RkClose:
    ; call any keys that still need to be called but were not encountered
    ; while reading through the file
    mov edx,[ebp+.RkStkCall]
    and edx,[ebp+.RkStkRead]
    jz .RkCloseNoKeys
    xor [ebp+.RkStkCall],edx

    xor eax,eax                 ;start with first index
    jmp short .RkCloseFirst
  .RkCloseCall:
    mov ebx,[ebp+.RkStkJtbl]
    push eax
    push edx
    stc
    call dword [ebx+eax*8]
    pop edx
    pop eax
  .RkCloseNext:
    inc eax
  .RkCloseFirst:
    shr edx,1                   ;test flags for nonexistant keys
    jc .RkCloseCall
    jnz .RkCloseNext

  .RkCloseNoKeys:
    cmp dword [ebp+.RkStkFilePos],-1
    je .RkEnd
    mov eax,[ebp+.RkStkIndent]
    pop dword [.NextPos]        ;restore file position, line number, indent
    pop dword [.LineNum]
    mov [.Indent],eax           ;reset indent to section level
    push eax                    ;push dummy line number
    push dword -1               ;default dependant key file position (none)
    jmp .RkNextLine

.RkEnd:
    mov esp,ebp
    pop ebp
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Read Values
; (function table ptr, bit table ptr, dword total keys, dword items per line
;  ebp=optional function stack parameters)
; ()
;
; Given a bit table of numbered keys and function table, it will read a
; section of values, parsing each comma delimited line item and calling the
; corresponding function for it. The bit table has at least as many bits as
; the maximum keys, and may or may not contain bits already set. Items is
; how many items are expected on each line (including the key number). If a
; line has more values than expected, the trailing items are ignored. If it
; contains fewer, the remaining value functions are called with cf set
; indicating null.
;
; do until close
;   read line
;   loop if comment or nested level
;   exit loop if close
;   convert string to key number
;   if not null
;   and next character is equal sign
;   and not already called (check bit table)
;   and key number in range
;     call key number function
;     initial count = 1
;     do until count > max
;       if value starts with quote
;         skip quote
;         determine length up to ending quote (or end of line)
;         skip to comma
;       else
;         determine length up to next comma (or end of line)
;       endif
;       call key function
;       find next parameter
;       exit loop if no more found
;     loop
;   endif
; loop
;
; Parameters passed to the functions:
;   Key number function
;     (eax=key number)
;   Value function
;     (ebx=key number, esi=first character,
;      ecx=string length, cf=null)
;
; C equivalent:
;   int RvIndent=Indent;
;   do
;       ReadLine();
;   loop while
;   (  Indent > RvIndent
;   || Type != LineKey
;   || (Index=StringToNum(&CharPtr)) <= -1
;   || *CharPtr++ != '='
;   || Index= > MaxKeys
;   || CalledKeys[Index]
;   )
;
;   if (Indent < RvIndent) return;
;
;   CalledKeys[Index] = 1;
;   *RvJtbl[0]();
;   ...
;
; If a value is null (in other words, nothing between two commas or perhaps
; omitted entirely), ecx is zero and cf is set. esi is unknown.

.ReadValues:

.RvStkIndex     equ 0           ;index number of current line
.RvStkIndent    equ 4           ;indent level
.RvStkJtbl      equ 12          ;function table
.RvStkCalled    equ 16          ;bit table indicating keys called already
.RvStkKeys      equ 20          ;total keys allowed
.RvStkItems     equ 24          ;values expected per line, includes index

    push dword [.Indent]        ;save current level of indent
    push eax                    ;push dummy dword for index

.RvNextLine:
    call .ReadLine
.RvLineRead:
    mov edx,[esp+.RvStkIndent]
    cmp [.Indent],edx
    jg .RvNextLine              ;inside subkey so loop
    jl near .RvClose            ;moved outside current section
    cmp al,.LineKey             ;just read next key
    jne .RvNextLine             ;loop while comment or opening parenthesis

    call StringToNum
    jz .RvNextLine              ;invalid number
    cmp byte [esi],'='          ;check that next character after number is an
    jne .RvNextLine             ;equal sign
    mov ebx,[esp+.RvStkCalled]
    cmp [esp+.RvStkKeys],eax
    jbe .RvNextLine             ;key number > max key number
    bts [ebx],eax
    jc .RvNextLine              ;key already been called
    inc esi
    mov ebx,[esp+.RvStkJtbl]
    mov [esp+.RvStkIndex],eax   ;store index number for later value calls
    push esi
    call [ebx]                  ;call key number function (index 0)
    pop esi

    ; top of line value loop
    mov edx,1                   ;start at first value function (index 1)
.RvNextValue:
    cmp [esp+.RvStkItems],edx   ;current index >= total indexes?
    jbe .RvNextLine

    ; skip all spaces
.RvNextChar:
    lodsb
    cmp al,' '
    je .RvNextChar              ;skip space
    jb .RvEol                   ;control character so end of line
    cmp al,'"'
    jne .RvNoQuote              ;unquoted string

    ; find length of quoted string
    mov ecx,-1                  ;set initial count
    mov edi,esi
.RvQuoteNext:
    inc ecx                     ;count another character
    lodsb
    cmp al,32                   ;exit loop if control character,
    jb .RvLenFound              ;end of line came before ending quote
    cmp al,'"'
    jne .RvQuoteNext            ;loop until ending quote is found

    ; skip to next comma (or end of line)
.RvQuoteNextComma:
    lodsb
    cmp al,32                   ;exit loop if control character,
    jb .RvLenFound              ;end of line came before ending quote
    cmp al,','
    jne .RvQuoteNextComma       ;loop until separating comma is found
    jmp short .RvLenFound

    ; find length of unquoted string
.RvNoQuote:
    xor ecx,ecx
    lea edi,[esi-1]
    jmp short .RvNoQuoteComma
.RvNoQuoteNext:
    inc ecx
    lodsb
    cmp al,32                   ;exit loop if control character,
    jb .RvLenFound              ;end of line came before separating comma
.RvNoQuoteComma:
    cmp al,','
    jne .RvNoQuoteNext

    ; length found, ready to call function
    ; (ecx=value length, edx=value index, esi=char ptr, edi=passed char ptr)
.RvLenFound:
    mov eax,[esp+.RvStkJtbl]
    mov ebx,[esp+.RvStkIndex]   ;get index number of current line
    push esi                    ;save char ptr
    push edx                    ;save current value column (which item)
    mov esi,edi
    cmp ecx,1                   ;indicate to function that value is null
    call dword [eax+edx*4]      ;if ecx=0 by setting cf
    pop edx
    pop esi
    inc edx                     ;next line item
    cmp byte [esi-1],32         ;< space ?
    jae near .RvNextValue       ;loop while not end of line (not control char)

    ; reached end of line so call all remaining value functions with null
    ; (edx=value index, esi=char ptr)
.RvEol:
    cmp [esp+.RvStkItems],edx
    jbe near .RvNextLine
    mov eax,[esp+.RvStkJtbl]
    mov ebx,[esp+.RvStkIndex]   ;get index number of current line
    xor ecx,ecx                 ;zero length value
    push edx                    ;save current value column (which item)
    stc                         ;indicate value is null
    call dword [eax+edx*4]
    pop edx
    inc edx
    jmp short .RvEol

.RvClose:
    add esp,byte 8              ;discard index and indent level
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Clear Numbered Keys
; (dummy function table ptr,
;  bit table ptr,
;  dword total keys,
;  dummy dword values per line)
; ()
;
; Given a bit table of numbered keys and the total keys in it, this function
; clears all the bits flags, indicating nothing loaded is those entries.
; The parameters are exactly the same as ReadValues so that this function
; can be called immediately before ReadValues without duplicating stack
; variables. Technically the function table ptr and values per line can be
; dummy values since they are not used.
;
.ClearNumberedKeys:
    cld
    mov ecx,[esp+12]            ;get total keys in bit table
    mov edi,[esp+8]             ;bit table is destination
    xor eax,eax
    shr ecx,3                   ;Bytes = Total Keys/8
    rep stosb
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Copy String
; (esi=source, edi=destination, ecx=source length, edx=destination max)
; (eax=characters copied)
;
; Copies a string of a specified length to an AsciiZ buffer, limiting it to
; the destination's space.
;
.CopyString:
    cmp ecx,edx
    jb .CsOk                    ;source is shorter than destination
    dec edx                     ;subtract 0 byte at string end
    js .CsNull
    mov ecx,edx
.CsOk:
    cld
    mov eax,ecx
    rep movsb
.CsEnd:
    mov byte [edi],0
    ret
.CsNull:
    xor eax,eax
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; Copy Control String
; (esi=source, edi=destination, ecx=source length, edx=destination max)
; (eax=characters copied, esi=last source char, edi=last dest char; none)
;
; Copies a string of a specified length with control characters to an AsciiZ
; buffer, limiting it to the destination's space.
;
.CopyControlString:
    dec edx                     ;subtract 0 byte at string end
    push edi
    jle .CcsEnd
    test ecx,ecx
    jle .CcsEnd
.CcsNext:
    lodsb
    cmp al,'\'
    jne .CcsWrite
    lodsb
    cmp al,'a'
    jb .CcsWrite
    sub al,'a'
.CcsWrite:
    stosb
    dec edx
    jle .CcsEnd
.CcsFirst:
    dec ecx
    jg .CcsNext
.CcsEnd:
    pop eax
    sub eax,edi
    mov byte [edi],0
    neg eax
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
%if 0
    set all keys as unread and needs written status accordingly
    goto readnext
    do
      if closing parenthesis then exit loop
      if comment or blank then transfer line, goto readnext
      if not matching keyname then transfer key and all subkeys, loop
      if unexpected opening parenthesis then transfer all subkeys, loop

      if key was already written then skip key and all subkeys, loop
      if key comes before another key which should needs to be written first
        save current key and file location
        search for necessary key
        if not found
          call close handler
        else
          pass value to key
        retrieve current key and file location
      else pass value to key
readnext:
      read next line
      goto noread:
    loop
    call close handlers for remaining unwritten keys
    return file position

pass value to key:
    if key needs to be rewritten
      if single line then pass value to key handler
      elseif parent key
        if next line is not opening parenthesis then ignore
        else pass file location calling key handler
    else
      transfer key and any subkeys
    mark key as written
    return

transfer subkeys only:
    set parenthesis level to 1
transfer all subkeys:
    write line
    read next line
    if opening parenthesis then increment parenthesis level
    if closing parenthesis
      decrement parenthesis level
      if parenthesis level <= 0 return
    if text and parenthesis level <= 0 then return

.WriteLine:
; (esi=text line) ()
; Writes a line of text to the destination file using the current indentation.
.WriteBracket:
; (eax=bracket type)
; Writes either an opening or closing bracket to the destination file.
.GetKey:
; (esi=text source ptr, edi=dest ptr, ecx=max dest length) (ecx=key length)
; Returns key name before equal sign. Text is converted.
.GetData:
; (esi=text source ptr, edi=dest ptr, ecx=max dest length) (ecx=data length)
; Converts a line of 7bit encoded data from text back into 8bit data.
.GetNameIndex:
; (esi=key name ptr, ebx=list base) (eax=index, cf=error)
; Returns the index (0-??) of a text key name in a list.
.GetIndexName:
; (eax=index, ebx=list base) (esi=key name ptr, cf=error)
; Returns the text key name in a list given an index (0-??).

LoadAllSettings:

LoadSettings:
;open settings file - return if error
;
;read line
;if comment, ignore
;if expected subkeys not encountered, call close handler for current routine, clear opening expected
;if unexpected opening bracket, ignore all lines inside
;if expected opening bracket, clear opening expected, read next line
;.SectionRoutine

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
SaveSettings:
;create temporary output file - return if error
;open settings file - if error, call close handler, jump down
;
;read line
;if comment, ignore and pass line through
;if (opening bracket) or (subkey expected and line is not opening bracket)
;  write opening bracket
;  clear subkey expected
;  if not opening bracket
;    call close handler
;    write closing bracket
;elif current routine
;elif unexpected opening bracket, ignore and pass all lines through
;else closing bracket
;  call close handler
;  clear subkey expected
;  write closing bracket
;close settings file
;close output file
;delete old settings file
;rename output file to settings file
;.SectionRoutine

    cmp al,SettingsFile.Comment
    jne .NoComment
    call SettingsFile.WriteLine
    jmp ...
.NoComment:

    cmp al,SettingsFile.Opening
    je .NotOpening
    test dword [.Options],.SubkeyExpected
    jnz .OpeningExpected
  ; in case of unexpected opening bracket
    cmp [.UnexpectedLevel],0
    ja .AlreadyUnexpected
    push [.KeyHandler]
    mov [.KeyHandler],.UnknownKeyHandler
.AlreadyUnexpected:
    inc [.UnexpectedLevel]
.OpeningExpected:
    and dword [.Options],~.SubkeyExpected
    call SettingsFile.WriteOpeningBracket
    jmp ...
.NotOpening:

    test dword [.Options],.SubkeyExpected
    jz .NoOpeningExpected
    push eax
    call SettingsFile.WriteOpeningBracket
    call [.CloseHandler]
    call SettingsFile.WriteClosingBracket
    pop eax
.NoOpeningExpected:

    cmp al,SettingsFile.Closing
    jne .NotClosing
    call [.CloseHandler]
    call SettingsFile.WriteClosingBracket
    jmp ...
.NotClosing:

.UnknownKeyHandler:
    call SettingsFile.Write
.StillUnknown:
    ret
.UnknownCloseHandler:
    dec [.UnknownLevel]
    ja .StillUnknown
    pop ebx
    mov [.UnknownLevel],0
    pop [.KeyHandler]
    jmp ebx

.EnterLevel:                    ;save current routine, flags
    pop ebx
    push dword [.KeyHandler]
    push dword [.CloseHandler]
    push dword [.LevelFlags]
    mov [.KeyHandler],  edi
    mov [.CloseHandler],esi
    mov [.LevelFlags],  eax
    or dword [.Options],.SubkeyExpected
    jmp ebx
%endif
