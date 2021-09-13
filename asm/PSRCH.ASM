BITS 32				;flat addressing is great!
GLOBAL _WDOSXStart		;great (free!) extender

%define ProgVersion '0.01'

FileBufferSize equ 512*8+256	;eight and a half disk clusters
PatternMaximumLength equ 32

_WDOSXStart:
	mov [StartOptions.Count],esi	;save the number of parameters,
	mov [StartOptions.Ptrs],edi	;array of pointers to each one,
	mov [StartOptions.Env],ebp	;command environment strings,
	mov [StartOptions.Selector],es	;and lastly its selector
	push ds				;save data segment
	pop es				;copy to extra segment

;	mov ah,3		;function to get cursor type
;	int 10h			;call video BIOS
;	mov [ScreenCursorType],cx	;save for later restoration
	mov eax,103h		;function to set cursor type in text mode
	mov ecx,2000h		;value to disable (hide) cursor
	int 10h			;call video BIOS

	call GetStartOptions

	mov ax,3E00h		;function to close file
	mov bx,[File.Handle]	;get file's handle
	int 21h			;call DOS

ProgramEnd:
	mov eax,103h		;function to set cursor type in text mode
;	mov cx,[ScreenCursorType];reset to original value
	mov cx,13<<8|14		;reset to original value
	int 10h			;call video BIOS

	mov ax,4C00h		;function to terminate self
	int 21h			;call DOS

;----------------------------------------
; Read the options passed on the command line and sets whatever variables
; accordingly.
;
; possible future options:
;   specify starting position if file and number of bytes to search
;   output all matches as relative to beginning of file, the starting
;     position, or some user specified offset
;   pause for every page of matching lines output (-pp)
;   no current progress display, matches only
;
GetStartOptions:
	cmp byte [StartOptions.Count],2	;must be at least two parameters
	ja .OptionsOk			;both file and pattern given
	mov edx,Text.NoPattern		;assume no pattern was given
	je .NoPattern			;filename but no pattern
        mov edx,Text.Info               ;no parameters at all were specified
.NoPattern:
	call PrintLine
	jmp ProgramEnd
.OptionsOk:
	mov ebx,[StartOptions.Ptrs]
	mov edi,File.Name
	mov ecx,128/4
	mov esi,[ebx+4]
	rep movsd
	mov esi,[ebx+8]
	mov edi,Pattern.Text
	mov ecx,PatternMaximumLength/4
	rep movsd
;	mov [StartOptions.Ptrs],edi	;array of pointers to each one,
;
;	ret

;----------------------------------------
; Given an ASCII string, it makes a sequence of numeric operation codes to
; be used by SearchForPattern.
;
; definition of pattern codes
; 0 - declare new different key value, if value does not already exist
; 1 - declare new key, value may or may not already exist
; 2 - check value with existing variable, end if mismatch
; 3 - skip over a number of bytes

MakePatternCodes:
	;get source, which is the pattern.text
	;set destination which is pattern.codes
	mov esi,Pattern.Text
	mov ebx,Pattern.Codes
	mov edx,PatternMaximumLength	;set character table to null
				;and counter to maximum pattern length
	xor ecx,ecx
.NextChar:
	mov al,[esi]		;get pattern character
	test al,al		;check for null character
	jz .End			;end if 0 was read

	mov ah,al		;make a copy
	inc esi			;next pattern character
	and ah,-1^32		;make uppercase
	cmp ah,'Z'		;is character above 'Z'
	ja .IllegalCharacter	;it is not a valid character
	cmp ah,'A'		;is character below 'A'
	jb .CheckForWildcard	;character is either wildcard or invalid
	;--- search for instance of in table ---
	mov cl,dh		;set counter to entries in table
	mov edi,.CharacterTable	;set destination to compare al to
	test ebx,ebx		;clear zero flag with dummy test
	repne scasb		;scan value index for prior instances of
	;  if key found in table
	;    code 2, with parameter of index in table
	;    next
	;  elseif character lowercase
	;    code 0
	;  else
	;    code 1
	;  add character to table
	jne .KeyIsNew		;declare new key in table
	mov ah,dh		;copy character table size
	mov byte [ebx],2	;set code to check existing value
	sub ah,cl		;subtract loops left from table characters
	dec ah			;make up for being one off
	;not cl
	;add cl,dh?
	mov [ebx+1],ah		;store index to reference
	jmp short .ContinueLoop
.KeyIsNew:
	test al,32		;test for letter case
	setz cl			;set cl=1 if uppercase, cl=0 if lowercase
	mov word [ebx],cx	;set code to declare key value
	movzx edi,dh		;get character table offset
	inc dh			;add one to character table size
	mov [.CharacterTable+edi],al	;store character in table
	jmp short .ContinueLoop
.CheckForWildcard:
	cmp al,'?'
	jne .CheckForSeparator	;if character is not wildcard
	mov word [ebx],3
	jmp short .ContinueLoop
.CheckForSeparator:
	inc dl
	cmp al,','		;is it a key separator?
	je .ContinueLoop2
.IllegalCharacter:
	mov edx,Text.BadPattern	
	call PrintLine
	jmp ProgramEnd
.ContinueLoop:
	;continue loop if not more than max characters have been read
	add ebx,byte 2
.ContinueLoop2:
	dec dl
	jnz .NextChar
.End:
	;figure length of pattern
        neg dl                          ;make counter negative
	add dl,PatternMaximumLength	;to subtract counter from max length
        mov [Pattern.Length],dl         ;set length of pattern
	mov esi,Pattern.Codes
	;ret

SECTION .bss
.CharacterTable resb PatternMaximumLength       ;enough for 32 characters
SECTION .text

;----------------------------------------
; Tries to open the file given
;
OpenFile:
	mov ax,3D00h		;function to open file, access mode=0
	mov edx,File.Name	;set ptr to source filename
	int 21h			;call DOS
	jnc .Success		;if no error opening
	mov edx,Text.FileOpenError	;set ptr to error message
	call PrintLine
	jmp ProgramEnd
.Success:
	mov [File.Handle],eax	;save file handle for later reads
;	ret

;----------------------------------------
; The main loop of the program, reads in chunks of the source file and calls
; SearchForPattern to find any matches in it.
; Outputs progress, finds, and checks for Esc keypress.
;
SearchInFile:
	call OutputMatch.NewSearch
	xor edx,edx			;start at beginning of file
	mov dword [OutputMatch.SourceBase],File.Buffer ;set base of search
        mov dword [File.Position],edx   ;set file position to zero

.ReadInSection:
	mov eax,4200h			;function to set file position
	mov ebx,[File.Handle]		;get file handle
	shld ecx,edx,16			;set cx to upper word of edx
	int 21h				;call DOS
	mov eax,3F00h			;function to read file
	mov ebx,[File.Handle]		;get file handle
	mov ecx,FileBufferSize		;set number of bytes to read
	mov edx,File.Buffer		;set destination to the file buffer
	int 21h				;call DOS
	jc near .End			;just end and return if error
	movzx ecx,byte [Pattern.Length]	;get length of pattern
	sub eax,ecx			;subtract from length of buffer
	jbe near .End			;end if buffer is negative or null
	mov [SearchForPattern.SourceBytes],eax			;set number of bytes to search
	mov dword [SearchForPattern.SourcePtr],File.Buffer	;set source address

.ForPattern:
	call SearchForPattern		;check for pattern matches in chunk
	jc .NoMatchFound		;if carry is set then no matches
	;output position in file of match and text character string
	call OutputMatch
.NoMatchFound:
	;output progress in file, current byte position
	mov eax,[File.Position]		;get file position
	mov edi,Text.FileProgress+14
	call MakeDecNum			;make decimal number
	mov edx,Text.FileProgress	;set ptr to message
	call PrintLine
	;check for Esc and quit if pressed
	mov ah,1			;function to get key status
	int 16h				;call keyboard BIOS
	jz .NoKeyPressed

	mov ah,0			;function to get last keypress
	int 16h				;call keyboard BIOS
	cmp al,27			;compare character with escape
	jne .NoKeyPressed		;not esc so simply continue
	;pause search and display question whether the user wants to quit
	call PrintClearLine
	mov edx,Text.QueryQuit		;set ptr to message
	call PrintLine
	mov ah,0			;function to wait for keypress
	int 16h				;call keyboard BIOS
	cmp al,27			;compare to escape
	je .End				;end search if pressed again
	or al,32			;make character lowercase
	cmp al,'y'			;yes to quitting?
	je .End				;end search
	call PrintClearLine
	jmp .NoMatchFound		;resume search

.NoKeyPressed:
	;if bytes remain to be searched in current section
	cmp dword [SearchForPattern.SourceBytes],0
	;simply look for next match in same loaded section
	ja near .ForPattern
	;otherwise move position in file to the next section
	;FilePosition += FileBufferSize-Pattern.Length
	mov edx,[File.Position]		;get file position
	movzx ecx,byte [Pattern.Length]	;get length of pattern
	add edx,FileBufferSize		;add length of buffer
	sub edx,ecx			;subtract length of pattern
	mov [File.Position],edx		;save file position
	jmp .ReadInSection
.End:
	call PrintClearLine
	call OutputMatch.PrintTotalFound
	ret

;----------------------------------------
; Searches for pattern matches in source, the most important part of the
; program. Sets carry and eax to -1 if no matches were found, otherwise
; carry is clear and eax contains the address of the pattern match.
;
SearchForPattern:
	cmp byte [Pattern.Length],0	;if there is no pattern to compare
	je near .End
	cmp dword [.SourceBytes],0	;or no source to search
	je near .End			;then end with failure
	;if 16bit word search then set ch to 1 else to zero 0 for bytes
	xor ecx,ecx
	xor eax,eax
	cld			;set direction flag to scan forward

.NextSourceCompare:
	mov edi,Pattern.Codes	;set current code to first one
	mov esi,[.SourcePtr]	;reset source to current position
	mov ch,[Pattern.Length]	;get number of pattern codes to compare
	xor edx,edx		;set value index to null

.NextKeyCompare:
	movzx ebx,byte [edi]	;get pattern key
	;jump to corresponding routine for that code
        ;then jump to either .KeyOk or .Mismatch
.0:	cmp bl,0
	jne .1
	mov al,[esi]		;read value from source
	;check if value already exists in index
	mov ebx,ecx		;save pattern code counter
	mov ebp,edi		;save current pattern code
	mov ecx,edx		;set number of checks to base in value index
	test ebx,ebx		;clear zero flag with dummy test
	mov edi,.ValueIndex	;set destination to compare al to
	repne scasb		;scan value index for prior instances of
	je .Mismatch		;mismatch if value already present
	mov edi,ebp		;restore current pattern code
	mov ecx,ebx		;restore pattern code counter
	mov [.ValueIndex+edx],al;place value into top of index
	inc edx			;set base to next position in index
	jmp short .KeyOk
.1:	cmp bl,1
	jne .2
	jmp short .KeyOk
.2:	cmp bl,2
	jne .3
	mov al,[esi]		;read value from source
	movzx ebx,byte [edi+1]	;get index to compare value to
	cmp al,[.ValueIndex+ebx];compare source with key value
	jne .Mismatch		;mismatch if key value is equal to source
	jmp short .KeyOk
.3:	;do nothing and simply pass over byte
.KeyOk:
	inc esi			;onward to next source position
	add edi,byte 2		;and next pattern code
	dec ch			;one less pattern code to compare
	jnz .NextKeyCompare	;keep looping until until all match

	;all pattern codes must match to have arrived here
	mov eax,[.SourcePtr]	;return of address of pattern match
	dec dword [.SourceBytes];for next recall, start with one fewer bytes
	inc dword [.SourcePtr]	;next byte in search source
	clc			;clear carry to indicate success
	ret

.Mismatch:
	inc dword [.SourcePtr]	;next byte in search source
	dec dword [.SourceBytes];one less time to compare source and pattern
	jnz .NextSourceCompare	;keep looping for byte length of source

.End:
	stc			;set carry to indicate no matches
	mov eax,-1		;indicate no matches again
	ret

.SourcePtr:	dd 0
.SourceBytes:	dd 0
SECTION .bss
.ValueIndex:	resb PatternMaximumLength*2	;enough for 32 words (or 64 bytes)
SECTION .text

;----------------------------------------
; eax=match address
;
OutputMatch:
	inc dword [.TotalFound]		;increment number of matches found
.Again:					;for reprinting old matches??
	push eax			;save address of pattern find
	mov edi,Text.MatchFound		;set destination to write number
;	sub eax,[.SourceBase]		;get offset of find from base
	sub eax,File.Buffer
	add eax,[File.Position]
	call MakeDecNum
	;make decimal number out of find address
	mov edx,Text.MatchFound		;set ptr to message
	call PrintLine

	;get cursor position
	;multiply row by screen width
	;limit cursor position to prevent overwrites
	;set destination
	pop esi				;retrieve address of pattern find
	;subtract matchbase
	mov edi,(80*24)*2+(11*2)
	mov cl,[Pattern.Length]
.NextChar:
	mov al,[esi]			;get character from buffer
	mov [0B8000h+edi],al		;write character to display
	inc esi				;next source character
	add edi,2			;next character/color cell
	dec cl
	jnz .NextChar

	;if file logging is on then output line to file also
	dec dword [.LineCounter]
	;jnz
	;if more than 25 lines have been output, then pause for user to
	;press a key before proceding, but do not actually read the keypress
	;and reset line counter
;.CheckKeys:
	;mov ah,1
	;int 16h
	;jz .CheckKeys

	mov edx,Text.LineEnd
	call PrintLine
	ret

.NewSearch:
	mov dword [.TotalFound],0	;set patterns found so far to zero
	;check if pause per page is set, set to 25 if so
	mov dword [.LineCounter],-1
	ret

.PrintTotalFound:
	mov eax,[.TotalFound]
	mov edi,Text.TotalFound+21
	call MakeDecNum
	mov edx,Text.TotalFound
	call PrintLine
	ret

alignb 4
.TotalFound:	dd 0
.SourceBase:	dd 0
.LineCounter:	dd 25

;----------------------------------------
; Turns a 32bit number into a decimal string, writing it to edi
;
; eax=value edi=text destination
;
MakeDecNum:
	mov ecx,8		;maximum of eight characters
	xor edx,edx		;set top 32 bits of quotient to zero
	mov ebx,10		;base of the decimal system
	add edi,byte 7		;start from right side of number
.NextChar:
	div ebx			;divide number by the decimal base
	add dl,48		;make remainder into an ASCII character
	mov [edi],dl		;output result
	dec edi			;move backwards one character
	test eax,eax		;see if we are done with the number
	jz .FillInBlanks	;nothing but zeroes left
	xor dl,dl		;set edx to zero again for next division
	dec cl			;one less character to output
	jnz .NextChar
	ret

.FillInBlanks:
	mov al,' '		;fill in with spaces
	dec cl			;one less than current count
	std			;move backwards
	rep stosb		;for number of characters remaining
	ret

;----------------------------------------
;
DrawTextLine:
	and edi,16383
	add edi,0B8000h
.NextChar:
	movsb
	inc edi
	dec ecx
	jnz .NextChar
	ret

;----------------------------------------
; edx should already be set
;
PrintLine:
	mov ah,9			;function to print string
	int 21h				;call DOS
	ret

;----------------------------------------
PrintClearLine:
	mov ah,9			;function to print string
	mov edx,Text.BlankSpace		;set ptr to line of space
	int 21h				;call DOS
	ret

;----------------------------------------
; DATA & PRESET VARIABLES
;----------------------------------------

Pattern:
.Length:	db 0		;number of codes in pattern (not bytes)
.Codes:		times 64 db 0	;room to store actual codes
.Text:          db '[pattern]'
		times PatternMaximumLength+.Text-$ db 0
File.Name:      db '[filename]'
		times 128+File.Name-$ db 0

Text:
;80 Column Ruler:   00000000010000000002000000000300000000040000000005000000000600000000070000000008
.Info:          db 'Pattern Searcher v',ProgVersion,', (c)1998 PeekinSoŸt',13,10
                db 'Written using NASM and WDOSX by FDwR (FDwR@hotmail.com)',13,10
		db 10
                db 'Usage:   psrch file.ext pattern',13,10
		db 'Example: psrch zelda.zst a?abcbac',13,10
		db 10
		db 'Little utility for finding sections of tilemaps and text strings in savestates',13,10
		db 'or ROMs. It could also be used for anything else can be searched and has some',13,10
                db 'kind of pattern in it. Not very advanced, but blazingly fast... (I hope anyway)',13,10
		db 10
		db 'The pattern may be up to 32 keys long, with each key representing a different',13,10
		db 'possible byte value. That value can be anything, so long as each key has its',13,10
		db 'own unique one and that all the similar keys have the same value. For example,',13,10
                db 'with the pattern above, 71746476, 79746476, and 32395935 would all be matches.',13,10
                db '(if those particular numeric sequences were really in the savestate anywhere).'
.LineEnd:	db 13,10,'$'
                ;db 10
                ;db 'Please read psrch.txt for more info...',13,10
                ;db '$'
.NoFilename:	db 'No filename was given.$'
.NoPattern:	db 'No search pattern was given.$'
.FileOpenError:	db 'Could not open the file.$'
.BadPattern:	db 'Characters in pattern string can only consist of: a-z, A-Z, and ?$'

;.MatchFound:    db '01234567 : 01234567890123456789012345678901$'
.MatchFound:    db '01234567 :                                 $'
.FileProgress:	db 'Current byte: 01234567',13,'$'
.TotalFound:	db 'Total matches found: 01234567$'
.QueryQuit:	db 'Quit search? Y/N$'
.BlankSpace:	db 13,'                                           ',13,'$'

;----------------------------------------
; RUNTIME VARIABLES
;----------------------------------------
SECTION .bss

StartOptions:
.Count:		resd 1	;number of parameters
.Ptrs:		resd 1	;array of pointers to each one
.Env:		resd 1	;command environment strings
.Selector: 	resw 1	;command environment selector

File:
.Handle:	resd 1		;handle for reading source file
.Position:	resd 1		;byte position in file
;.Name:		resb 256	;the source file's name
.Buffer:	resb FileBufferSize

ScreenCursorType:	resw 1
