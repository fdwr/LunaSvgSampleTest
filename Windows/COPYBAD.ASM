; Copy Bad File (c)PeekinSoft
; 2002-06-09 / 2002-06-13
; Dwayne Robinson (FDwR@hotmail.com)
;
; Purpose:
;   Copies corrupt files on damaged media that Explorer would simply give up
;   on. Hopelessly damaged areas are filled with zeroes and skipped. You can
;   drag the source file and drop it on the program to begin copying it to
;   the temporary folder.
;
; Reason:
;   This program was written because there was 90mb AVI on a CD that was
;   mostly good, but stupid Explorer would always stop half way reporting
;   device read error. I don't care, COPY IT ANYWAY! Thus, this very simple
;   program was born.
;
; Tech-note:
;   For anyone interested, it opens the source file unbuffered, reading only
;   on sector boundaries. The file name, size, and date are all copied, but
;   all file attributes (hidden/read only) and security attributes are
;   discarded. Note that unbuffered copying is much slower than the usual
;   copying that most file managers use, but it is more reliable."
;
;   Copies corrupt files from CDs or floppy disks when Explorer gives up.
;   Hopelessly corrupt parts of the file will be zeroed. Name, size, and
;   date will be copied the same, but file attribute and security will be
;   discarded.
;
; Todo:
;   Add progress bar
;   Use actual sector size


[section code code]
[section data data]
[section text data]
[section bss bss]
global Main


; Include Windows definitions/constants/macros
;%define debug
%define UseWindowStyles
%define UseWindowControls
%define UseWindowMsgs
%define UseWindowGfx
;%define UseResources
%define UseFileSystem
%define UseKeyboard
%include "mywininc.asm"         ;standard Windows constants, structs...


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
align 4, db 0
hwnd:   dd 0                    ;window handle
;hdc:   dd 0                    ;class device context
hfont:  dd 0                    ;default font to use for controls

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

;             control name, id,     class name          text                flags                           x  y        w h
DefWndControl lblFilenameTxt,  100, ClassNames.Label,   "File name:",       SS_RIGHT,0,   8, 8+16*0,  64,16
DefWndControl lblFileSizeTxt,  101, ClassNames.Label,   "File size:",       SS_RIGHT,0,   8, 8+16*1,  64,16
DefWndControl lblProgressTxt,  102, ClassNames.Label,   "Progress:",        SS_RIGHT,0,   8, 8+16*2,  64,16
DefWndControl lblErrorsTxt,    103, ClassNames.Label,   "Read errors:",     SS_RIGHT,0,   8, 8+16*3,  64,16
DefWndControl lblSectorSizeTxt,104, ClassNames.Label,   "Sector size:",     SS_RIGHT,0,   8, 8+16*4,  64,16
DefWndControl txtFilename,     105, ClassNames.Edit,    Text.NoFilename,    ES_READONLY|ES_AUTOHSCROLL,0,76,8+16*0, 208,16
DefWndControl lblFileSize,     106, ClassNames.Label,   NullString,         0,0,            76,8+16*1,  64,16
DefWndControl lblProgress,     107, ClassNames.Label,   NullString,         0,0,            76,8+16*2,  64,16
DefWndControl lblErrors,       108, ClassNames.Label,   NullString,         0,0,            76,8+16*3,  64,16
DefWndControl lblSectorSize,   109, ClassNames.Label,   NullString,         0,0,            76,8+16*4,  64,16
DefWndControl pbrCopied,       150, ClassNames.Progress,NullString,         WS_DISABLED,0,8,96,       276,8
DefWndControl chkErrorPause,   151, ClassNames.Button,  "Pause on er&ror",  WS_TABSTOP|BS_AUTOCHECKBOX|WS_GROUP,0, 8,112-4, 276,16
DefWndControl cmdCopy,         200, ClassNames.Button,  "&Copy...",         WS_TABSTOP|BS_DEFPUSHBUTTON|WS_GROUP|WS_DISABLED,0, 8+56*0,112+(8*2), 52,24
DefWndControl cmdStopResume,   201, ClassNames.Button,  Caption.Resume,     WS_TABSTOP|WS_DISABLED,0, 8+56*1,112+(8*2), 52,24
DefWndControl cmdOpen,         202, ClassNames.Button,  "&Open",            WS_TABSTOP|WS_DISABLED,0, 8+56*2,112+(8*2), 52,24
DefWndControl cmdExplore,      203, ClassNames.Button,  "&Explore",         WS_TABSTOP,0,             8+56*3,112+(8*2), 52,24
DefWndControl cmdAbout,     IDHELP, ClassNames.Button,  "&About",           WS_TABSTOP,0,             8+56*4,112+(8*2), 52,24

;rect:
;point:
;dd 0,            0             ;left,top
;dd Screen.Width, Screen.Height ;right,bottom

section bss
msg:    resb MSG_size
;ps:    resb PAINTSTRUCT_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:   db "Copy Bad File 1.2 (Beta)" ;,0
NullString:     db 0
ClassNames:
.Program:       db "CopyBadFile",0
.Button:        db "BUTTON",0
.Label:         db "STATIC",0
.Edit:          db "EDIT",0
.Progress:      db "msctls_progress32",0
ErrMsg:
;.Fatal:        db "CopyBadFile: Fatal Error",0
.NoWindow:      db "Failed to create window.",0
.FileOpen:      db "File Error #0000",0
.SrcOpen:       db "Could not open source file.",0
.DestOpen:      db "Could not create destination file.",0
.AtSrcEnd:      db "Copy already finished before. Retry copy from beginning?",0
.WriteError:    db "Error writing to copy file. The disk may be full, removed, or inaccessible.",0
Caption:
.Resume:        db "&Resume",0
.Stop:          db "&Pause",0
Text:
.NoFilename:    db "(drag & drop file)",0
.About:         db "Copies corrupt files on damaged media that Explorer would simply give up on. "
                db "Hopelessly damaged areas are filled with zeroes and skipped. "
                db "You can drag the source file and drop it on the program to begin copying it to the temporary folder."
                db 10,10
                db "This program was written because there was 90mb AVI on a CD that was mostly good, but stupid Explorer would always stop half way reporting device read error. "
                db "I don't care, COPY IT ANYWAY! Thus, this very simple program was born."
                db 10,10
                db "For anyone interested, it opens the source file unbuffered, reading only on sector boundaries. "
                db "The file name, size, and date are all copied, but all file attributes (hidden/read only) and security attributes are discarded. "
                db "Note that unbuffered copying is much slower than the usual copying that most file managers use, but it is more reliable."
                db 10,10
                db "Dwayne Robinson",10
                db "FDwR@hotmail.com",10
                db "PeekinSoft 2002-05-11"
                db 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; global program variables

section data
align 4, db 0
SrcHandle:  dd 0                ;source file's handle
DestHandle: dd 0
SrcLen:     dd 0                ;byte length of source file
FilePtr:    dd 0                ;current position in files
Copying:    dd 0                ;currently copying flag
Errors:     dd 0                ;total sector read errors
Flashes:    dd 0                ;title bar flashes remaining
FileSizeShr:dd 0                ;amount to shift size to fit under <64
SectorSize: dd 0                ;bytes per sector of source file
FocusHwnd:  dd 0                ;control that has focus
PauseOnError:dd 0

section bss
alignb 8
FileBufferSize equ 16384;4096
FileBuffer: resb FileBufferSize
SrcFile:    resb MAX_PATH
DestFile:   resb MAX_PATH
DestDir:    resb MAX_PATH
CreateTime: resb FILETIME_size
WriteTime:  resb FILETIME_size


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
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_MINIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME, 0,0, 300,8*23, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    ;mov [hwnd],eax


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Loop
.Top:
    debugpause "entering main loop"

.Next:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    jz near .End
    mov eax,[msg+MSG.message]
    debugwinmsg "process msg=%X %s W=%X L=%X", eax,edx,[msg+MSG.wParam],[msg+MSG.lParam]
    api IsDialogMessage, [hwnd],msg
    test eax,eax
    jnz .MsgHandled
    api DispatchMessage, msg
.MsgHandled:
    cmp [Copying],dword FALSE
    je .Next

    ; basic loop:
    ;
    ; do
    ;   zero buffer
    ;   read sector block from source
    ;   advance ptr
    ;   write sectors to destination
    ;   quit if done
    ;   refresh current position
    ;   if pending messages
    ;     if escape pressed || close button, break
    ;     dispatch message
    ;   endif
    ; loop

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.CopyLoop:
    debugpause "entering copy loop"
    mov esi,[FilePtr]
.NextBlock:

    ; zero file buffer in case of bad read
    ;cld
    mov ecx,[SectorSize]
    xor eax,eax
    mov edi,FileBuffer
    shr ecx,2                   ;/4    
    rep stosd

    ; read string of sectors
    api SetFilePointer, [SrcHandle], esi,NULL,FILE_BEGIN
    api ReadFile, [SrcHandle],FileBuffer, [SectorSize],.BytesRead, NULL
    ;api GetLastError
    ;debugpause "read result=%d %s<",eax,FileBuffer
    ; check for errors
    test eax,eax
    jnz .NoReadError
    inc dword [Errors]
    mov eax,[Errors]
    call NumToString
    api SetWindowText, [lblErrors],NumToString.Buffer

    cmp dword [PauseOnError],TRUE
    jb .WritePart
    call StopCopy
    jmp .Top

.NoReadError:

.WritePart:
    ; write file buffer
.Retry:
    mov eax,[SrcLen]
    sub eax,esi
    cmp [SectorSize],eax
    ja .PartSector
    mov eax,[SectorSize]        ;not last part of file so write full sector
.PartSector:
    lea edx,[esi+eax]
    mov [FilePtr],edx
    api WriteFile, [DestHandle],FileBuffer, eax,.BytesWritten, NULL

    ; check for write errors
    test eax,eax
    jnz .NoWriteError
    call FormatFileError
    api MessageBox, [hwnd],ErrMsg.WriteError,ErrMsg.FileOpen,MB_RETRYCANCEL|MB_ICONEXCLAMATION|MB_TOPMOST
    cmp eax,IDRETRY
    je .ResetPointer
    call StopCopy
    jmp .Top
.ResetPointer:
    ; readjust file pointer just in case
    api SetFilePointer, [DestHandle], esi,NULL,FILE_BEGIN
    jmp .Retry
.NoWriteError:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
    ; update information (current byte position)
    mov eax,[FilePtr]
    call NumToString
    api SetWindowText, [lblProgress],NumToString.Buffer
    api SendMessage, [pbrCopied],PBM_SETPOS,[FilePtr],0

    ; advance pointer & check if done copying
    add esi,[SectorSize]
    cmp [SrcLen],esi
    ja near .Continue
    api EnableWindow, [cmdStopResume],FALSE
    api MessageBeep, MB_ICONHAND
    api SetTimer,[hwnd],1,300,NULL  ;3 times per second, no callback
    xor eax,eax
    api SetWindowPos, [hwnd],HWND_TOPMOST, eax,eax, eax,eax, SWP_NOACTIVATE|SWP_NOMOVE|SWP_NOSIZE
    xor eax,eax
    api SetWindowPos, [hwnd],HWND_NOTOPMOST, eax,eax, eax,eax, SWP_NOACTIVATE|SWP_NOMOVE|SWP_NOSIZE
    mov dword [Flashes],10
    push dword .Top
    jmp StopCopy
.Continue:

    ; check for any pending messages
.NextPeek:
    xor eax,eax
    api PeekMessage, msg, eax,eax,eax,PM_REMOVE
    test eax,eax
    jz near .NextBlock
    cmp dword [msg+MSG.message],WM_QUIT
    je .EndAndClose
    api IsDialogMessage, [hwnd],msg
    ;api DispatchMessage, msg
    cmp [Copying],dword FALSE
    jne .NextPeek
    jmp .Top


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Termination
.EndAndClose:
    api SetFileTime, [DestHandle], CreateTime,NULL,WriteTime
    api CloseHandle, [SrcHandle]
    api CloseHandle, [DestHandle]
.End:
    debugpause "ending"
    api DestroyWindow, [hwnd]
    api ExitProcess, [msg+MSG.wParam]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section bss
alignb 4
.BytesRead:     resd 1
.BytesWritten:  resd 1
section code


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]

    cmp eax,WM_KEYDOWN
    jne .NotKey
    cmp byte [msg+MSG.wParam],VK_ESCAPE
    je near .EscPress
.NotKey:
    cmp eax,WM_COMMAND
    jne .NotCommand
    cmp word [esp+.wParam+2],BN_CLICKED
    je near .Command
.NotCommand:
    cmp eax,WM_TIMER
    je near .FlashTitle
    cmp eax,WM_ACTIVATE
    je near .Activate
    cmp eax,WM_CREATE
    je near .Create
    cmp eax,WM_SYSCOMMAND
    je near .Minimize
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
    api PostQuitMessage,0
.RetFalse:
    xor eax,eax
    ret 16

.FileDropped:
    debugpause "File dropped"
    cmp [Copying],dword 1
    jae .AlreadyCopying
    api DragQueryFile, [esp+.wParam+12],0, SrcFile,MAX_PATH
    call StartCopy
.AlreadyCopying:
    api DragFinish, [esp+.wParam]
    debugpause "End File dropped"
    xor eax,eax
    ret 16

.Create:
    mov eax,[esp+.hwnd]
    mov [hwnd],eax
    mov [FocusHwnd],eax
    ;api GetDC, eax              ;get window class display handle
    ;debugwrite "get hdc=%X",eax
    ;mov [hdc],eax
    api GetStockObject, DEFAULT_GUI_FONT
    mov [hfont],eax

    api InitCommonControls

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

    push dword txtFilename
    call CreateChildWindow
    push dword lblFileSize
    call CreateChildWindow
    push dword lblProgress
    call CreateChildWindow
    push dword lblErrors
    call CreateChildWindow
    push dword lblSectorSize
    call CreateChildWindow

    push dword pbrCopied
    call CreateChildWindow
    push dword chkErrorPause
    call CreateChildWindow

    ; create buttons
    push dword cmdCopy
    call CreateChildWindow
    push dword cmdStopResume
    call CreateChildWindow
    push dword cmdOpen
    call CreateChildWindow
    push dword cmdExplore
    call CreateChildWindow
    push dword cmdAbout
    call CreateChildWindow

    xor eax,eax
    ret 16

.EscPress:
    cmp [Copying],dword FALSE
    jne near StopCopy
    api PostQuitMessage,1
    ret

.Command:
    mov eax,[esp+.wParam]
    push dword .RetFalse
    cmp eax,chkErrorPause.Id
    je near .chkErrorPause
    cmp eax,IDCANCEL
    je .EscPress
    cmp eax,cmdCopy.Id;|(BN_CLICKED<<16)
    je .cmdCopy
    cmp eax,cmdStopResume.Id
    je .cmdStopResume
    cmp eax,cmdOpen.Id
    je .cmdOpen
    cmp eax,IDHELP
    je .cmdAbout
    cmp eax,cmdExplore.Id
    je .cmdExplore
    ret

.cmdCopy:
    ; show file open dialog
    ; if user pressed ok
    ;   copy filename
    ;   start copy
    ; endif
    ret
.cmdOpen:
    ; open temporary folder
    ; first attempt to use explorer
    ; if failed, use ShellEx
    ; explorer /select,[filename]
    ;api ShellExecute, [hwnd],"open",DestFile, NULL,NULL, 0
    api ShellExecute, [hwnd],"open",DestFile, NULL,NULL, SW_SHOWNORMAL
    ret
.cmdAbout:
    api MessageBox, [hwnd],Text.About,ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret
.cmdStopResume:
    cmp dword [Copying],FALSE
    je near StartCopy.Resume    ;resume using last file
    jmp StopCopy
.cmdExplore:
    ; open temporary folder
    ; 'explorer /select,[filename]
    api GetTempPath, MAX_PATH,DestDir
    api ShellExecute, [hwnd],"open",DestDir, NULL, NULL, SW_SHOWNORMAL
    ret
.chkErrorPause:
    api SendMessage, [chkErrorPause], BM_GETCHECK, 0,0
    mov [PauseOnError],eax
    ret

.FlashTitle:
    api FlashWindow, [hwnd],TRUE
    dec dword [Flashes]
    jg .MoreFlashes
    api KillTimer,[hwnd],1      ;destroy 30 tick per second timer
    api FlashWindow, [hwnd],FALSE
.MoreFlashes:
    xor eax,eax
    ret 16

.Activate:
    cmp word [esp+.wParam],WA_INACTIVE
    je .LoseFocus
    debugwrite "new focus hwnd=%X",[FocusHwnd]
    api SetFocus, [FocusHwnd]
    xor eax,eax
    ret 16

.LoseFocus:
    api GetFocus
    test eax,eax
    jz .NullFocus
    mov [FocusHwnd],eax
    debugwrite "old focus hwnd=%X",eax
    xor eax,eax
.NullFocus:
    ret 16

.Minimize:
    cmp dword [esp+.wParam],SC_MINIMIZE
    jne .NotMinimize
    api GetFocus
    mov [FocusHwnd],eax
    debugwrite "old focus hwnd=%X",eax
.NotMinimize:
    jmp [DefWindowProc]


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Copies a control structure onto parameter stack and calls CreateWindowEx.
; Sets the font for each control, assumes the standard GUI font has already
; been obtained.
CreateChildWindow:
    push esi,edi
    mov esi,[esp+4+8]
    xor eax,eax                 ;null window creation data
    push eax
    push dword wc.BaseAddress
    push dword [esi+WndControlStruct.hId]
    push dword [hwnd]
    ;cld
    sub esp,byte 8*4
    add esi,byte WndControlStruct.dwExStyle
    mov ecx,8
    mov edi,esp
    rep movsd
    api CreateWindowEx
    mov [esi+WndControlStruct.hwnd-WndControlStruct_size],eax
    api SendMessage, eax,WM_SETFONT,[hfont],FALSE
    pop esi,edi
    ret 4


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=error message ptr)
EndWithErrMsg:
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBox, [hwnd],esi,ProgramTitle,MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL ;|MB_SETFOREGROUND
    api DestroyWindow, [hwnd]
    api ExitProcess, -1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; enable/disable buttons
; open source file
; open/create destination file
; resume copy and sync file pointers
StartCopy:
    cmp [Copying],dword TRUE
    jae near .AlreadyCopying
    mov dword [Errors],0
    api SetWindowText, [lblErrors],NullString

.Resume:
    push ebx,esi,edi

    debugpause "Source file name = %s",SrcFile

    mov esi,SrcFile
    api SetWindowText, [txtFilename],esi
    api SendMessage, [txtFilename], EM_SETSEL, 0,-1

    ; open unbufferred source file
    ;api CreateFile, esi, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING|FILE_FLAG_SEQUENTIAL_SCAN, NULL
    api CreateFile, esi, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, NULL
    debugpause "Source file handle=%X",eax
    cmp eax,INVALID_FILE_HANDLE
    mov esi,ErrMsg.SrcOpen      ;set error message in case jump is taken
    je near .FileError
    mov [SrcHandle],eax

    ; get source file size
    api SetFilePointer, eax, 0,NULL,FILE_END
    debugpause "Source file pointer=%d",eax
    mov [SrcLen],eax
    call NumToString
    api SetWindowText, [lblFileSize],NumToString.Buffer
    xor eax,eax
    api SendMessage, [pbrCopied],PBM_SETPOS,eax,eax
    api SendMessage, [pbrCopied],PBM_SETRANGE32,0,[SrcLen]

    ; get source file time and sector size
    api GetFileTime, [SrcHandle], CreateTime,NULL,WriteTime
    xor eax,eax
    push dword [SrcFile]
    mov dword [SectorSize],FileBufferSize ;set to max size in case call fails
    mov byte [SrcFile+3],0      ;pass only root directory (dumb)
    api GetDiskFreeSpace, SrcFile,eax,SectorSize,eax,eax
    pop dword [SrcFile]
    debugpause "Sector size =%d",[SectorSize]
    mov eax,[SectorSize]
    call NumToString
    api SetWindowText, [lblSectorSize],NumToString.Buffer

    ; build destination filename
    mov esi,SrcFile
    call GetFileName
    api GetTempPath, MAX_PATH,DestFile
    ;cld
    mov ecx,MAX_PATH
    lea edi,[DestFile+eax]
    sub ecx,eax                 ;max path - path filename offset
    rep movsb

    ; open destination file
    debugpause "Dest file name = %s",DestFile
    api CreateFile, DestFile, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_FLAG_SEQUENTIAL_SCAN, NULL
    debugpause "Dest file handle=%X",eax
    cmp eax,INVALID_FILE_HANDLE
    mov esi,ErrMsg.DestOpen     ;set error message in case jump is taken
    je near .FileError
    mov [DestHandle],eax

    ; resume copy and sync file pointers
    xor edx,edx
    api SetFilePointer, eax, edx,edx,FILE_END
    cmp [SrcLen],eax
    ja .StartOk
    api MessageBox, [hwnd],ErrMsg.AtSrcEnd,ProgramTitle,MB_ICONEXCLAMATION|MB_RETRYCANCEL|MB_SETFOREGROUND
    cmp eax,IDRETRY
    jne near StopCopy.CloseOnly
    xor eax,eax
    api SetFilePointer, [DestHandle], eax,eax,eax;FILE_BEGIN
    api SetEndOfFile, [DestHandle]
    xor eax,eax
.StartOk:
    mov edx,[SectorSize]
    neg edx                     ;get bitmask from sector size
    and eax,edx                 ;align to nearest sector
    debugpause "Synced file pointer=%d",eax
    mov [FilePtr],eax
    api SetFilePointer, [DestHandle], eax,NULL,FILE_BEGIN

    api EnableWindow, [cmdCopy],FALSE
    api EnableWindow, [cmdStopResume],TRUE
    api EnableWindow, [cmdOpen],TRUE
    api SetWindowText, [cmdStopResume],Caption.Stop
    inc dword [Copying]

.End:
    pop ebx,esi,edi
.AlreadyCopying:
    ret

.FileError: ;(esi=text message)
    call FormatFileError
    api MessageBox, [hwnd],esi,ErrMsg.FileOpen,MB_ICONEXCLAMATION|MB_SETFOREGROUND
    jmp short StopCopy.CloseOnly


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
StopCopy:
    push ebx,esi,edi
.Inside:
    mov eax,[FilePtr]
    call NumToString
    api SetWindowText, [lblProgress],NumToString.Buffer
    api SetWindowText, [cmdStopResume],Caption.Resume
    ;api EnableWindow, [cmdCopy],TRUE

    api SetFileTime, [DestHandle], CreateTime,NULL,WriteTime
.CloseOnly:
    debugpause "Closing files"
    api CloseHandle, [SrcHandle]
    api CloseHandle, [DestHandle]
    xor eax,eax
    mov [SrcHandle],eax
    mov [DestHandle],eax
    mov [Copying],eax ;FALSE
    pop ebx,esi,edi
    ret


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
