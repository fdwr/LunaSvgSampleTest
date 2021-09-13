; Quick Set Pic as Desktop (c)PikenSoft
; Dwayne Robinson (FDwR@hotmail.com)
; 2004-03-30 Born
; 2004-04-07 Reads correct location of IrfanView executable from registry.
; 2004-06-15 Fixed bug that picture was not resized because resample came after
;		 convert on command line. Did not notice because desktop strech was on.
;
; Purpose:
;   Quickly sets any picture as background using IrfanView.
;

[section code code]
[section data data]
[section text data]
[section bss bss]
global Main

;#define debug

; Include Windows definitions/constants/macros
;%define debug
%define UseProcess
%define UseWindowStyles
%define UseWinRegistry
%define UseWindowSysVars
%include "WINNASM.INC"         ;standard Windows constants, structs...


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text
Text:
.About:
    db "Quickly sets any picture as user desktop background using IrfanView.",13
    db "  QsetDeskPic ",34,"sourcefile",34," ",34,"destfile",34,13
    db "  QsetDeskPic ",34,"shinryusai_k_02_800.jpg",34," ",34,"c:\windows\bg.bmp",34,13
    db 13
    db "Dwayne Robinson (FDwR@hotmail.com)",13
    db "PikenSoft 2004-03-30 Born",13
    db 0
.TooManyFilenames:
    db "Too many filenames. Need only source and destination images.",0
.TooFewFilenames:
    db "Too few filenames. Need both source and destination images.",0
.InvalidParameter:
    db "Invalid command line parameter.",0
.MissingParameter:
    db "Missing parameter",0
.ExecErr:
    db "Error executing IrfanView",0
.ConvertFailed:
    db "Conversion failed. Not updating wallpaper.",0
.NoIrfanView:
    db "Could not find IrfanView's path in the registry. Ensure it is installed.",13,13
    db "This program itself does not do any image conversion. Rather it calls the much",
    db "capable IrfanView to do the resize+conversion. It is a very useful program and",
    db "surprisingly free, so I recommend getting it.",0

FilesNeeded: db 2
alignb 4
StartParamFlags: dd 0
.PreviewOnly equ 1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section bss
SrcFile:    resb MAX_PATH	; source image parameter
DestFile:   resb MAX_PATH	; destination image parameter
DestPath:   resb MAX_PATH	; destination image with full path
IviewPath:  resb MAX_PATH	; path to IrfanView executable
CmdLine:    resb MAX_PATH*4	; cmd line to start IrfanView

ExecInfo:   resb 16;PROCESS_INFORMATION_size
ExecOpts:   resb 16*4;STARTUPINFO_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code
Main:
    call CheckStartParams
    jc near .ParamErr
    cmp byte [FilesNeeded],1
    mov edx,Text.About
    ja near .ParamErr
    mov edx,Text.TooFewFilenames
    je near .ParamErr

    ; check if full path was given for destination
    ; if not, prepend the source file's full path
    mov esi,DestFile
    call GetFileName
    cmp esi,edi
    jne .FullPathGiven
    api lstrcpy, DestPath,SrcFile
    mov esi,DestPath
    call GetFileName
    api lstrcpy, esi,DestFile
    jmp .OnlyFileGiven
.FullPathGiven:
    api lstrcpy, DestPath,DestFile
.OnlyFileGiven:

    ; build command line string
    ; read from registry! HKEY_CLASSES_ROOT\Applications\i_view32.exe\shell\open\command
    push dword MAX_PATH
    api RegQueryValue, HKEY_CLASSES_ROOT,"Applications\i_view32.exe\shell\open\command", IviewPath,esp
    pop ecx
    test eax,eax
    mov edx,Text.NoIrfanView
    jnz near .ParamErr
    debugpause "read from registry=%s", CmdLine
    mov esi,IviewPath
    call CheckStartParams.GetWordLen
    mov byte [ebx],0 ;clip off an extra junk, just want path and file
    ;api lstrcpy, CmdLine, "C:\Programs\Irfanvyu\i_view32.exe "

    api GetSystemMetrics, SM_CXSCREEN ; screen size, height x width
    mov ebx,eax
    api GetSystemMetrics, SM_CYSCREEN
    test dword [StartParamFlags],StartParamFlags.PreviewOnly
    jnz .PreviewOnly
.ConvertFile:
    api wsprintf, CmdLine, "%s %s /resample=(%d,%d) /aspectratio /convert=%s",IviewPath,SrcFile, ebx,eax, DestPath
    jmp short .ConvertedFile
.PreviewOnly:
    api wsprintf, CmdLine, "%s %s /resample=(%d,%d) /aspectratio /fs",IviewPath,SrcFile, ebx,eax
.ConvertedFile:

    ; spawn irfanview
    xor eax,eax
    mov dword [ExecOpts+STARTUPINFO.cb],17*4
    mov dword [ExecOpts+STARTUPINFO.lpReserved],eax
    mov dword [ExecOpts+STARTUPINFO.lpDesktop],eax
    mov dword [ExecOpts+STARTUPINFO.dwFlags],eax
    debugpause "creating process cmd=%s", CmdLine
    api CreateProcess, NULL,CmdLine, NULL,NULL, FALSE, NORMAL_PRIORITY_CLASS, NULL, NULL, ExecOpts,ExecInfo
    test eax,eax
    mov edx,Text.ExecErr
    jz near .ParamErr

    ; wait for irfanview to finish and check exit code
    debugpause "waiting to finish"
    api WaitForSingleObject, [ExecInfo],-1;INFINITE
    debugpause "finished"
    push eax
    api GetExitCodeProcess, [ExecInfo],esp
    pop eax
    test eax,eax
    mov edx,Text.ConvertFailed
    jnz .ParamErr

    debugpause "updating wallpaper"
    api SystemParametersInfo, SPI_SETDESKWALLPAPER, 0,DestPath, SPIF_UPDATEINIFILE

    debugpause "exiting"
    api ExitProcess, 0

.ParamErr:
    api MessageBox, NULL,edx,"SetPicToBg",MB_OK|MB_ICONINFORMATION|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
    api ExitProcess, -1

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
    ;debugpause "command line = %s length = %d",esi,ecx
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
    mov edx,Text.InvalidParameter
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
    mov edx,Text.InvalidParameter ;just in case invalid parameter
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
    movzx eax,byte [esi]
    bt dword [.SepChars],eax
    jnc near .Err               ;no number so end
    cmp al,'0'
    mov edx,Text.InvalidParameter ;just in case invalid parameter
    jb near .Err                ;not numeric so end
    cmp al,'9'
    ja near .Err                ;not numeric so end
    call StringToNum.UseRadix
    mov edx,Text.MissingParameter ;set message in case error
    jz near .Err                ;no number so end
    ret
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.NonSwitchParam:
    call .GetWordLen
    dec byte [FilesNeeded]
    mov edx,Text.TooManyFilenames
    js near .Err
    mov edi,DestFile
    jz .Nsp
    mov edi,SrcFile
.Nsp:
    ;cld
    rep movsb
    mov byte [edi],0            ;put null on end of filename
    mov esi,ebx                 ;skip trailing " or space
    ret
.Help:
    ;call .CheckNextParam
    mov edx,Text.About
    jmp .Err
.PreviewOnly:
    or dword [StartParamFlags],StartParamFlags.PreviewOnly
    ret

;.Invalid:
;    call .GetNextParam          ;skip any initial space
;    mov edx,Text.MissingParameter ;set message in case error
;    jae near .Err               ;cf=0
;    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
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
    dd .PreviewOnly
.List:      ;parameter word strings
    ;first byte is length of string
    ;following bytes are characters of parameter string (1-255)
    ;last length of list is zero
    db 1,"h"
    db 1,"?"
    db 7,"preview"
    db 0
section code


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

