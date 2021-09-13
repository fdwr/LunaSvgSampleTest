[section code code]
[section data data]
[section text data]
global Main


; Include Windows definitions/constants/macros
%define UseWindowStyles
%define UseWindowMsgs
%include "mywininc.asm"         ;standard Windows constants, structs...

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section data
align 4, db 0
hwnd:   dd 0                    ;window handle

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

;section bss
msg:    resb MSG_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:       db "Media File Lister 1.0 (Beta)" ;,0
NullString:         db 0
ClassNames.Program: db "MediaFileLister",0
ErrMsg.NoWindow:    db "Failed to create window.",0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code
Main:

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Create window

    api LoadCursor, 0,IDC_ARROW
    mov [wc+WNDCLASS.hCursor],eax
    api LoadIcon, wc.BaseAddress,1
    mov [wc+WNDCLASS.hIcon],eax
    api RegisterClass, wc       ; register window class
    test eax,eax
    jz near .EndWithMsg

    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_MINIMIZEBOX|WS_MAXIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME|WS_SIZEBOX, 0,0, 400,572, NULL, NULL, wc.BaseAddress, NULL
    test eax,eax
    mov [hwnd],eax
    jnz .LoopTop

.EndWithMsg:
    api MessageBox, [hwnd],ErrMsg.NoWindow,ProgramTitle,MB_OK|MB_TOPMOST|MB_ICONERROR|MB_TASKMODAL ;|MB_SETFOREGROUND
    api ExitProcess, -1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Main Loop
.LoopTop:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    jz near .End
    mov eax,[msg+MSG.message]
    api DispatchMessage, msg
    jmp short .LoopTop

.End:
    api DestroyWindow, [hwnd]
    api ExitProcess, [msg+MSG.wParam]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    cmp eax,WM_DESTROY
    je .Destroy

.DefProc:
    jmp [DefWindowProc]

.Destroy:
    ;mov dword [hwnd],0
    api PostQuitMessage,0
.RetFalse:
    xor eax,eax
    ret 16
