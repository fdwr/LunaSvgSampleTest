; Set Desktop Background (c)PeekinSoft
; Dwayne Robinson (FDwR@hotmail.com)
; 2002-06-26 Born
; 2002-06-27 Updated
;
; Purpose:
;   Allows you to change the background of any user, even if you are not
;   logged in as that user (unsure if Win2k's security will allow it though).
;

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
%define UseFileSystem
%define UseWinRegistry
%define UseWindowSysVars
%define UseKeyboard
%include "mywininc.asm"         ;standard Windows constants, structs...


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:   db "Set Desktop Background 1.0 (Beta)" ;,0
NullString:     db 0
ClassNames:
.Program:       db "PknSetDeskBg",0
.Button:        db "BUTTON",0
.Label:         db "STATIC",0
.List:          db "LISTBOX",0
;.Tooltip:      db "TOOPTIPS_CLASS",0
;.Edit:         db "EDIT",0
;.Progress:     db "msctls_progress32",0
ErrMsg:
.NoWindow:      db "Failed to create window.",0
Text:
.About:         db "It is a simple enough task to change your own user wallpaper, but how could you change other user's backgrounds or the default user background? "
                db "This program allows you to select the desktop backgrounds for multiple users on a workstation, without needing to log in as each user or use the registry editor."
                db 10,10
                db "First select the user whose background you want to change; then select the desired image from the file list, and choose Change. "
                db "You can also open the open the previewed image with the default image viewer/editor, explore the current directory, and drop files onto the program."
                db 10,10
                db "Dwayne Robinson",10
                db "FDwR@hotmail.com",10
                db "PeekinSoft 2002-06-26"
                db 0
.ParentFolder:  db "( go up to parent folder )",0
.WallPaperKey:  db "\Control Panel\desktop",0
.WallPaperKey_size equ $-.WallPaperKey
.WallPaperValue:db "Wallpaper",0
.DefaultUser:   db ".Default",0,0,0,0
.DefaultUser_size equ $-.DefaultUser
.ShellOpen:     db "open",0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Window related vars
section data

section data
align 4, db 0
hwnd:   dd 0                    ;window handle
hdc:    dd 0                    ;class device context
fhwnd:  dd 0                    ;hwnd of control with focus
hfont:  dd 0                    ;default font to use for controls
hkey:   dd 0                    ;generic handle for registry use

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

;rect:
;point:
;dd 0,            0             ;left,top
;dd Screen.Width, Screen.Height ;right,bottom

DefWndControl lblBgPath,        100, ClassNames.Label,  NullString,         WS_CHILD|WS_VISIBLE,                184+16,8, 268,16
DefWndControl lstUsers,         150, ClassNames.List,   NullString,         WS_CHILD|WS_VISIBLE|WS_VSCROLL|WS_TABSTOP|WS_GROUP|LBS_NOINTEGRALHEIGHT|LBS_NOTIFY|LBS_SORT,8,16+168, 184,72
DefWndControl lstBgFiles,       151, ClassNames.List,   NullString,         WS_CHILD|WS_VISIBLE|WS_VSCROLL|WS_TABSTOP|         LBS_NOINTEGRALHEIGHT|LBS_NOTIFY|LBS_SORT|LBS_WANTKEYBOARDINPUT, 184+16,16+16,  268,224
DefWndControl cmdChange,       IDOK, ClassNames.Button, "&Change",          WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_DISABLED|WS_GROUP|BS_DEFPUSHBUTTON, 8+72*0,8*33, 64,24
DefWndControl cmdOpen,          201, ClassNames.Button, "&Open",            WS_CHILD|WS_VISIBLE|WS_TABSTOP,     8+72*1,8*33, 64,24
DefWndControl cmdExplore,       202, ClassNames.Button, "&Explore",         WS_CHILD|WS_VISIBLE|WS_TABSTOP,     8+72*2,8*33, 64,24
DefWndControl cmdAbout,      IDHELP, ClassNames.Button, "&About",           WS_CHILD|WS_VISIBLE|WS_TABSTOP,     8+72*3,8*33, 64,24
DefWndControl cmdClose,    IDCANCEL, ClassNames.Button, "Close",            WS_CHILD|WS_VISIBLE|WS_TABSTOP,     8+72*4,8*33, 64,24


section bss
msg:    resb MSG_size
ps:     resb PAINTSTRUCT_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Global program vars

section data
align 4, db 0
PreviewBmp:     dd 0            ;HBITMAP of the previewed image (152x112)
PreviewBmpBdr:  dd 0            ;HBITMAP of the border around the image (184x169)
PreviewDC:      dd 0            ;memory device context
DummyVar:       dd 0,0          ;variable to simply waste return value
ListActivate:   dd TRUE         ;selected list choice with mouse

TempDataSize:   dd 0
TempData_size   equ 1024        ;miscellaneous temporary data
section bss
alignb 4
FindFileData:
TempData:       resb TempData_size

BgFileName:     resb MAX_PATH   ;wallpaper filename in preview
BgFilePath:     resb MAX_PATH   ;path of file list
CurUser:        resb MAX_PATH   ;user currently logged in


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
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_MINIMIZEBOX|WS_SYSMENU|WS_DLGFRAME|WS_VISIBLE, CW_USEDEFAULT,CW_USEDEFAULT, 8*60,8*40, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    ;mov [hwnd],eax

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Misc init

    ; prepare preview area
    xor eax,eax
    ;api LoadBitmap, wc.BaseAddress,2
    api LoadImage, wc.BaseAddress,2, IMAGE_BITMAP, eax,eax, LR_LOADMAP3DCOLORS|LR_LOADTRANSPARENT|LR_SHARED
    mov [PreviewBmpBdr],eax
    api CreateCompatibleDC, NULL  ;get screen compatible device context
    mov [PreviewDC],eax
    api SelectObject, eax,[PreviewBmpBdr]

    ; fill user list
    xor ebx,ebx
    mov [BgFilePath],ebx
    mov [BgFileName],ebx
    jmp short .FirstUser
.NextUser:
    inc ebx
    api SendMessage, [lstUsers],LB_ADDSTRING,0,TempData
.FirstUser:
    xor eax,eax
    mov dword [TempDataSize],TempData_size
    api RegEnumKeyEx, HKEY_USERS,ebx, TempData,TempDataSize, eax,eax,eax, DummyVar
    cmp eax,ERROR_SUCCESS
    je .NextUser

    ; predraw window while waiting for image to load and files to be read
;.CheckPaint:
;    xor eax,eax
;    api PeekMessage, msg, eax,WM_PAINT,WM_PAINT,PM_REMOVE
;    test eax,eax
;    jz .NoMorePaint
;    api DispatchMessage, msg
;    jmp short .CheckPaint
;.NoMorePaint:
    api UpdateWindow, [hwnd]

    ; select current user
    mov dword [TempDataSize],MAX_PATH
    api GetUserName, CurUser,TempDataSize
    test eax,eax
    jnz .SelectUser
    mov esi,Text.DefaultUser
    mov edi,CurUser
    mov ecx,Text.DefaultUser_size/4
    ;cld
    rep movsd
.SelectUser:
    api SendMessage, [lstUsers],LB_SELECTSTRING,-1,CurUser
    call MsgProc.UserSelected

    mov esi,BgFilePath
    api GetWindowsDirectory, esi,MAX_PATH
    call GetStringLength
    cmp byte [esi+ecx-1],'\'
    je .SlashAppended
    mov dword [esi+ecx],'\'
.SlashAppended:
    call FillBgFileNames


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Message Loop

    debugwrite "entering main loop"
    jmp short .Next

.Top:
    mov eax,[msg+MSG.message]
    debugwinmsg "process msg=%X %s W=%X L=%X", eax,edx,[msg+MSG.wParam],[msg+MSG.lParam]
    api IsDialogMessage, [hwnd],msg
    ;api DispatchMessage, msg ;(IsDialogMessage does this)
.Next:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    ;js .MsgError (don't bother checking for errors)
    jnz .Top

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Termination

.End:
    debugwrite "ending"
    api DeleteDC, [PreviewDC]
    api DeleteObject, [PreviewBmpBdr]

    api DestroyWindow, [hwnd]
    api ExitProcess, [msg+MSG.wParam]


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]

    cmp eax,WM_COMMAND
    jne .NotCommand
    cmp word [esp+.wParam+2],BN_CLICKED
    je near .ButtonPushed
    cmp word [esp+.wParam+2],LBN_SELCHANGE
    je near .ListSelected
.NotCommand:
    cmp eax,WM_VKEYTOITEM
    jne .NotListPress
    mov ecx,[lstBgFiles]
    cmp [esp+.lParam],ecx
    je near .ListKeyPressed
.NotListPress:
    cmp eax,WM_PAINT
    je near .Paint
    cmp eax,WM_DROPFILES
    je near .FileDropped
    cmp eax,WM_ACTIVATE
    je near .Activate
    cmp eax,WM_HELP
    je near .cmdHelp
    cmp eax,WM_DESTROY
    je .Destroy
    cmp eax,WM_CREATE
    je .Create
.DefProc:
    jmp [DefWindowProc]

.RetTrue:
    mov eax,TRUE
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Destroy:
    debugwrite "destroying window"
    xor eax,eax
    mov [hwnd],eax
    api PostQuitMessage,eax
.RetFalse:
    xor eax,eax
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Create:
    mov eax,[esp+.hwnd]
    mov [hwnd],eax
    mov [fhwnd],eax
    api GetDC, eax              ;get window class display handle
    debugwrite "get hdc=%X",eax
    mov [hdc],eax
    api GetStockObject, DEFAULT_GUI_FONT
    mov [hfont],eax

    ; create lists
    push dword lstUsers
    call CreateChildWindow
    push dword lstBgFiles
    call CreateChildWindow

    push dword lblBgPath
    call CreateChildWindow

    ; create buttons
    push dword cmdChange
    call CreateChildWindow
    push dword cmdOpen
    call CreateChildWindow
    push dword cmdExplore
    call CreateChildWindow
    push dword cmdAbout
    call CreateChildWindow
    push dword cmdClose
    call CreateChildWindow

    mov eax,[lstUsers]
    mov [fhwnd],eax

    xor eax,eax
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Paint:
    ;debugmsg "paint background"
    push ebx,esi,edi
    api BeginPaint, [hwnd],ps

    xor eax,eax
    api BitBlt, [hdc], 8,8, 184,169, [PreviewDC],eax,eax, SRCCOPY

    api EndPaint, [hwnd],ps
    pop ebx,esi,edi
    xor eax,eax
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Activate:
    cmp word [esp+.wParam],WA_INACTIVE
    je .LoseFocus
    debugwrite "new focus hwnd=%X",[fhwnd]
    api SetFocus, [fhwnd]
    xor eax,eax
    ret 16
.LoseFocus:
    api GetFocus
    test eax,eax
    jz .NullFocus
    mov [fhwnd],eax
    debugwrite "old focus hwnd=%X",eax
    xor eax,eax
.NullFocus:
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; RetFalse on stack
.ButtonPushed:
    mov eax,[esp+.wParam]
    push dword .RetFalse
    cmp eax,IDCANCEL
    je .EscPress
    cmp eax,cmdOpen.Id
    je .cmdOpen
    cmp eax,cmdAbout.Id
    je .cmdAbout
    cmp eax,cmdExplore.Id
    je .cmdExplore
    cmp eax,cmdChange.Id
    je .cmdChange
    ret

.EscPress:
    api PostQuitMessage,0
    ret

.cmdHelp:
    push dword .RetTrue
.cmdAbout:
    api MessageBox, [hwnd],Text.About,ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret

.cmdOpen:
    xor eax,eax
    api ShellExecute, [hwnd],Text.ShellOpen,BgFileName, eax,eax, SW_SHOWNORMAL
    ret

.cmdExplore:
    api ShellExecute, [hwnd],Text.ShellOpen,BgFilePath, NULL, NULL, SW_SHOWNORMAL
    ret

.cmdChange:
    call .BuildUserBgKey

    ; check if current user or different user not logged in now
    push edi,edi
    mov esi,CurUser
    call GetStringLength
    mov edi,TempData
    rep cmpsb
    jne .DifferentUser
    api SystemParametersInfo, SPI_SETDESKWALLPAPER, 0,BgFileName,SPIF_UPDATEINIFILE
    jmp short .WallpaperChanged

.DifferentUser:
    api RegOpenKeyEx, HKEY_USERS,TempData,0,KEY_SET_VALUE,hkey
    mov dword [TempDataSize],MAX_PATH
    mov esi,TempData
    call GetStringLength
    inc ecx                     ;include terminarting null character
    api RegSetValueEx, [hkey],Text.WallPaperValue, 0,REG_SZ, BgFileName,ecx
    api RegCloseKey, [hkey]

.WallpaperChanged:
    pop esi,edi
    api EnableWindow, [cmdChange],FALSE
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; RetFalse on stack
.ListSelected:
    cmp dword [esp+.wParam],lstUsers.Id|(LBN_SELCHANGE<<16)
    push dword .RetFalse
    je near .UserSelected

.BgFileSelected:
    ; get selected list text
    xor eax,eax
    api SendMessage, [lstBgFiles],LB_GETCARETINDEX,eax,eax
    push eax
    api SendMessage, [lstBgFiles],LB_GETTEXT,eax,TempData
    pop eax

    ; was choice selected by key or mouse?
    cmp dword [ListActivate],TRUE
    mov dword [ListActivate],TRUE
    je .ListActivated
    cmp byte [TempData],'<'
    je .ListInactivate
    cmp byte [TempData],'('
    jne .ListActivated
.ListInactivate:
    ret
.ListActivated:

    ; check if selecting drive, folder, file, or retreating a level
    ; (eax=index of list item)
    cmp byte [BgFilePath],0
    je near .ChangeDrive
    test eax,eax
    jle near .RetreatPath

    ; either folder or file
    push esi,edi
    mov esi,BgFilePath
    call GetStringLength
    cmp byte [TempData],'<'
    jne .SelectedFile

    ; folder selected
    lea edi,[esi+ecx]
    neg ecx
    mov esi,TempData+1
    add ecx,MAX_PATH            ;max path - path filename length
    ;cld
    rep movsb

    mov esi,BgFilePath
    call GetStringLength
    mov byte [esi+ecx-1],'\'    ;replace trailing '>' with '\'
    pop esi,edi
    jmp FillBgFileNames

.ChangeDrive:
    mov eax,'  \'
    mov ax,[TempData+1]
    mov [BgFilePath],eax
    jmp FillBgFileNames
    ;ret

.RetreatPath:
    push esi,edi
    mov esi,BgFilePath
    call GetStringLength
    cmp ecx,3
    jbe .RetreatPathTop
    mov [esi+ecx-1],byte 0      ;remove trailing slash
    call GetFileName
.RetreatPathTop:
    mov [esi],byte 0            ;remove separating slash
    pop esi,edi
    jmp FillBgFileNames
    ;ret

.SelectedFile:
    ; concatenate current path with selected file
    mov edx,MAX_PATH
    mov edi,BgFileName
    sub edx,ecx
    ;cld
    rep movsb
    mov ecx,edx
    mov esi,TempData
    rep movsb
    pop esi,edi
    api EnableWindow, [cmdChange],TRUE
    jmp LoadBgImageFile
    ;ret

.UserSelected:
    call .BuildUserBgKey

    api RegOpenKeyEx, HKEY_USERS,TempData,0,KEY_QUERY_VALUE,hkey
    mov dword [TempDataSize],MAX_PATH
    api RegQueryValueEx, [hkey],Text.WallPaperValue, 0,DummyVar, BgFileName,TempDataSize
    api RegCloseKey, [hkey]

    api SendMessage, [lstBgFiles],LB_SETCURSEL,-1,0
    jmp LoadBgImageFile
    ;ret

.BuildUserBgKey:
    push edi,edi
    xor eax,eax
    api SendMessage, [lstUsers],LB_GETCARETINDEX,eax,eax
    api SendMessage, [lstUsers],LB_GETTEXT,eax,TempData
    mov esi,TempData
    call GetStringLength
    lea edi,[esi+ecx]
    mov esi,Text.WallPaperKey
    mov ecx,Text.WallPaperKey_size
    ;cld
    rep movsb
    pop esi,edi
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.ListKeyPressed:
    xor eax,eax
    cmp word [esp+.wParam],VK_SPACE
    jne .NotListSpace
    mov dword [ListActivate],TRUE
    call .BgFileSelected
    mov eax,-2
    ret
.NotListSpace:
    mov dword [ListActivate],FALSE

    cmp byte [BgFilePath],0
    je .NotListBkspc
    cmp word [esp+.wParam],VK_BACK
    jne .NotListBkspc
    call .RetreatPath
    mov eax,-2
    ret
.NotListBkspc:
    mov eax,-1
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.FileDropped:
    api DragQueryFile, [esp+.wParam+12],0, BgFileName,MAX_PATH
    api DragFinish, [esp+.wParam]
    api EnableWindow, [cmdChange],TRUE
    push dword .RetFalse
    jmp LoadBgImageFile


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Copies a control structure onto parameter stack and calls CreateWindowEx.
; Sets the font for each control, assumes the standard GUI font has already
; been obtained.
CreateChildWindow:
    push esi,edi
    mov esi,[esp+12]
    xor eax,eax                 ;null window creation data
    push eax
    push dword wc.BaseAddress
    push dword [esi+WndControlStruct.hId]
    push dword [hwnd]
    ;cld
    sub esp,byte 7*4
    add esi,byte WndControlStruct.lpClassName
    mov ecx,7
    mov edi,esp
    rep movsd
    ;push eax                    ;no ex style
    push dword WS_EX_NOPARENTNOTIFY|WS_EX_STATICEDGE ;WS_EX_CLIENTEDGE
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
; Fills the list with the names of image files, or drives if at top of
; heirarchy.
FillBgFileNames:
    push ebx,esi,edi

    ; clear list box & prevent flicker
    xor eax,eax
    api SendMessage, [lstBgFiles],LB_RESETCONTENT,eax,eax
    xor eax,eax
    api SendMessage, [lstBgFiles],WM_SETREDRAW,eax,eax
    api SetWindowText, [lblBgPath],BgFilePath

    cmp byte [BgFilePath],0
    je near .Drives

    mov esi,BgFilePath
    call GetFileName
    mov dword [esi],'*'
    api FindFirstFile, BgFilePath,FindFileData
    mov byte [esi],0
    test eax,eax
    mov ebx,eax
    js .LastFile

.NextFile:
    ;test attributes
    ;if directory, add to list with <xxx>
    ;else file, simply add to list
    mov esi,FindFileData+WIN32_FIND_DATA.cFileName
    test byte [FindFileData+WIN32_FIND_DATA.dwFileAttributes],FILE_ATTRIBUTE_DIRECTORY
    jz .NotDir
    cmp byte [esi],'.'
    je .SkipFile
    call GetStringLength        ;find end of string
    mov dword [esi+ecx],'>'
    dec esi
    mov byte [esi],'<'
    jmp short .AddFile
.NotDir:
    call GetFileExtension
    cmp eax,'BMP'
    je .AddFile
    cmp eax,'JPG'
    je .AddFile
    cmp eax,'GIF'
    jne .SkipFile
.AddFile:
    api SendMessage, [lstBgFiles],LB_ADDSTRING,0,esi
.SkipFile:
    api FindNextFile, ebx,FindFileData
    test eax,eax
    jnz .NextFile
.LastFile:

    api FindClose, ebx
    api SendMessage, [lstBgFiles],LB_INSERTSTRING,0,Text.ParentFolder

.End:
    api SendMessage, [lstBgFiles],WM_SETREDRAW,1,0
    xor eax,eax
    api InvalidateRect, [lstBgFiles],eax,eax
    pop ebx,esi,edi
    ret

.Drives:
    api GetLogicalDrives
    mov ebx,eax
    mov dword [TempData],'<A:>' ;start with first drive
    mov byte [TempData+4],0     ;append null
    jmp short .FirstDrive
.AddDrive:
    api SendMessage, [lstBgFiles],LB_INSERTSTRING,-1,TempData
.SkipDrive:
    inc byte [TempData+1]
.FirstDrive:
    shr ebx,1
    jc .AddDrive
    jnz .SkipDrive
    jmp short .End


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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Returns extension without period and top byte null.
;
; (esi=filename zstring)
; (eax=extension, zf=no extension; esi=filename)
GetFileExtension:
    mov edi,esi     ;copy source for string length search
    mov ecx,MAX_PATH;FilePathMaxLen
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=source)
; (ecx=length, zf=zero length; esi,edx)
GetStringLength:
    mov eax,1024            ;maximum length of characters
; (al=character to search for, eax=maximum length of characters to search)
.UntilChar:
    mov ecx,eax             ;make a copy of max length for later
    mov edi,esi             ;copy source for string length search
    ;cld                    ;as always, look forward
    repne scasb             ;search for the end, until character is found
    ;neg ecx                ;;get negative count
    ;dec ecx                ;;minus the character at the end
    not ecx                 ;negate count and subtract character at the end
    add ecx,eax             ;get length (conveniently sets zf)
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Loads the user background image into the preview area.
; [BgFileName]
LoadBgImageFile:
    api LoadImage, wc.BaseAddress,BgFileName, IMAGE_BITMAP, 152,112, LR_LOADFROMFILE
    push eax
    api CreateCompatibleDC, NULL  ;get screen compatible device context
    push eax
    api SelectObject, eax,[esp+4]
    xor eax,eax
    api BitBlt, [PreviewDC], 16,17, 152,112, [esp+12],eax,eax, SRCCOPY
    api DeleteDC ;dc on stack already
    api DeleteObject ;hbitmap on stack already

    lea eax,[esp-16]
    api InvalidateRect, [hwnd],eax,0, 8,8, 184,169
    add esp,byte 16
    ret
