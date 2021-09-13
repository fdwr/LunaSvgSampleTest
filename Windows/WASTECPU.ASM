; Waste Time (c)PeekinSoft
; 2002-07-17 / 2002-07-17
; Dwayne Robinson (FDwR@hotmail.com)
;
; Purpose:
;   Specifically written to do nothing but waste precious CPU cycles. Why!?
;   To have fun watching things in slow motion. Alternatively, I could
;   downgrade to a 25Mhz 386 if I TRULY wanted to see slow motion, but I'm
;   not curious enough to warrant that.

[section code code]
[section data data]
[section text data]
[section bss bss]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Include Windows definitions/constants/macros

;%define debug
%define UseWindowMsgs
%define UseWindowStyles
%define UseWindowControls
%define UseWindowSysVars
%include "mywininc.asm"         ;standard Windows constants, structs...

NORMAL_PRIORITY_CLASS equ 32
IDLE_PRIORITY_CLASS equ 64
HIGH_PRIORITY_CLASS equ 128
REALTIME_PRIORITY_CLASS equ 256

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
at WNDCLASS.lpszMenuName,       dd NULL
at WNDCLASS.lpszClassName,      dd ClassNames.Program
iend

;             control name, id,     class name          text                flags                           x  y        w h
DefWndControl cmdPause,         200, ClassNames.Button,  "&Pause",          BS_AUTOCHECKBOX|BS_PUSHLIKE,    4+56*0,4, 52,24
DefWndControl cmdClose,    IDCANCEL, ClassNames.Button,  "&Close",          0,                              4+56*1,4, 52,24
DefWndControl cmdAbout,         202, ClassNames.Button,  "&About",          0,                              4+56*2,4, 52,24
DefWndControl cmdOnTop,         203, ClassNames.Button,  "On &Top",         BS_AUTOCHECKBOX|BS_PUSHLIKE,    4+56*3,4, 52,24

rect:
point:
dd 0,           0               ;left,top
dd 0,           0               ;right,bottom

section bss
alignb 4
msg:    resb MSG_size
edge:   resb RECT_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
align 4,db 0
Flags:  dd 0
.Paused equ 1
.OnTop  equ 2

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:   db "CPU Time Waster 1.1" ;,0
NullString:     db 0
ClassNames:
.Program:       db "WasteCpuTime",0
.Button:        db "BUTTON",0

ErrMsg:
.NoWindow:      db "Failed to create window.",0

Text:
.About:         db "Specifically written to do nothing but waste precious CPU cycles. Why!? "
                db "To have fun watching things in slow motion. Alternatively, I could "
                db "downgrade to a 25Mhz 386 if I TRULY wanted to see slow motion, but I'm "
                db "not curious enough to warrant that."
                db 10,10
                db "Dwayne Robinson",10
                db "FDwR@hotmail.com",10
                db "PeekinSoft 2002-05-11"
                db 0
;.Ending:       db "Terminating Time Waster prcoess",0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code

global Main
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
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_MINIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME, 0,0, 56*4+8,24+18+14, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    ;mov [hwnd],eax

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Set process priority high

    debugwrite "setting process priority"

    api GetCurrentProcess
    api SetProcessPriority, eax,HIGH_PRIORITY_CLASS ;(high priority)
    ;api GetLastError
    ;api GetPriorityClass, eax
    debugwrite "priority result = %d",eax

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Loop

.Next:
    xor eax,eax
    api PeekMessage, msg, eax,eax,eax,PM_REMOVE
    test eax,eax
    jnz .CheckMsg

    test dword [Flags],Flags.Paused
    jz .Waste
    xor eax,eax
    api GetMessage, msg, eax,eax,eax

.CheckMsg:
    mov eax,[msg+MSG.message]
    debugwinmsg "thread msg=%X %s",eax,edx
    cmp eax,WM_QUIT
    je .Quit
    cmp eax,WM_CLOSE
    je .Quit
    api IsDialogMessage, [hwnd],msg
    ;api DispatchMessage, msg

    test dword [Flags],Flags.Paused
    jnz .Next

.Waste: ; begin waste time here
    mov ebx,1048576
.Delay:
    inc eax
    ;api GdiFlush
    dec ebx
    jns .Delay
    jmp .Next

.Quit:
    debugwrite "exiting process"
    ;api MessageBox, 0, Text.Ending,ProgramTitle,MB_OK|MB_ICONERROR|MB_TASKMODAL|MB_SETFOREGROUND|MB_TOPMOST
    api DestroyWindow, [hwnd]
    api ExitProcess, 0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]

    cmp eax,WM_COMMAND
    jne .NotCommand
    cmp word [esp+.wParam+2],BN_CLICKED
    je near .ButtonPushed
.NotCommand:
    cmp eax,WM_ACTIVATE
    je near .Activate
    cmp eax,WM_CREATE
    je near .Create
    cmp eax,WM_SYSCOMMAND
    je near .Minimize
    cmp eax,WM_WINDOWPOSCHANGING
    je near .WindowMoved
    cmp eax,WM_WINDOWPOSCHANGED
    je .RetFalse
    cmp eax,WM_DESTROY
    je .Destroy

.DefProc:
    jmp [DefWindowProc]

.RetTrue:
    mov eax,TRUE
    ret 16

.Destroy:
    ;debugpause "destroying window"
    mov dword [hwnd],0
.PostQuit:
    api PostQuitMessage,0
.RetFalse:
    xor eax,eax
    ret 16

.EscPressed:
    api PostQuitMessage,0
    ret

.ButtonPushed:
    mov eax,[esp+.wParam]
    cmp eax,IDCANCEL
    je .PostQuit

    push dword .RetFalse
    cmp eax,cmdAbout.Id
    je .cmdAbout
    cmp eax,cmdPause.Id
    je .cmdPause
    cmp eax,cmdOnTop.Id
    je .cmdOnTop
    ret

.cmdAbout:
    api MessageBox, [hwnd],Text.About,ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret
.cmdPause:
    ;api SendMessage, [cmdPause],BM_GETCHECK,TRUE,0
    xor dword [Flags],Flags.Paused
    ret
.cmdOnTop:
    xor dword [Flags],Flags.OnTop
    mov eax,HWND_TOPMOST
    test dword [Flags],Flags.OnTop
    jnz .IsOnTop
    mov eax,HWND_NOTOPMOST
.IsOnTop:
    api SetWindowPos, [hwnd],eax, edx,edx, edx,edx, SWP_NOACTIVATE|SWP_NOMOVE|SWP_NOSIZE
    ret

.Create:
    mov eax,[esp+.hwnd]
    mov [hwnd],eax
    mov [focus],eax
    ;api GetDC, eax              ;get window class display handle
    ;debugwrite "get hdc=%X",eax
    ;mov [hdc],eax
    api GetStockObject, DEFAULT_GUI_FONT
    mov [hfont],eax

    ;api InitCommonControls

    ; create buttons
    push dword cmdPause
    call CreateChildWindow
    push dword cmdAbout
    call CreateChildWindow
    push dword cmdClose
    call CreateChildWindow
    push dword cmdOnTop
    call CreateChildWindow

    xor eax,eax
    ret 16

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

.WindowMoved:
    xor eax,eax
    api SystemParametersInfo, SPI_GETWORKAREA, eax,edge, eax
    api GetWindowRect, [hwnd],rect
    mov edx,[rect+RECT.bottom]
    mov ecx,[rect+RECT.right]
    sub edx,[rect+RECT.top]         ;get height
    sub ecx,[rect+RECT.left]        ;get width
    sub [edge+RECT.bottom],edx ;set bottom edge
    sub [edge+RECT.right],ecx  ;set right edge

    push ebx
    mov ebx,[esp+.lParam+4]
    mov eax,[ebx+WINDOWPOS.y]
    mov edx,[edge+RECT.top]
    call .AlignEdge
    mov edx,[edge+RECT.bottom]
    call .AlignEdge
    mov [ebx+WINDOWPOS.y],eax

    mov eax,[ebx+WINDOWPOS.x]
    mov edx,[edge+RECT.left]
    call .AlignEdge
    mov edx,[edge+RECT.right]
    call .AlignEdge
    mov [ebx+WINDOWPOS.x],eax

    ;xor edx,edx
    ;api SetWindowPos, [hwnd],edx, eax,edi, edx,edx, SWP_NOACTIVATE|SWP_NOSIZE|SWP_NOZORDER|SWP_NOSENDCHANGING

    pop ebx
    xor eax,eax
    ret 16

; Aligns a window to the nearest edge if close enough, to make the window seem
; to 'stick' to the edges.
; (eax=row/column, edx=nearest row/column)
; (eax=aligned row/column; !ecx)
.AlignEdge:
    mov ecx,eax
    sub ecx,edx
    cmp ecx,-16
    jle .NoAlign
    cmp ecx,16
    jge .NoAlign
    mov eax,edx
.NoAlign:
    ret


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
    push dword WS_EX_NOPARENTNOTIFY|WS_EX_CONTEXTHELP
    
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


