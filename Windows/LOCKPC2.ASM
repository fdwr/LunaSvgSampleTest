; PC Lock (Fire Mode)
; Dwayne Robinson
; 2002-04-16 / 2002-05-03
;
; Brief Features:
;   Mildly discourages people from using your computer
;   Disables all common Windows keypresses (to prevent switch away)
;   Prevents shut down (in case user tries to turn ATX PC off)
;   Stops screensaver from coming on and monitor low power mode
;
; Prevents annoying people from sitting down at your PC and closing all your
; open programs while you are temporarily away. Was created because as an
; assistant in the computer lab, I'll typically be working on some program
; and have a few windows open. Then, I leave for moment to help someone with
; a question, and someone sits down at my computer (well, it's technically
; the school's) closing them all. There are other unused PCs they could have
; chosen, but no, they chose to annoy me >:-/
;
; This program is not intended as a high security gate (since a single
; keypress is all it takes to terminate it), just a discouragement.
;
; All the common key combinations are intentionally disabled so semi-smarter
; people can't simply switch away from the program. This includes: Alt+Tab,
; Ctrl+Esc, Windows Key, and Alt+Esc. Ctrl+Alt+Del will always work on
; Win2k+ systems regardless. The first method of disabling common key presses
; is by simply never passing them to DefWindowProc (which works on Win9x).
; Win2k uses a different order of operations, so you must intercept the
; message by using a keyboard hook.
;
; System Requirements:
;   Windows 95+         works on 95/98/2k, others are unverified)
;
; Compiling:
;   GoRC 0.56 - compile RC into resource file
;   NASM 0.98 - compile source code into object file
;   ALINK 1.6 - link object file with external references
;
;   nasm -fwin32 lockpc2.asm -o LOCKPC2.COF -dWinVer -d_DMCLINK
;   gorc /r lockpc2.rc
;   alink -oPE LOCKPC2.COF WINIMP.LIB LOCKPC2.RES -o LOCKPC2.EXE -entry Main
;

[section code code]
[section data data]
[section text data]
[section bss bss]
global Main

%define debug
%define UseWindowStyles
%define UseWindowMsgs
%define UseWindowGfx
%define UseResources
%define UseKeyboard
%define UseWindowHooks
%define UseWindowSysVars
;%include "mywininc.asm"         ;standard Windows constants, structs...
%include "wininc.asm"         ;standard Windows constants, structs...
;%include "winnasm.inc"         ;standard Windows constants, structs...


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
align 4, db 0
hwnd:   dd 0            ;window handle
hdc:    dd 0            ;class device context
dxd:    dd 0            ;DirectDraw object
ddps:   dd 0            ;DirectDraw primary surface
ddcp:   dd 0            ;primary surface color palette
hkbd:   dd 0            ;keyboard hook
Active: dd 0            ;program is active or not

wc:
.BaseAddress    equ 400000h ;base address of program (Windows module handle)
istruc WNDCLASS
at WNDCLASS.style,         dd CS_CLASSDC
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
.lfHeight               dd 45
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


;SineTable:
;.Degrees    equ 1024
;incbin "sinewave.dat"

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section bss
msg:        resb MSG_size
ps:         resb PAINTSTRUCT_size

Screen:
alignb 4
;.Width      resd 1
;.Height     resd 1
;.Palette:  resb 1024
section data
.Width      dd 1024
.Height     dd 768
section bss

Particles:
.MaxCount   equ 200
.Brightness equ 18
.MaxDistance equ 800
.Distance:  resd .MaxCount      ;distance of particle from center
.AngleY:    resd .MaxCount      ;y rotation (clockwise/countercw)
.AngleZ:    resd .MaxCount      ;z rotation (forward/backward)
section data
.BaseY:     dd 300
.BaseX:     dd 400
section bss

Passwords:
.Minimize:  resb 10
.Quit:      resb 10
.Current:   resb 10
.Size       equ $-Passwords

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:
ProgramClass:   db "PeekinPcLock2",0
ErrMsg:
.Fatal:         db "PC Lock: Fatal Error",0
.NoWindow:      db "Failed to create window"
LockMessage:    db "Not your computer"
LockMessage_size equ $-LockMessage


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

Main:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Create window
    ;api LoadCursor, 0,IDC_HANDWRITING;IDC_ARROW
    ;mov [wc+WNDCLASS.hCursor],eax
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
    ;api CreateWindowEx, 0, ProgramClass, ProgramTitle, WS_POPUP|WS_MAXIMIZE|WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU, 0,0, 3000,3000, NULL, NULL, wc.BaseAddress, NULL
    api CreateWindowEx, WS_EX_TOPMOST|WS_EX_TOOLWINDOW, ProgramClass, ProgramTitle, WS_POPUP|WS_MAXIMIZE|WS_VISIBLE, 0,0, 3000,3000, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    ;mov [hwnd],eax

    ; get window class display handle
    api GetDC, eax
    debugwrite "get hdc=%X",eax
    mov [hdc],eax

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Misc Init
    ;call InitParticles

    cld
    xor eax,eax
    mov edi,Passwords
    mov ecx,Passwords.Size/4
    rep stosd

    ;api ShowCursor, FALSE

    ;api SetTimer,[hwnd],1,33,NULL   ;30 times per second, no callback

    ; set text properties
    api SetTextColor, [hdc],00AFFF80h
    api SetBkMode, [hdc],BKMODE_TRANSPARENT
    api CreateFontIndirect, logfont
    api SelectObject, [hdc],eax
    ;TA_CENTER equ 6
    api SetTextAlign, [hdc],TA_CENTER

    ; bring back upon pressing Ctrl+Shift+Z
    api RegisterHotKey, 0,0,MOD_CONTROL|MOD_SHIFT,VK_Z

    ; Disallow application from being switched away from:
    ;   For 9x systems, pretend we are a screen saver.
    ;   For NT/2k systems, intercept low level keyboard hooks
    ; Doing both doesn't hurt anything.
    xor eax,eax
    api SystemParametersInfo, SPI_SETSCREENSAVEACTIVE,TRUE,eax,eax
    ;api SetWindowsHookEx, WH_KEYBOARD_LL,LlKeyboardProc,wc.BaseAddress,NULL
    ;mov [hkbd],eax

    ;api GetDesktopWindow
    ;api EnableWindow, eax, FALSE

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Loop
    debugwrite "entering main loop"
    jmp short .Inside
.Next:
    mov eax,[msg+MSG.message]
    debugwinmsg "process msg=%X %s W=%X L=%X", eax,esi,[msg+MSG.wParam],[msg+MSG.lParam]
    cmp eax,WM_KEYFIRST
    jb .NotKey
    cmp eax,WM_KEYLAST
    jbe near .KeyPress
.NotKey:
    cmp eax,WM_MOUSEMOVE
    je .MouseMove
    cmp eax,WM_TIMER
    je near .FrameUpdate
    cmp eax,WM_HOTKEY
    je .HotKey
.Dispatch:
    api DispatchMessage, msg
.Inside:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    jnz .Next

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Termination
.End:
    ;api GetDesktopWindow
    ;api EnableWindow, eax, TRUE

    ;api UnhookWindowsHookEx, [hkbd]
    xor eax,eax
    api SystemParametersInfo, SPI_SETSCREENSAVEACTIVE,eax,eax,eax
    xor eax,eax
    api UnregisterHotKey, eax,eax ;0,0
    api DestroyWindow, [hwnd]
    api ExitProcess,[msg+MSG.wParam]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.MouseMove:
    movsx edx,word [msg+MSG.lParam+2]   ;sign row
    movsx ecx,word [msg+MSG.lParam]     ;sign column
    mov [Particles.BaseY],edx
    mov [Particles.BaseX],ecx
    jmp short .Inside

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.HotKey:
;    api IsWindowVisible, [hwnd]
;    dec eax
;    js .ShowWin
;    api ShowWindow, [hwnd],SW_HIDE
;    jmp .Inside
.ShowWin:
    api ShowWindow, [hwnd],SW_MAXIMIZE
    jmp .Inside

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.KeyPress:
    mov al,[msg+MSG.wParam]
    cmp al,VK_F12
    je near .End
    cmp al,VK_F11
    jne near .Inside
    api ShowWindow, [hwnd],SW_HIDE
    ;api GetDesktopWindow
    ;api SetForegroundWindow, eax
    ;api GetWindow, [hwnd],GW_HWNDNEXT
    ;api FindWindowEx, NULL,NULL, ShellTrayWnd,NULL
    ;api SetForegroundWindow, eax
    jmp .Inside

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.FrameUpdate:

    ;api SetWindowPos, [hwnd],HWND_TOPMOST, 0,0,0,0, SWP_NOCOPYBITS|SWP_NOMOVE|SWP_NOSIZE
    ;api InvalidateRect, [hwnd],NULL,FALSE

    jmp .Inside


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    debugwinmsg "win msg=%X %X W=%X L=%X", eax,esi,[esp+.wParam+4],[esp+.lParam]
    cmp eax,WM_CREATE
    je near .Created
    cmp eax,WM_CLOSE
    je near .Ignore;.Close
    cmp eax,WM_SYSCOMMAND
    je near .DisableScreensaver
    cmp eax,WM_QUERYENDSESSION
    je near .QueryEndSession
    cmp eax,WM_PAINT
    je near .Paint
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
    ;debugwrite "enable timer"
    api SetTimer,[hwnd],1,33,NULL   ;30 times per second, no callback
    mov dword [Active],TRUE
    ;getsystemmetrics SM_CXSCREEN
    ;getsystemmetrics SM_CXSCREEN
    xor eax,eax
    ret 16
.LoseFocus:
    ;debugwrite "disable timer"
    api KillTimer,[hwnd],1      ;destroy 30 tick per second timer
    api PeekMessage, msg,0,WM_TIMER,WM_TIMER,PM_REMOVE

    ;api SetWindowPos, [hwnd],HWND_TOPMOST, 0,0,0,0, SWP_NOCOPYBITS|SWP_NOMOVE|SWP_NOSIZE
    xor eax,eax
    mov dword [Active],eax ;FALSE
    ret 16

%if 0
    api RegisterHotKey, 0,0,MOD_ALT,VK_TAB
    api RegisterHotKey, 0,1,MOD_ALT|MOD_SHIFT,VK_TAB
    api RegisterHotKey, 0,2,MOD_CONTROL,VK_ESCAPE
    api UnregisterHotKey, 0,0
    api UnregisterHotKey, 0,1
    api UnregisterHotKey, 0,2
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Paint:
    ;debugwrite "paint background"
    push ebx,esi,edi
    api BeginPaint, [hwnd],ps

%if 0
    mov edi,[Screen.Height]
    xor esi,esi
    api CreatePen, PS_NULL,0,0
    api SelectObject, [hdc],eax
    api DeleteObject, eax
    xor ebx,ebx
    dec edi
.Next1:
    add esi,121014h
    mov eax,esi
    and eax,0C0C0C0h
    and esi,3F3F3Fh
    shr eax,6
    add ebx,eax

   %if 0
    api CreatePen, PS_SOLID,1,ebx
    api SelectObject, [hdc],eax
    api DeleteObject, eax
    api MoveToEx, [hdc], 0,edi, NULL
    api LineTo, [hdc],3000,edi
   %elif 0
    api CreateSolidBrush, ebx
    api SelectObject, [hdc],eax
    api DeleteObject, eax
    lea eax,[edi-2]
    api Rectangle, [hdc], 0,edi, 3000,eax
   %endif

    dec edi
    jge .Next1
%elif 1

    ; set left & right sides for fill
    mov ecx,[ps+PAINTSTRUCT.left]
    mov edx,[ps+PAINTSTRUCT.right]
    mov [rect+RECT.left],ecx
    mov [rect+RECT.right],edx

    xor esi,esi
    mov edi,[Screen.Height]
    xor ebx,ebx
.Next1:
    ; next shade of color
    add esi,151012h
    mov eax,esi
    and eax,0C0C0C0h
    and esi,3F3F3Fh
    shr eax,6
    add ebx,eax

    cmp [ps+PAINTSTRUCT.bottom],edi
    jb .SkipLine

    lea ecx,[edi-1]
    mov [rect+RECT.bottom],edi
    mov [rect+RECT.top],ecx
    api CreateSolidBrush, ebx
    push eax
    api FillRect, [hdc],rect,eax
    api DeleteObject;,eax

.SkipLine:
    dec edi
    cmp [ps+PAINTSTRUCT.top],edi
    jb .Next1

%endif

    api TextOut, [hdc],400,250,LockMessage,LockMessage_size

    api EndPaint, [hwnd],ps
    pop ebx,esi,edi
    xor eax,eax
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
    cmp eax,SC_SCREENSAVE
    je .Ignore
    cmp eax,SC_MONITORPOWER
    je .Ignore
    jmp [DefWindowProc]

    unlocals

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LlKeyboardProc:
    params .nCode, .message, .kbInfo

    ;api MessageBox, [hwnd],ErrMsg.Fatal,ErrMsg.Fatal,MB_OK|MB_SETFOREGROUND|MB_TOPMOST ;MB_ICONERROR|MB_TASKMODAL|
    ;cmp dword [Active],TRUE     ;return immediately if inactive (different program has focus)
    ;jne .Chain
    ;cmp dword [esp+.nCode],0    ;return immediately if code is negative
    ;js .Chain
    mov eax,TRUE                ;return nonzero result to end chain
    ret 12

    mov ecx,[esp+.kbInfo]
    mov al,[ecx+KBDLLHOOKSTRUCT.vkCode]
    cmp al,VK_TAB
    je .NoChain
    cmp al,VK_ESCAPE
    je .NoChain
    cmp al,VK_LWIN
    je .NoChain
    cmp al,VK_RWIN
    je .NoChain
.Chain:
    api CallNextHookEx, [hkbd], [esp+8+.nCode],[esp+4+.message],[esp+.kbInfo]
    ret 12
.NoChain:
    mov eax,TRUE                ;return nonzero result to end chain
    ret 12

;KBDLLHOOKSTRUCT

%if 0
    params .nCode, .vkCode, .kbInfo
    mov eax,TRUE                ;return nonzero result to end chain
    ret 12

    cmp dword [Active],TRUE     ;return immediately if inactive (different program has focus)
    jne .Chain
    cmp dword [esp+.nCode],0    ;return immediately if code is negative
    js .Chain
    cmp byte [esp+.vkCode],VK_TAB
    je .NoChain
    cmp byte [esp+.vkCode],VK_ESCAPE
    je .NoChain

.Chain:
    api CallNextHookEx, [hkbd], [esp+8+.nCode],[esp+4+.vkCode],[esp+.kbInfo]
    ret 12
.NoChain:
    mov eax,TRUE                ;return nonzero result to end chain
    ret 12
%endif

    unlocals


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%if 0
InitParticles:
    mov edi,(Particles.MaxCount-1)*4
;%define UseSimpleRnd
%ifdef UseSimpleRnd
    mov eax,0BFFCh
%else
    mov eax,082775212h          ; set initial seed values
    mov ebx,03914AC5Fh
    mov ecx,0B460D9C3h
%endif
.Next:
    call .GetRng
    and esi,SineTable.Degrees-1
    mov dword [Particles.AngleY+edi],esi
    call .GetRng
    and esi,SineTable.Degrees-1
    mov dword [Particles.AngleZ+edi],esi
    call .GetRng
    ;and esi,255
    ;or esi,128
    ;mov dword [Particles.Distance+edi],esi
    push eax
    xor edx,edx
    mov esi,Particles.MaxDistance
    div esi
    mov dword [Particles.Distance+edi],200
    pop eax
    sub edi,byte 4
    jge .Next
    ret

; (eax=previous random value)
; (eax=new random value, edx=eax)
.GetRng:
%ifdef UseSimpleRnd
    mov ecx,33797
    mul ecx
    inc eax
%else
    mov edx,ecx                 ; R4=R3
    mov ecx,ebx                 ; R3=R2
    mov ebx,eax                 ; R2=R1

    mov eax,edx                 ; R1 = R4 + (R3<=R2 ? R3 : R2)
    cmp ecx,ebx
    jbe .Less
    add eax,ebx                 ; +R2
    jmp short .EndRng
.Less:
    add eax,ecx                 ; +R3
.EndRng:
%endif
    mov esi,eax                 ;make copy
    ret
%endif


%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
DrawParticles:
    mov ebx,(Particles.MaxCount-1)*4
.Next:
    ; xy distance = z * distance
    mov eax,[Particles.AngleZ+ebx]
    mov eax,[SineTable+eax*4]
    imul eax,[Particles.Distance+ebx]
    ;imul eax,150
    sar eax,16
    ;mov eax,50

    ; x & y
    mov edx,[Particles.AngleY+ebx]
    mov ecx,edx
    mov edx,[SineTable+edx*4]
    add ecx,256                 ;get cosine
    imul edx,eax
    and ecx,1024-1
    sar edx,16
    mov ecx,[SineTable+ecx*4]
    imul ecx,eax
    sar ecx,16
    add edx,[Particles.BaseY]
    add ecx,[Particles.BaseX]

; (edx=row, ecx=col)
.At:
    cmp edx,Screen.Height
    jae .OffScreen
    cmp ecx,Screen.Width
    jae .OffScreen
%if Screen.Width=320
    mov eax,edx
    shl edx,6
    shl eax,8
    add edx,eax
%elif Screen.Width=640
    mov eax,edx
    shl edx,7
    shl eax,9
    add edx,eax
%else
    imul edx,Screen.Width
%endif
    add [Screen.Buffer+edx+ecx],byte Particles.Brightness
    jnc .NoOverFlow
    mov [Screen.Buffer+edx+ecx],byte 255
.NoOverFlow:
.OffScreen:

    ; move particle for next frame
    add dword [Particles.AngleY+ebx],byte 2
    and dword [Particles.AngleY+ebx],SineTable.Degrees-1
    add dword [Particles.AngleZ+ebx],byte 3
    and dword [Particles.AngleZ+ebx],SineTable.Degrees-1

    sub ebx,byte 4
    jns near .Next
    ret
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; (esi=error message ptr)
EndWithErrMsg:
    debugwrite "exiting process from fatal error: %s", esi
    api MessageBox, [hwnd],esi,ErrMsg.Fatal,MB_OK ;|MB_SETFOREGROUND|MB_TOPMOST ;MB_ICONERROR|MB_TASKMODAL|
    api DestroyWindow, [hwnd]
    api ExitProcess, -1


%if 0
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
;section bss
;.Buffer:    resb .DefMaxLen
.Buffer:        db "          ",0
section code
%endif
