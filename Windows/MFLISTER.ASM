; Media File Lister (c)PeekinSoft
; 2002-09-26 / 2002-09-26
; Dwayne Robinson (FDwR at hotmail.com)
;
; Purpose:
;   Simply lists all files of certain types below a given path. Why? Because
;   I wanted a program that would find and list all media files my CDs. My
;   collection was simply getting too large to easily locate which CD
;   specific files were on.


;filename
;volume
;size
;date
;checksum
;flags



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
focus:  dd 0                    ;control that has focus

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
at WNDCLASS.lpszMenuName,       dd 1;NULL
at WNDCLASS.lpszClassName,      dd ClassNames.Program
iend

;             control name, id,     class name          text                flags                               x  y        w h

DefWndControl tabMain,         300, ClassNames.Tab,     "&About",           WS_CHILD|WS_TABSTOP|TCS_VERTICAL|TCS_FOCUSNEVER|TCS_FIXEDWIDTH,0, 0,0, 392,200

DefWndControl txtFilePath,     100, ClassNames.Edit,    "[file name here]", WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_GROUP,WS_EX_CLIENTEDGE,          0, 0+40,       330,20
DefWndControl txtCdVolume,     101, ClassNames.Edit,    "[cd volume]",      WS_CHILD|WS_VISIBLE|WS_TABSTOP,WS_EX_CLIENTEDGE,          330, 0+40,     64,20
DefWndControl txtMediaExts,    102, ClassNames.Edit,    "MPG MPEG AVI MP3 OGM",      WS_CHILD|WS_VISIBLE|WS_TABSTOP,WS_EX_CLIENTEDGE,          0, 184+16*2,     378,20
DefWndControl lstFiles,        103, ClassNames.ListBox, "(file list)",      WS_CHILD|WS_VISIBLE|WS_TABSTOP|SS_RIGHT,WS_EX_CLIENTEDGE, 0, 40+4,    394,16*10
DefWndControl btnStripPath,    104, ClassNames.Button,  "Filename only (strip all path)",       WS_CHILD|WS_TABSTOP|BS_AUTOCHECKBOX,0,                8, 176+16*0,  394,16
DefWndControl btnWaitOnVolume, 105, ClassNames.Button,  "Wait for next volume (ejects when done)",WS_CHILD|BS_AUTOCHECKBOX|WS_TABSTOP,0,             8, 176+16*1,  394,16

DefWndControl cmdScan,         200, ClassNames.Button,  "&Scan...",         WS_CHILD|WS_TABSTOP|BS_DEFPUSHBUTTON|WS_GROUP,0, 56*0,240, 52,24
DefWndControl cmdStopResume,   201, ClassNames.Button,  Caption.Resume,     WS_CHILD|WS_TABSTOP|WS_DISABLED,0, 56*1,240, 52,24
DefWndControl cmdDelete,       202, ClassNames.Button,  "&Delete",          WS_CHILD|WS_TABSTOP,0, 56*2,240, 52,24
DefWndControl cmdClear,        204, ClassNames.Button,  "&Clear all",       WS_CHILD|WS_TABSTOP,0, 56*3,240, 52,24
DefWndControl cmdAbout,     IDHELP, ClassNames.Button,  "&About",           WS_CHILD|WS_TABSTOP,0, 56*4,240, 52,24

%if 0
DefWndControl txtFilename,     105, ClassNames.Edit,    Text.NoFilename,    WS_CHILD|WS_VISIBLE|ES_AUTOHSCROLL,76,8+16*0, 208,16
DefWndControl lblFileSize,     106, ClassNames.Label,   NullString,         WS_CHILD|WS_VISIBLE,            76,8+16*1,  64,16
DefWndControl lblProgress,     107, ClassNames.Label,   NullString,         WS_CHILD|WS_VISIBLE,            76,8+16*2,  64,16
DefWndControl lblErrors,       108, ClassNames.Label,   NullString,         WS_CHILD|WS_VISIBLE,            76,8+16*3,  64,16
DefWndControl lblSectorSize,   109, ClassNames.Label,   NullString,         WS_CHILD|WS_VISIBLE,            76,8+16*4,  64,16
DefWndControl pbrCopied,       150, ClassNames.Progress,NullString,         WS_CHILD|WS_VISIBLE|WS_DISABLED,8,96,       276,8
DefWndControl cmdCopy,         200, ClassNames.Button,  "&Copy...",         WS_CHILD|WS_VISIBLE|WS_TABSTOP|BS_DEFPUSHBUTTON|WS_GROUP|WS_DISABLED, 8+56*0,112, 52,24
DefWndControl cmdStopResume,   201, ClassNames.Button,  Caption.Resume,     WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_DISABLED, 8+56*1,112, 52,24
DefWndControl cmdOpen,         202, ClassNames.Button,  "&Open",            WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_DISABLED, 8+56*2,112, 52,24
DefWndControl cmdExplore,      203, ClassNames.Button,  "&Explore",         WS_CHILD|WS_VISIBLE|WS_TABSTOP,             8+56*3,112, 52,24
DefWndControl cmdAbout,        204, ClassNames.Button,  "&About",           WS_CHILD|WS_VISIBLE|WS_TABSTOP,             8+56*4,112, 52,24
%endif

rect:
;point:
dd 0, 0 ;left,top
dd 0, 0 ;right,bottom

section bss
msg:    resb MSG_size
;ps:    resb PAINTSTRUCT_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:   db "Media File Lister 1.0 (Beta)" ;,0
                ;dw 'M','e','d','i','a',' ','F','i','l','e',' ','L','i','s','t','e','r',' ','1','.','0',' ','(','B','e','t','a',')',0 ;,0
NullString:     db 0
ClassNames:
.Program:       db "MediaFileLister",0
                ;dw 'M','e','d','i','a','F','i','l','e','L','i','s','t','e','r',0
.Button:        db "BUTTON",0
.Label:
.Static:        db "STATIC",0
.Edit:          db "EDIT",0
.ListBox:       db "LISTBOX",0
.Progress:      db "msctls_progress32",0
.Tab:           db "SysTabControl32",0
ErrMsg:
;.Fatal:        db "MediaFileLister: Fatal Error",0
.NoWndClass:    db "Failed to register window class.",0
.NoWindow:      db "Failed to create window.",0
.FileOpen:      db "File Error #0000",0
.SrcOpen:       db "Could not open source file.",0
.DestOpen:      db "Could not create destination file.",0
.AtSrcEnd:      db "Copy already finished before. Retry copy from beginning?",0
.WriteError:    db "Error writing to copy file. The disk may be full, removed, or inaccessible.",0
Caption:
.Unicode:       dw 'T','e','s','t',0,0
.Resume:        db "&Resume",0
.Stop:          db "&Pause",0
.Scan:          db "Scan",0 ;!!
.View:          db "View",0
.About:         db "About",0
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
CurMode:    dd 0                ;current mode of operation, reading/waiting
.Scanning   equ 1
Errors:     dd 0                ;total sector read errors
Flashes:    dd 0                ;title bar flashes remaining
FileSizeShr:dd 0                ;amount to shift size to fit under <64
SectorSize: dd 0                ;bytes per sector of source file

TcItem: ;(TC_ITEM_bare)
dd TCIF_TEXT
dd 0,0
dd 0                            ;text ptr

section bss
alignb 4
FileNamesSize equ 131072
FileNames:  resb FileNamesSize
FindData:   resb WIN32_FIND_DATAW_size
SrcPath:    resb MAX_PATH

himc:       resd 1
imehwnd:    resd 1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

Main:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create window

    api ImmCreateContext
    mov [himc],eax

    api LoadCursor, 0,IDC_ARROW
    mov [wc+WNDCLASS.hCursor],eax
    api LoadIcon, wc.BaseAddress,1
    mov [wc+WNDCLASS.hIcon],eax

    ; register window class
    debugwrite "registering class"
    api RegisterClass, wc
    ;api RegisterClassW, wc
    test eax,eax    
    mov esi,ErrMsg.NoWndClass
    jz near EndWithErrMsg
    debugwrite "register result=%X", eax

    api InitCommonControls

    ; create instance of window
    debugwrite "creating window"
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME|WS_SIZEBOX, 0,0, 400,572, NULL, NULL, wc.BaseAddress, NULL
    ;api CreateWindowExW, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME|WS_SIZEBOX, 0,0, 400,572, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    mov esi,ErrMsg.NoWindow
    jz near EndWithErrMsg
    ;mov [hwnd],eax

    api SetWindowTextW, [hwnd], Caption.Unicode
    api GetLastError
    debugwrite "error code=%d",eax

    api ImmGetDefaultIMEWnd, [hwnd]
    mov [imehwnd],eax
    api ShowWindow, eax, SW_SHOW

    api ImmAssociateContext, [hwnd],[himc]


    api ImmGetContext, [hwnd]
    api ImmSetOpenStatus, eax,TRUE
    api ImmReleaseContext, [hwnd],[himc]


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Loop
.Top:
    ;debugpause "entering main loop"

.Next:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    jz near .End
    mov eax,[msg+MSG.message]
    debugwinmsg "process msg=%X %s W=%X L=%X", eax,edx,[msg+MSG.wParam],[msg+MSG.lParam]
    api IsDialogMessage, [hwnd],msg
    ;api DispatchMessage, msg
    cmp [CurMode],dword CurMode.Scanning
    jne .Next

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
.NextFilename:

%if 0
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
    test eax,eax
    jnz .NoReadError
    inc dword [Errors]
    mov eax,[Errors]
    call NumToString
    api SetWindowText, [lblErrors],NumToString.Buffer
    ;api GetLastError
    ;debugpause "read result=%d %s<",eax,FileBuffer
    ; check for errors
.NoReadError:

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
%endif

    ; check for any pending messages
.NextPeek:
    xor eax,eax
    api PeekMessage, msg, eax,eax,eax,PM_REMOVE
    test eax,eax
    jz near .NextFilename
    cmp dword [msg+MSG.message],WM_QUIT
    je .EndAndClose
    api IsDialogMessage, [hwnd],msg
    ;api DispatchMessage, msg
    cmp [CurMode],dword CurMode.Scanning
    jne .NextPeek
    jmp .Top


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Termination
.EndAndClose:
    ;api SetFileTime, [DestHandle], CreateTime,NULL,WriteTime
    api CloseHandle, [SrcHandle]
    api CloseHandle, [DestHandle]
.End:
    ;debugpause "ending"
    api ImmDestroyContext, [himc]
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

%if 0
    cmp eax,WM_KEYDOWN
    jne .NotKey
    cmp byte [msg+MSG.wParam],VK_ESCAPE
    je near .EscPress
.NotKey:
    cmp eax,WM_TIMER
    je near .FlashTitle
    cmp eax,WM_DROPFILES
    je .FileDropped
%endif
    cmp eax,WM_COMMAND
    jne .NotCommand
    cmp word [esp+.wParam+2],BN_CLICKED
    je near .Command
.NotCommand:
    cmp eax,WM_ACTIVATE
    je near .Activate
    cmp eax,WM_CREATE
    je near .Create
    cmp eax,WM_SYSCOMMAND
    je near .Minimize
    cmp eax,WM_WINDOWPOSCHANGED
    je near .Resize
    cmp eax,WM_WINDOWPOSCHANGING
    je .RetFalse
    cmp eax,WM_DESTROY
    je .Destroy

.DefProc:
    extern DefWindowProc
    jmp [DefWindowProc]

.RetTrue:
    mov eax,TRUE
    ret 16

.Destroy:
    ;debugpause "destroying window"
    mov dword [hwnd],0
    api PostQuitMessage,0
.RetFalse:
    xor eax,eax
    ret 16

%if 0
.FileDropped:
    debugpause "File dropped"
    cmp [CurMode],CurMode.Scanning
    je .AlreadyCopying
    api DragQueryFile, [esp+.wParam+12],0, SrcFile,MAX_PATH
    call StartScan
.AlreadyCopying:
    api DragFinish, [esp+.wParam]
    debugpause "End File dropped"
    xor eax,eax
    ret 16
%endif

.Create:
    mov eax,[esp+.hwnd]
    mov [hwnd],eax
    mov [focus],eax
    ;api GetDC, eax              ;get window class display handle
    ;debugwrite "get hdc=%X",eax
    ;mov [hdc],eax
    api GetStockObject, DEFAULT_GUI_FONT
    mov [hfont],eax

    push dword tabMain
    call CreateChildWindow
    debugpause "tabmain=%d",[tabMain]
    mov dword [TcItem+TC_ITEM.pszText],Caption.Scan
    api SendMessage, [tabMain],TCM_INSERTITEM, 0,TcItem
    mov dword [TcItem+TC_ITEM.pszText],Caption.View
    api SendMessage, [tabMain],TCM_INSERTITEM, 1,TcItem
    mov dword [TcItem+TC_ITEM.pszText],Caption.About
    api SendMessage, [tabMain],TCM_INSERTITEM, 2,TcItem
    ;api GetStockObject, DEFAULT_GUI_FONT
    ;api SendMessage, [tabMain],WM_SETFONT, eax,0
    api SendMessage, [tabMain],TCM_SETITEMSIZE, 0,60|(16<<16)

    push dword txtFilePath
    call CreateChildWindow
    push dword txtCdVolume
    call CreateChildWindow
    push dword txtMediaExts
    call CreateChildWindow
    push dword lstFiles
    call CreateChildWindow
    push dword btnWaitOnVolume
    call CreateChildWindow
    push dword btnStripPath
    call CreateChildWindow

    push dword cmdScan
    call CreateChildWindow
    push dword cmdStopResume
    call CreateChildWindow
    push dword cmdDelete
    call CreateChildWindow
    push dword cmdClear
    call CreateChildWindow
    push dword cmdAbout
    call CreateChildWindow

    ;api CreateWindowEx, WS_EX_CLIENTEDGE    ,ClassNames.Static,"static test", WS_VISIBLE|WS_CHILD |WS_VSCROLL, 10,10, 80,80, [hwnd],221, wc.BaseAddress,0
    ;api CreateWindowEx, 0,ClassNames.Edit,"test", WS_VISIBLE|WS_CHILD, 10,10, 40,40, eax,221, wc.BaseAddress,0

%if 0

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
%endif

    xor eax,eax
    ret 16

.EscPress:
    cmp [CurMode],dword CurMode.Scanning
    je near StopScan
    api PostQuitMessage,1
    ret

.Command:
    mov eax,[esp+.wParam]
    push dword .RetFalse
    cmp eax,IDCANCEL
    je .EscPress
    cmp eax,IDHELP
    je .cmdAbout
    ;cmp eax
    jmp short .cmdUnfinished
%if 0
    cmp eax,cmdCopy.Id;|(BN_CLICKED<<16)
    je .cmdCopy
    cmp eax,cmdStopResume.Id
    je .cmdStopResume
    cmp eax,cmdOpen.Id
    je .cmdOpen
    cmp eax,cmdExplore.Id
    je .cmdExplore
%endif
    ret
.cmdAbout:
    api MessageBox, [hwnd],Text.About,ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret
.cmdUnfinished:
    api MessageBox, [hwnd],"Option unfinished",ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret

%if 0
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
.cmdStopResume:
    cmp dword [CurMode],CurMode.Scanning
    je near StartScan.Resume    ;resume using last file
    jmp StopScan
.cmdExplore:
    ; open temporary folder
    ; 'explorer /select,[filename]
    api GetTempPath, MAX_PATH,DestDir
    api ShellExecute, [hwnd],"open",DestDir, NULL, NULL, SW_SHOWNORMAL
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
%endif

.Activate:
    cmp word [esp+.wParam],WA_INACTIVE
    je .LoseFocus
    debugwrite "new focus hwnd=%X",[focus]
    api SetFocus, [focus]
    xor eax,eax
    ret 16

.LoseFocus:
    api GetFocus
    test eax,eax
    jz .NullFocus
    mov [focus],eax
    debugwrite "old focus hwnd=%X",eax
    xor eax,eax
.NullFocus:
    ret 16

.Minimize:
    cmp dword [esp+.wParam],SC_MINIMIZE
    jne .NotMinimize
    api GetFocus
    mov [focus],eax
    debugwrite "old focus hwnd=%X",eax
.NotMinimize:
    jmp [DefWindowProc]

.Resize:
    ;api SetWindowPos
    ;
    ;mov edx,[esp+.lParam]
    ;test dword [edx+WINDOWPOS.flags],SWP_NOSIZE
    ;jnz near .NoResize
    push ebx,esi

    api GetClientRect, [hwnd],rect
    mov ebx,[rect+RECT.bottom]
    sub ebx,[rect+RECT.top]
    mov esi,[rect+RECT.right]
    sub esi,[rect+RECT.left]

    lea eax,[esi-64]
    api SetWindowPos, [txtFilePath],0, 0,0, eax,20, SWP_NOACTIVATE|SWP_NOMOVE|SWP_NOCOPYBITS|SWP_NOZORDER
    lea eax,[esi-64]
    api SetWindowPos, [txtCdVolume],0, eax,0, 64,20, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER|SWP_NOSIZE
    api SetWindowPos, [txtMediaExts],0, 0,22, esi,20, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER

    lea edx,[ebx-24-4-16*2-4-20 -20-4]
    api SetWindowPos, [lstFiles],0, 0,44, esi,edx, SWP_NOACTIVATE|SWP_NOMOVE|SWP_NOCOPYBITS|SWP_NOZORDER

    lea edx,[ebx-28-16*1]
    api SetWindowPos, [btnStripPath],0, 0,edx, esi,16, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER
    lea edx,[ebx-28-16*2]
    api SetWindowPos, [btnWaitOnVolume],0, 0,edx, esi,16, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER

    lea edx,[ebx-24]
    api SetWindowPos, [cmdScan],0, 56*0,edx, 52,24, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER
    lea edx,[ebx-24]
    api SetWindowPos, [cmdDelete],0, 56*1,edx, 52,24, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER
    lea edx,[ebx-24]
    api SetWindowPos, [cmdStopResume],0, 56*2,edx, 52,24, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER
    lea edx,[ebx-24]
    api SetWindowPos, [cmdClear],0, 56*3,edx, 52,24, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER
    lea edx,[ebx-24]
    api SetWindowPos, [cmdAbout],0, 56*4,edx, 52,24, SWP_NOACTIVATE|SWP_NOCOPYBITS|SWP_NOZORDER

    ;api SetWindowPos, [hwnd],HWND_TOPMOST, eax,eax, eax,eax, SWP_NOACTIVATE|SWP_NOMOVE|SWP_NOSIZE

    pop ebx,esi
.NoResize:
    xor eax,eax
    ret 16


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
    %ifdef debug
    api GetLastError
    debugwrite "exiting process from fatal error: %d, %s", eax,esi
    %endif
    api MessageBox, [hwnd],esi,ProgramTitle,MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL ;|MB_SETFOREGROUND
    api DestroyWindow, [hwnd]
    api ExitProcess, -1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; enable/disable buttons
; open source file
; open/create destination file
; resume copy and sync file pointers
StartScan:
    cmp [CurMode],dword CurMode.Scanning
    je near .AlreadyScanning




.AlreadyScanning:

    ret


;    api SendMessage, [lstBgFiles],LB_RESETCONTENT,eax,eax
;    xor eax,eax
;    api SendMessage, [lstBgFiles],WM_SETREDRAW,eax,eax
;    api SendMessage, [lstBgFiles],LB_INSERTSTRING,-1,TempData
;    api SendMessage, [lstBgFiles],WM_SETREDRAW,1,0


%if 0
    mov dword [Errors],0
    api SetWindowText, [lblErrors],NullString

.Resume:
    push ebx,esi,edi

    debugpause "Source file name = %s",SrcFile

    mov esi,SrcFile
    api SetWindowText, [txtFilename],esi
    api SendMessage, [txtFilename], EM_SETSEL, 0,-1

    ; open unbufferred source file
    api CreateFile, esi, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING|FILE_FLAG_SEQUENTIAL_SCAN, NULL
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
    jne near StopScan.CloseOnly
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
    inc dword [CurMode]

.End:
    pop ebx,esi,edi
%endif
    mov dword [CurMode],CurMode.Scanning
.AlreadyCopying:
    ret

.FileError: ;(esi=text message)
    call FormatFileError
    api MessageBox, [hwnd],esi,ErrMsg.FileOpen,MB_ICONEXCLAMATION|MB_SETFOREGROUND
    ret
    ;jmp short StopScan.CloseOnly


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
StopScan:
%if 0
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
    pop ebx,esi,edi
%endif
    mov [CurMode],dword FALSE
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
