[section code code]
[section text data]
[section bss bss]
global Main

; Include Windows definitions/constants/macros
%define UseWindowStyles
%define UseWindowControls
%define UseWindowMsgs
%include "mywininc.asm"         ;standard Windows constants, structs...

section text
wc:
.BaseAddress                    equ 400000h ;base address of program (Windows module handle)
hwnd:   dd 0

section bss
msg:    resb MSG_size

section text
Work: db "work",0

section code
Main:
    api GetCommandLine
    api CreateWindowEx, WS_EX_CLIENTEDGE, "EDIT", eax, WS_MINIMIZEBOX|WS_VISIBLE|WS_SYSMENU|WS_DLGFRAME| ES_AUTOHSCROLL, 0,0, 300,64, NULL, NULL, wc.BaseAddress, NULL
    mov [hwnd],eax
    api SendMessage, eax,EM_SETSEL,0,-1
    api SendMessage, [hwnd],WM_COPY,0,0

.Next:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    jz near .End
    mov eax,[msg+MSG.message]
    debugwinmsg "process msg=%X %s W=%X L=%X", eax,edx,[msg+MSG.wParam],[msg+MSG.lParam]
    ;api SendMessage, [msg+MSG.hwnd],[msg+MSG.message],[msg+MSG.wParam],[msg+MSG.lParam]
    ;api IsDialogMessage, [hwnd],msg
    api DispatchMessage, msg
    api IsWindowVisible, [hwnd]
    test eax,eax
    jnz .Next

.End:
    debugwrite "ending"
    api DestroyWindow, [hwnd]
    ret
