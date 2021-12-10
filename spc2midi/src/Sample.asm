; Spc2Midi - Sample miscellaneous
; Routines related to the global/local sample tables, not really belonging to
; either emulation or simulation.
;
; NewSample.NextFreeIdx
; NewSample.GetNumberedNames
; NewSample.NextNumberedName
; NewSample.CreateName
; MatchLocalSamples
; DumpSoundBuffer
; DumpSoundBuffer.Info
;
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

; Following are a set of functions to help with adding new samples.
;
; Allocates a new sample based on one loaded locally in the current SPC state.
; (dword source directory entry to base from [local sample])
NewSample:

    cmp dword [.NameLcase+1],'wave'
    je .CurrentName
    mov esi,NewSample.DefaultName
    call .GetNumberedNames

.CurrentName:
    call .NextFreeIdx
    jc near .NoneLeft

    mov edi,eax                 ;get sample list index for name ptr
    push eax                    ;save new sample index
    shl edi,GlobalSample.NameShl
    bt [NewSample.NameFlags],eax
    jc .SampleNumForName        ;number is free
    call .NextNumberedName
.SampleNumForName:
    add edi,GlobalSample.Name
    call .CreateName
    pop esi

    mov ebx,[esp+4]
    debugwrite "new gs=%-4d ls=%-3d offset=%08X",esi,ebx,[LocalSample.Offset+ebx*4]
    ;debugwrite "mls drum=%X",[GlobalSample.Instrument]
    push dword [LocalSample.Length+ebx*4]
    push dword [LocalSample.LoopLen+ebx*4]
    push dword [LocalSample.Checksum+ebx*4]
    push dword [LocalSample.Offset+ebx*4]
    push dword [GlobalSample.Volume]
    push dword [GlobalSample.Instrument]
    push dword [GlobalSample.Freq]
    mov  dword [LocalSample.GlobalIdx+ebx*4],esi
    mov  dword [GlobalSample.LocalIdx+esi*4],ebx
    btr  dword [GlobalSample.Cached],esi
    btr  dword [GlobalSample.Disabled],esi
    btr  dword [GlobalSample.Muted],esi ;***
    btr  dword [GlobalSample.Independant],esi
    pop  dword [GlobalSample.Freq+esi*4]
    pop  dword [GlobalSample.Instrument+esi*4]
    pop  dword [GlobalSample.Volume+esi*4]
    pop  dword [GlobalSample.Offset+esi*4]
    pop  dword [GlobalSample.Checksum+esi*4]
    pop  dword [GlobalSample.LoopLen+esi*4]
    pop  dword [GlobalSample.Length+esi*4]
    bts dword [DspFlags],DspFlags.NewVoiceBit
.NoneLeft:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns and allocates the next available sample index. Does not initialize
; the variables for that sample!
;
; ()
; (cf=error-no more samples, eax=sample index; !)
.NextFreeIdx:
    xor esi,esi
    mov ecx,GlobalSample.Max/32 ;(8 bits per byte, 4 bytes per dword)
.NextSample:
    mov edx,[GlobalSample.Used+esi]
    not edx                     ;invert bits, looking for free ones, not used
    bsf eax,edx
    jnz .IdxFound
    add esi,byte 4
    loop .NextSample
    xor eax,eax                 ;return default entry
    stc
    ret
.IdxFound:
    lea eax,[esi*8+eax]
    inc dword [GlobalSample.Entries]
    cmp [GlobalSample.LastEntry],eax
    jae .LastEntrySame
    mov [GlobalSample.LastEntry],eax
.LastEntrySame:
    bts [GlobalSample.Used],eax
    ;clc
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; It's best to name samples according to the instrument they most sound like
; (of course there are plenty of sounds in video games that have absolutely
; no musical equivalent). What do you do though when there are multiple
; variations of the same instrument? Maybe various types type of flute? If
; you know instruments well, you could name them after their real-world types
; (Pan Flute, Wood Flute); but if you're like me, and know music well but not
; necessarily the whole realm of music, it would be easier to simply number
; each instance. This routine helps with that numbering by finding all
; occurences of a specific instrument so that a new number can be returned.
;
; For example, if "Flute", "Flute 2", and "Flute  4" are existing names, the
; next available one is "Flute 3".
;
; Before searching for a free number, it strips the given name of any number
; it may have following.
;   "Flute 2"          >> "Flute ?"
;   "Flute-2"          >> "Flute-?"
;   "Flute #2"         >> "Flute #?"
;   "Flute2"           >> "Flute?"
;   "Flute3 4"         >> "Flute3 ?"
;   "Flute Bright 3"   >> "Flute Bright ?"
;   "Flute Bright   3" >> "Flute Bright ?"
;   "Flute Bright A"   >> "Flute Bright A ?"
;   "23"               >> "?"
;   ""                 >> "?"
;
; When comparing the search name with other names, it is not case sensitive
; but only chooses names that completely match the text portion.
;   "Wood Flute"      yes
;   "Wood Flute    "  yes
;   "Wood Flute 2"    yes
;   "Wood Flute   56" yes
;   "wOoD fLuTe 3"    yes
;   "Wood Flute A"    no
;   "Wood Glock 2"    no
;
; (esi=sample name blen string ptr)
; (!)
.GetNumberedNames:
    ; copy sample name and lowercase second copy
    ; strip sample name of trailing numbers or space
    ; find all samples of same name and record their number in table
    cld
    mov ecx,.MaxFlags/32        ;(32 = 8 bits per byte, 4 bytes per dword)
    mov eax,-1                  ;clear table, filling with all ones
    mov edi,.NameFlags          ;to indicate names are free
    rep stosd
    mov edi,.Name
    mov ecx,GlobalSample.NameSize/4
    rep movsd
    mov esi,.Name
    mov edi,.NameLcase
    mov ecx,GlobalSample.NameSize-2
    movsb                       ;transfer length byte
.NextUpperCase:
    lodsb
    cmp al,'A'
    jb .NotUpperCase
    cmp al,'Z'
    ja .NotUpperCase
    or al,32  ;make lowercase
.NotUpperCase:
    stosb
    dec ecx
    jg .NextUpperCase

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; get name length
    movzx ecx,byte [.Name]
    test ecx,ecx
    jz .SetNameMinLen

    ; ignore any trailing numbers
    mov edx,ecx
.SkipDigits:
    mov al,[.Name+ecx]
    cmp al,'9'
    ja .NoSpace
    cmp al,' '
    je .SkipSpaces
    cmp al,'0'
    jb .NoSpace
    dec ecx
    jg .SkipDigits
    jmp short .SetNameMinLen

    ; if offset = name length
    ;   append space to name
    ; else offset < name length
    ;   assume number is appended directly to end of word
    ; endif
.NoSpace:                       ;number is joined with name
    cmp ecx,edx
    jb .SetNameMinLen
    jmp short .AppendSpace

    ; trim any spaces
    ; loop while offset > 0 && char[offset++] = ' '
.SkipSpaces:
    dec ecx
    jle .SetNameMinLen
    cmp byte [.Name+ecx],' '
    je .SkipSpaces

.AppendSpace:
    cmp ecx,GlobalSample.NameSize-2
    jae .SetNameMinLen
    mov [.NameMinLen],ecx
    inc ecx
    mov byte [.Name+ecx],' '
    jmp short .SetNameLen

.SetNameMinLen:
    mov [.NameMinLen],ecx
.SetNameLen:
    mov edx,GlobalSample.NameSize-2
    mov [.NameLen],ecx
    sub edx,ecx
    mov [.NumLen],edx

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; find all similar sample names and record their numbers in table
    mov edx,GlobalSample.Name
    xor ebx,ebx
.SampleNameNext:
    bt dword [GlobalSample.Used],ebx  ;ensure sample info isn't null junk
    jnc .Mismatch

    ; if compared sample name >= original sample name
    ;   loop while > 0
    ;     if char = 'A'-'Z' make lowercase
    ;     if mismatch break loop
    ;     char ptr++
    ;   endloop
    ;   ...
    mov ecx,[.NameMinLen]
    cmp [edx],cl
    jb .Mismatch
    lea esi,[edx+1]             ;first character after len byte
    mov edi,.Name+1
    jmp short .CompareStart
.CompareNext:
    lodsb
    cmp al,'Z'
    ja .CompareChar
    cmp al,'A'
    jb .CompareChar
    or al,32  ;make lowercase
.CompareChar:
    cmp [edi],al
    jne .Mismatch
.CompareStart:
    dec ecx
    jns .CompareNext

.NameMatch:
    ;   get number from name and clear flag in table
    ;   validation is intermixed with the number conversion
    ;   loop while char is valid
    ;     skip any spaces
    ;     number = number * 10 + char
    ;     char ptr++
    ;   endloop
    ;   if last char was null && flag number < max flags
    ;     clear flag at number
    ;   end if
    xor eax,eax
    xor ecx,ecx
    jmp short .NumStart
.NumAdd:
    imul ecx,10
    add ecx,eax
.NumNext:
    inc esi
.NumStart:
    mov al,[esi]
    sub al,'0'
    cmp al,9
    jbe .NumAdd
    cmp al,' '-'0'
    je .NumNext
    cmp al,-'0'
    jne .Mismatch
    cmp ecx,.MaxFlags
    jae .Mismatch
    btr dword [.NameFlags],ecx

.Mismatch:
    ; endloop while < total sample attribute entries
    inc ebx
    add edx,byte GlobalSample.NameSize
    cmp [GlobalSample.LastEntry],ebx
    jae near .SampleNameNext

    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Search through all flags for a free numbered name. Returns and reserves
; that number.
; ()
; (eax=next free number; edi)
.NextNumberedName:
    xor esi,esi
    mov ecx,.MaxFlags/32 ;(8 bits per byte, 4 bytes per dword)
.NextName:
    mov edx,[.NameFlags+esi]
    bsf eax,edx
    jnz .NameFound
    add esi,byte 4
    loop .NextName
    mov eax,.MaxFlags-1
    jmp short .NoNameFound
.NameFound:
    lea eax,[esi*8+eax]
    btr [.NameFlags],eax
.NoNameFound:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Based on the name passed to NewSampleName, along with a given number, this
; will build the string name.
;
; (edi=blen string dest, eax=number to use)
; ()
.CreateName:
    push edi
    mov ecx,[.NameLen]
    mov esi,.Name+1
    inc edi
    rep movsb

    push edi
    call NumToString
    pop edi
    lea ecx,[NumToString.Buffer+NumToString.DefMaxLen]
    sub ecx,esi
    cld
    cmp [.NumLen],ecx
    jae .NumLenOk
    mov ecx,[.NumLen]
.NumLenOk:
    rep movsb
    xor eax,eax
    mov ecx,edi
    stosb

    pop edi
    sub ecx,edi
    dec ecx
    mov [edi],cl
    ret


section data
.DefaultName:       db 4,"wave",0
section bss
alignb 4
.MaxFlags           equ GlobalSample.Max
.NameFlags:         resb (.MaxFlags+7)/8 ;bit flags telling name free or not
.NameLen:           resd 1      ;significant length of sample name
.NameMinLen:        resd 1      ;minimum length of sample name
.NumLen:            resd 1      ;max string length of number
.Name:              resb GlobalSample.NameSize  ;last used name (blen string)
.NameLcase:         resb GlobalSample.NameSize  ;last used name (blen string)
section code

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Matches BRR samples in the local SPC source directory to any existing
; samples already defined in the global list. New BRR samples (no match found
; in the global list) are added to it with default attributes.
;
; Matching samples is necessary because of how often games have entries in
; their source directory that point to the exact same sound. Gs Mikami is
; good example of this. The first four are all the same sample. Then the next
; four all point to another sample. Without this matching, you would get
; eight samples from above, when really there were only two.
;
; This function is called upon after loading an SPC state. A subfunction of
; it is called after a key on for any new samples.
;
; () ()
MatchLocalSamples:
    ret;****
    cmp byte [DspRam+DspReg.SourceDirectory],0
    ja .ValidSrcDir             ;check only if samples exist
    ret
.ValidSrcDir:

    mov esi,Text.IdentifyingSamples
    call StatusMessage

; match all samples in the global list to any duplicates in the local list (BRR source directory)
    mov esi,1                   ;start at sample 1 (skipping default)
.NextSample:
    bt dword [GlobalSample.Used],esi  ;ensure sample info isn't null junk
    jnc .NullSample
    mov eax,[GlobalSample.Checksum+esi*4]
    mov ecx,[GlobalSample.Length+esi*4]
    mov edx,[GlobalSample.LoopLen+esi*4]
    mov dword [GlobalSample.LocalIdx+esi*4],-1

    ; count negative (255-0) so that the lowest BRR number will be
    ; pointed to in the sample's BRR index
    mov ebx,255
.NextBrr:
    cmp [LocalSample.Checksum+ebx*4],eax
    jne .Mismatch
    cmp [LocalSample.Length+ebx*4],ecx
    jne .Mismatch
    cmp [LocalSample.LoopLen+ebx*4],edx
    jne .Mismatch

    ; BRR sample matched sample from list
    ; make both point to each other, sample to BRR, BRR to sample
    mov edi,[LocalSample.Offset+ebx*4]
    mov [GlobalSample.LocalIdx+esi*4],ebx
    mov [LocalSample.GlobalIdx+ebx*4],esi
    mov [GlobalSample.Offset+esi*4],edi
    debugwrite "old gs=%-4d ls=%-3d offset=%08X",esi,ebx,edi

    ; if a BRR sample matches one from the global sample list, it must be
    ; valid, so mark it accordingly
    ;bts [LocalSample.Valid],esi

.Mismatch:
    dec ebx                     ;local sample--
    jns .NextBrr

.NullSample:
    inc esi                     ;global sample++
    cmp [GlobalSample.LastEntry],esi
    jae near .NextSample

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create names and default attributes for any new samples.
;
; Called after the key on of a new sample.
; Loading a new SPC also falls through to here.
.New:
    mov esi,NewSample.DefaultName
    call NewSample.GetNumberedNames

    xor ebx,ebx                 ;start local sample 0 (first source dir entry)
.NextNewBrr:
    ; if valid sample && no global index
    bt [LocalSample.Valid],ebx
    jnc near .SkipSample
    cmp dword [LocalSample.GlobalIdx+ebx*4],0
    jg near .SkipSample

    push ebx
    call NewSample.CurrentName
    pop ebx

    ; check for duplicate local entries
    mov esi,[LocalSample.GlobalIdx+ebx*4]
    mov eax,[LocalSample.Checksum+ebx*4]
    mov ecx,[LocalSample.Length+ebx*4]
    mov edx,[LocalSample.LoopLen+ebx*4]
    mov edi,ebx
    jmp short .StartDupCheck
.NextCheckDupBrr:
    cmp [LocalSample.Checksum+edi*4],eax
    jne .NotDup
    cmp [LocalSample.Length+edi*4],ecx
    jne .NotDup
    cmp [LocalSample.LoopLen+edi*4],edx
    jne .NotDup
.StartDupCheck:
    ; another BRR sample matched sample from list
    mov [LocalSample.GlobalIdx+edi*4],esi
.NotDup:
    inc edi                     ;local sample++
    cmp edi,256
    jb .NextCheckDupBrr

.SkipSample:
    inc ebx                     ;main local sample++
    cmp ebx,256
    jb .NextNewBrr
.NoMoreSamples:

    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Exports cached sample buffer to wave file.
;
; () ()
DumpBrrBuffer:
    ; clear sample buffer and decompress all valid samples
    cld
    mov edi,SamplesBuffer
    mov ecx,SamplesBufferSize/4
    xor eax,eax
    rep stosd
    call DecompressLocalSamples

    mov esi,Text.ExportBrrBuffer
    call StatusMessage

    ; create file and export wave
%ifdef DosVer
    mov ah,3Ch                  ;DOS: Create file
    xor ecx,ecx                 ;no attributes
    mov edx,SoundDumpFileName
    int 21h
    jc .FileError
    mov ebx,eax
    mov edx,SoundDumpHeader
    mov ecx,SoundDumpHeader.Size
    mov ah,40h                  ;DOS: Write to file
    int 21h
    mov edx,SamplesBuffer
    mov ecx,SamplesBufferSize
    mov ah,40h                  ;DOS: Write to file
    int 21h
    mov ah,3Eh                  ;DOS: Close file
    int 21h
%else
    xor eax,eax
    api CreateFile, SoundDumpFileName, GENERIC_WRITE,FILE_SHARE_READ, eax, OPEN_ALWAYS, eax,eax
    cmp eax,INVALID_HANDLE_VALUE
    je .FileError
    mov ebx,eax
    api WriteFile, ebx,SoundDumpHeader,SoundDumpHeader.Size, dummy,NULL
    api WriteFile, ebx,SamplesBuffer,SamplesBufferSize, dummy,NULL
    api CloseHandle, ebx
%endif
.FileError:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Writes info about each sample to screen (can be redirected to file)
;
; () ()
.Info:
    mov edx,Text.SampleInfoTitles
    call WriteString

    xor ecx,ecx
.NextSampleInfoLine:
    push ecx

    mov eax,'    '
    bt [LocalSample.Played],ecx
    jnc .Unused
    mov ah,'p'
.Unused:
    bt [LocalSample.Valid],ecx
    jnc .Invalid
    mov al,'v'
.Invalid:
    mov [Text.SampleInfo+20],ax

    push dword [LocalSample.GlobalIdx+ecx*4]
    push dword [LocalSample.Checksum+ecx*4]
    push dword [LocalSample.LoopLen+ecx*4]
    push dword [LocalSample.Length+ecx*4]
    push dword [LocalSample.Offset+ecx*4]

    mov eax,ecx                 ;sample number
    mov edi,Text.SampleInfo
    mov ecx,3
    call NumToString.UseDLen

    movzx eax,word [esp]        ;sample offset
    mov edi,Text.SampleInfo+7
    mov ecx,5
    call NumToString.UseDLen

    pop eax                     ;loop offset
    shr eax,16
    mov edi,Text.SampleInfo+13
    mov ecx,5
    call NumToString.UseDLen

    pop eax                     ;sample length
    mov edi,Text.SampleInfo+24
    mov ecx,5
    call NumToString.UseDLen

    pop eax                     ;loop length
    mov edi,Text.SampleInfo+30
    mov ecx,5
    call NumToString.UseDLen

    pop eax                     ;checksum
    mov edi,Text.SampleInfo+37
    mov ecx,32                  ;bits
    call MakeHexNum

    pop esi
    cld
    mov edx,30
    mov edi,Text.SampleInfo+47
    shl esi,GlobalSample.NameShl
    jle .NoSampleName
    add esi,GlobalSample.Name
    movzx ecx,byte [esi]
    inc esi
    sub edx,ecx
    ja .NameLenOk
    add ecx,edx
    xor edx,edx
.NameLenOk:
    rep movsb
.NoSampleName:
    mov dword [edi],0A0Dh
    ;mov al,' '
    ;mov ecx,edx
    ;rep stosb

    mov edx,Text.SampleInfo
    call WriteString
    pop ecx
    inc cl
    jnz near .NextSampleInfoLine
    ;inc ecx ;**** show only first 16
    ;cmp ecx,16
    ;jb near .NextSampleInfoLine
    ret
