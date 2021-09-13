; No Touch!
; Dwayne Robinson
; 2002-10-24 / 2003-02-03
;
;

[section code code]
[section data data]
[section text data]
[section bss bss]
global Main

;%define debug
%define UseWindowStyles
%define UseWindowMsgs
%define UseWindowGfx
%define UseResources
%define UseWindowGfx
%define UseKeyboard
%define UseWindowHooks
%define UseWindowSysVars
%define UseMultimedia
%include "mywininc.asm"         ;standard Windows constants, structs...

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
align 4, db 0
hwnd:       dd 0            ;window handle
hdc:        dd 0            ;class device context
hbmp:       dd 0            ;background bitmap
hbdc:       dd 0            ;bitmap device context
Active:     dd 0            ;program is active or not
ScrMode:    dd 0
HotKeyTime: dd 0
LastMsg:    dd 0            ;ptr to last message displayed

wc:
.BaseAddress    equ 400000h ;base address of program (Windows module handle)
istruc WNDCLASS
at WNDCLASS.style,         dd CS_NOCLOSE|CS_OWNDC
at WNDCLASS.lpfnWndProc,   dd MsgProc
at WNDCLASS.cbClsExtra,    dd 0
at WNDCLASS.cbWndExtra,    dd 0
at WNDCLASS.hInstance,     dd .BaseAddress ;(default image base is at 4MB)
at WNDCLASS.hIcon,         dd NULL
at WNDCLASS.hCursor,       dd NULL
at WNDCLASS.hbrBackground, dd NULL ;COLOR_BTNFACE + 1
at WNDCLASS.lpszMenuName,  dd NULL
at WNDCLASS.lpszClassName, dd ProgramClass
iend

rect:
point:
dd 0, 0 ;left,top
dd 0, 0 ;right,bottom

LF_FACESIZE equ 32
logfont:
.lfHeight               dd 72
.lfWidth                dd 0
.lfEscapement           dd 0
.lfOrientation          dd 0
.lfWeight               dd 700
.lfItalic               db 0
.lfUnderline            db 0
.lfStrikeOut            db 0
.lfCharSet              db 0
.lfOutPrecision         db 0
.lfClipPrecision        db 0
.lfQuality              db 0
.lfPitchAndFamily       db 0
.lfFaceName             db "Arial",0 ;resb LF_FACESIZE
align 4,db 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section bss
msg:        resb MSG_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:
ProgramClass:   db "PeekinPcLock3",0
ErrMsg:
.Fatal:         db "No Touch: Fatal Error",0
.NoWindow:      db "Failed to create window"
;StartMessage:   db "Gaurdian Mode",0
StartMessage:   db "-",0
StartMessageSize equ $-StartMessage-1
;LockMessage:    db "Touch not things",13,"that are not yours",0
;LockMessage:    db ";-Ş",0
;LockMessageSize equ $-LockMessage-1
LockMessage:    db "This computer is locked",13,10,"It is busy rendering...",13,10,"Thanks, Dwayne",0
LockMessageSize equ $-LockMessage-1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

Main:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create window

    ; if previous instance exists, simply set focus to it and exit program
    api FindWindow, ProgramClass, NULL
    test eax,eax
    jz .NewInstance
    api ShowWindowAsync, eax, SW_SHOWMAXIMIZED
    api ExitProcess, -1
.NewInstance:

    ; register window class
    debugwrite "registering class"
    api LoadCursor, 0,IDC_ARROW
    mov [wc+WNDCLASS.hCursor],eax
    api LoadIcon, wc.BaseAddress,1
    mov [wc+WNDCLASS.hIcon],eax
    api RegisterClass, wc
    debugwrite "register result=%X", eax
    test eax,eax
    mov esi,ErrMsg.NoWindow
    jz near EndWithErrMsg

    ; create instance of window
    debugwrite "creating window"
    api CreateWindowEx, WS_EX_TOPMOST|WS_EX_TOOLWINDOW|WS_EX_TRANSPARENT, ProgramClass, NULL, WS_POPUP|WS_VISIBLE, 8192,8192, 2048,2048, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    ;mov [hwnd],eax

    ; get window class display handle
    api GetDC, eax
    mov [hdc],eax
    debugwrite "get hdc=%X",eax
    api CreateFontIndirect, logfont
    api SelectObject, [hdc],eax
    api SetTextColor, [hdc], 00AFFF80h ;<-green  0FF8FCFh<-blue
    ;api SetBkColor, [hdc],0E0A0C0h
    api SetBkMode, [hdc],BKMODE_TRANSPARENT

    ; make visible and display message
    xor eax,eax
    api SetWindowPos, [hwnd], eax, eax,eax, eax,eax, SWP_NOCOPYBITS|SWP_NOREDRAW|SWP_NOSIZE|SWP_NOZORDER
    api Sleep, 100
    push dword StartMessageSize
    push dword StartMessage
    call ShowUserMsg

    ; bring back upon pressing Ctrl+Shift+Z
    api RegisterHotKey, 0,32173,MOD_CONTROL|MOD_SHIFT,VK_Z

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Loop
    debugwrite "entering main loop"
    jmp short .GetMsg
.Next:
    mov eax,[msg+MSG.message]
    ;debugwinmsg "process msg=%X %s W=%X L=%X", eax,edx,[msg+MSG.wParam],[msg+MSG.lParam]
    cmp eax,WM_KEYFIRST
    jb .NotKey
    cmp eax,WM_KEYLAST
    jbe near .KeyPress
.NotKey:
    cmp eax,WM_LBUTTONDOWN
    je near .MouseClick
    cmp eax,WM_TIMER
    je near .FrameUpdate
    cmp eax,WM_HOTKEY
    je .HotKey
.Dispatch:
    api DispatchMessage, msg
.GetMsg:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    jnz .Next

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Termination
.End:
    ;api UnhookWindowsHookEx, [hkbd]

    call ShowUserMsg.Hide

    xor eax,eax
    api SystemParametersInfo, SPI_SETSCREENSAVERRUNNING,eax,ScrMode,eax

    xor eax,eax
    api UnregisterHotKey, eax,eax ;0,0
    xor eax,eax
    api SetWindowPos, [hwnd], eax, 8192,8192, eax,eax, SWP_NOCOPYBITS|SWP_NOREDRAW|SWP_NOSIZE|SWP_SHOWWINDOW|SWP_NOZORDER
    api DestroyWindow, [hwnd]
    api ExitProcess,[msg+MSG.wParam]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.HotKey:
    api SetForegroundWindow, [hwnd]
    api ShowWindow, [hwnd],SW_SHOW
    xor eax,eax
    api SetWindowPos, [hwnd], eax, eax,eax, eax,eax, SWP_NOCOPYBITS|SWP_NOREDRAW|SWP_NOSIZE|SWP_NOZORDER
    mov eax,[msg+MSG.time]
    add eax,1000
    mov [HotKeyTime],eax

    push dword StartMessageSize
    push dword StartMessage
    call ShowUserMsg
    ;api PlaySound, "notouch on.wav", NULL, SND_ASYNC|SND_FILENAME
    ;api MessageBox, [hwnd],StartMessage,StartMessage,MB_OK|MB_SETFOREGROUND|MB_TOPMOST|MB_ICONEXCLAMATION|MB_TASKMODAL|MB_DEFBUTTON2
    jmp .GetMsg

.MouseClick:
.KeyDown:
    push dword LockMessageSize
    push dword LockMessage
    call ShowUserMsg
    ;api MessageBeep, MB_ICONEXCLAMATION
    ;api PlaySound, "notouch pleh.wav", NULL, SND_ASYNC|SND_FILENAME|SND_NOSTOP
    jmp .GetMsg

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.FrameUpdate:
    call ShowUserMsg.Hide
    api SetWindowPos, [hwnd],HWND_TOPMOST, 0,0,0,0, SWP_NOCOPYBITS|SWP_NOMOVE|SWP_NOSIZE
    ;api InvalidateRect, NULL,rect,TRUE
    ;api MessageBox, [hwnd],StartMessage,StartMessage,MB_OK|MB_SETFOREGROUND|MB_TOPMOST|MB_ICONEXCLAMATION|MB_TASKMODAL|MB_DEFBUTTON2
    jmp .GetMsg

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.KeyPress:
    mov cl,[msg+MSG.wParam]
    cmp cl,VK_F12
    je near .End
    cmp cl,VK_F11
    je near .Hide
    cmp dword [Active],FALSE
    je near .GetMsg
    cmp eax,WM_KEYDOWN
    jne near .GetMsg
    mov eax,[msg+MSG.time]
    cmp eax,[HotKeyTime]
    js near .GetMsg
    jmp .KeyDown
.Hide:

%if 0
    push ebx
    mov ebx,[hwnd]
.HideCheckNext:
    api GetWindow, ebx,GW_HWNDNEXT
    test eax,eax
    mov ebx,eax
    jz .HideCheckEnd
    api IsWindowEnabled,eax
    debugwrite "ebx=%X eax=%d",ebx,eax
    test eax,eax
    jz .HideCheckNext
.HideCheckEnd:
    api SetForegroundWindow, ebx
    pop ebx

    api GetDesktopWindow
    api GetWindow, eax,GW_HWNDLAST
    api SetForegroundWindow, eax

%endif

    call ShowUserMsg.Hide
    ;api PlaySound, "notouch off.wav", NULL, SND_ASYNC|SND_FILENAME

    xor eax,eax
    api SetWindowPos, [hwnd], eax, 8192,8192, eax,eax, SWP_NOCOPYBITS|SWP_NOREDRAW|SWP_NOSIZE|SWP_SHOWWINDOW|SWP_NOZORDER|SWP_NOACTIVATE
    api ShowWindow, [hwnd],SW_HIDE
    ;api GetDesktopWindow
    ;api SetForegroundWindow, eax
    ;api GetWindow, [hwnd],GW_HWNDNEXT
    ;api FindWindowEx, NULL,NULL, ShellTrayWnd,NULL
    ;api SetForegroundWindow, eax
    jmp .GetMsg

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    ;debugwinmsg "win msg=%X %s W=%X L=%X %d", eax,edx,[esp+.wParam+4],[esp+.lParam],esp
    cmp eax,WM_CREATE
    je near .Created
    cmp eax,WM_CLOSE
    je near .Ignore;.Close
    cmp eax,WM_SYSCOMMAND
    je near .DisableScreensaver
    ;cmp eax,WM_QUERYENDSESSION
    ;je near .QueryEndSession
    ;cmp eax,WM_PAINT
    ;je near .Paint
    cmp eax,WM_WINDOWPOSCHANGING
    je .RetFalse
    cmp eax,WM_WINDOWPOSCHANGED
    je .RetFalse
    cmp eax,WM_MOVING
    je .RetTrue
    cmp eax,WM_DESTROY
    je .Destroy
    cmp eax,WM_ERASEBKGND
    je .RetTrue
    cmp eax,WM_ACTIVATEAPP
    je .ChangeFocus
    ;cmp eax,WM_NCACTIVATE
    ;je .ChangeFocus
    ;cmp eax,...

    extern DefWindowProc
    jmp [DefWindowProc]

.RetTrue:
    mov eax,TRUE
    ret 16

.Destroy:
    debugwrite "destroying window"
    api PostQuitMessage,0
.RetFalse:
    xor eax,eax
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.ChangeFocus:
    cmp word [esp+.wParam],FALSE
    je near .LoseFocus
.GainFocus:
    api SystemParametersInfo, SPI_SETSCREENSAVERRUNNING,TRUE,ScrMode,0
    ;api SetTimer,[hwnd],1,330000,NULL   ;30 times per second, no callback
    mov dword [Active],TRUE
    ;getsystemmetrics SM_CXSCREEN
    ;getsystemmetrics SM_CXSCREEN
    xor eax,eax
    ret 16
.LoseFocus:
    ;api KillTimer,[hwnd],1      ;destroy 30 tick per second timer
    ;api PeekMessage, msg,0,WM_TIMER,WM_TIMER,PM_REMOVE
    xor eax,eax
    api SystemParametersInfo, SPI_SETSCREENSAVERRUNNING,eax,ScrMode,eax
    ;api SetWindowPos, [hwnd],HWND_TOPMOST, 0,0,0,0, SWP_NOCOPYBITS|SWP_NOMOVE|SWP_NOSIZE
    xor eax,eax
    mov dword [Active],eax ;FALSE
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Created:
    mov eax,[esp+.hwnd]
    mov [hwnd],eax
.QueryEndSession:               ;return FALSE to stop shut down
.Ignore:
    xor eax,eax
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Close:
    cmp dword [Active],TRUE
    je .Ignore
    jmp [DefWindowProc]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.DisableScreensaver:
    mov eax,[esp+.wParam]
    and eax,0FFFFFFF0h
    ;cmp eax,SC_SCREENSAVE
    ;je .Ignore
    ;cmp eax,SC_MONITORPOWER
    ;je .Ignore
    jmp [DefWindowProc]


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ShowUserMsg:
    ; if different, hide previous message and show new, else ignore
    mov esi,[esp+4]
    cmp [LastMsg],esi
    je near .RefreshTimer
    call .Hide

    mov esi,[esp+4]
    mov ebx,[esp+8]
    mov [LastMsg],esi

    ; (esi=message ptr, ebx=message length)
  %if 1
    ; determine message size
    mov [rect+RECT.top],dword 0
    mov [rect+RECT.left],dword 0
    ;mov [rect+RECT.bottom],dword 0
    ;mov [rect+RECT.right],dword 0
    api DrawText, [hdc], esi,ebx, rect,DT_CALCRECT|DT_NOPREFIX|DT_NOCLIP

    ; create a bitmap to hold the background pixels
    api CreateCompatibleBitmap, [hdc],[rect+RECT.right],[rect+RECT.bottom]

    debugwrite "CreateCompatibleBitmap=%d",eax
    mov [hbmp],eax
    ;api GetDesktopWindow
    api CreateCompatibleDC, [hdc]
    mov [hbdc],eax
    api SelectObject, eax,[hbmp]

    ; calculate screen offset to center horizontally and vertically
    api GetSystemMetrics,SM_CXSCREEN
    sub eax,[rect+RECT.right]
    sar eax,1
    add [rect+RECT.left],eax
    add [rect+RECT.right],eax
    api GetSystemMetrics,SM_CYSCREEN
    sub eax,[rect+RECT.bottom]
    sar eax,1
    add [rect+RECT.top],eax
    add [rect+RECT.bottom],eax

    mov ecx,[rect+RECT.right]
    mov edx,[rect+RECT.bottom]
    sub ecx,[rect+RECT.left]
    sub edx,[rect+RECT.top]

    ; save background and draw message
    api BitBlt, [hbdc], 0,0,ecx,edx, [hdc],[rect+RECT.left],[rect+RECT.top], SRCCOPY
    api DrawText, [hdc], esi,ebx, rect,DT_NOPREFIX|DT_NOCLIP|DT_CENTER
    ;api DrawEdge, [hdc], rect, BDR_RAISEDOUTER|BDR_RAISEDINNER,BF_RECT
  %endif

  %if 0
    xor eax,eax
    mov [rect+RECT.left],eax
    mov [rect+RECT.top],eax
    api GetSystemMetrics,SM_CXSCREEN
    mov [rect+RECT.right],eax
    api GetSystemMetrics,SM_CYSCREEN
    mov [rect+RECT.bottom],eax
    api DrawText, [hdc], esi,ebx, rect,DT_CALCRECT|DT_NOPREFIX|DT_CENTER|DT_NOCLIP|DT_VCENTER
    api DrawText, [hdc], esi,ebx, rect,DT_NOPREFIX|DT_CENTER|DT_NOCLIP|DT_VCENTER
  %endif

.RefreshTimer:
    api SetTimer,[hwnd],1,3000,NULL

    ret 8

; Hides previously displayed message
.Hide:
    mov [LastMsg],dword 0
    api KillTimer,[hwnd],1
    cmp dword [hbmp],0
    je near .NoMsgShown

    ;api KillTimer,[hwnd],1
    ;api PeekMessage, msg,0,WM_TIMER,WM_TIMER,PM_REMOVE

    mov ecx,[rect+RECT.right]
    sub ecx,[rect+RECT.left]
    mov edx,[rect+RECT.bottom]
    sub edx,[rect+RECT.top]
    api BitBlt, [hdc], [rect+RECT.left],[rect+RECT.top],ecx,edx, [hbdc],0,0, SRCCOPY

    api DeleteDC, [hbdc]
    api DeleteObject, [hbmp]
    mov dword [hbmp],0
.NoMsgShown:
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=error message ptr)
EndWithErrMsg:
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBox, [hwnd],esi,ErrMsg.Fatal,MB_OK ;|MB_SETFOREGROUND|MB_TOPMOST ;MB_ICONERROR|MB_TASKMODAL|
    api DestroyWindow, [hwnd]
    api ExitProcess, -1
