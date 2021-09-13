; Set Desktop Style (c)PeekinSoft
; Dwayne Robinson (FDwR@hotmail.com)
; 2002-06-27 Born
; 2002-06-27 Updated
;
; Purpose:
;   Sets the style of the desktop's system list view. Normally the desktop
;   is permanently set to large icons, but this allows other styles like
;   small icons, list, or details.

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
;%define UseResources
%include "mywininc.asm"         ;standard Windows constants, structs...


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:   db "Set Desktop Style 1.1 (Beta)" ;,0
NullString:     db 0

ClassNames:
.Program:       db "PknSetDeskStyle",0
.Button:        db "BUTTON",0
.Label:         db "STATIC",0
.List:          db "LISTBOX",0
;.Tooltip:      db "TOOPTIPS_CLASS",0
;.Edit:         db "EDIT",0
;.Progress:     db "msctls_progress32",0

ErrMsg:
.NoWindow:      db "Failed to create window.",0

Text:
.About:         db "Sets the style of the desktop's system list view. "
                db "Normally the desktop is permanently set to large icons, "
                db "but this allows other styles like small icons, list, or "
                db "details."
                db 10,10
                db "Dwayne Robinson",10
                db "FDwR@hotmail.com",10
                db "PeekinSoft 2002-06-26"
                db 0
.ListStyles:    db "Icon view",0
                db "Small icons",0
                db "List view",0
                db "Report view",0
                db "Single selection",0
                db "Always show selection",0
                db "Sort ascending",0
                db "Sort descending",0
                db "No label wrap",0
                db "Auto arrange",0
                db "Align top",0
                db "Align left",0
                db 0


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Window related vars
section data

section data
align 4, db 0
hwnd:   dd 0                    ;window handle
;hdc:   dd 0                    ;class device context
fhwnd:  dd 0                    ;hwnd of control with focus
hfont:  dd 0                    ;default font to use for controls

wc:
.BaseAddress                    equ 400000h ;base address of program (Windows module handle)
istruc WNDCLASS
at WNDCLASS.style,              dd 0;CS_CLASSDC
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

DefWndControl lblDeskHwnd,      100, ClassNames.Label,  NullString,         WS_CHILD|WS_VISIBLE,                8,8, 152,16
DefWndControl lstDeskStyle,     200, ClassNames.List,   NullString,         WS_CHILD|WS_VISIBLE|WS_VSCROLL|WS_TABSTOP|WS_GROUP|LBS_NOINTEGRALHEIGHT|LBS_NOTIFY|LBS_MULTIPLESEL,8,8+16+8, 152,13*12+4
DefWndControl cmdGetHwnd,       300, ClassNames.Button, "&Get",             WS_CHILD|WS_VISIBLE|WS_TABSTOP|WS_GROUP, 8+52*0,8*25, 48,24
DefWndControl cmdSetStyle,     IDOK, ClassNames.Button, "&Set",             WS_CHILD|WS_VISIBLE|WS_TABSTOP|BS_DEFPUSHBUTTON, 8+52*1,8*25, 48,24
DefWndControl cmdAbout,      IDHELP, ClassNames.Button, "&About",           WS_CHILD|WS_VISIBLE|WS_TABSTOP,     8+52*2,8*25, 48,24


section bss
msg:    resb MSG_size
;ps:     resb PAINTSTRUCT_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Global program vars

section data
align 4, db 0
DeskHwnd:       dd 0            ;window handle of desktop listview
DeskPid:        dd 0
DeskTid:        dd 0
DeskStyle:      dd LVS_SMALLICON
MouseCaptured:  dd 0


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
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT, ClassNames.Program, ProgramTitle, WS_VISIBLE|WS_SYSMENU|WS_CAPTION, CW_USEDEFAULT,CW_USEDEFAULT, 8*22-2,8*32, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    ;mov [hwnd],eax

    mov edi,Text.ListStyles
.NextStyle:
    api SendMessage, [lstDeskStyle],LB_ADDSTRING,0,edi
    mov eax,1024            ;maximum length of characters, bottom byte null
    mov ecx,eax             ;make a copy of max length for later
    ;cld                    ;as always, look forward
    repne scasb             ;search for the end, until character is found
    cmp byte [edi],0
    jne .NextStyle


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
  %ifdef debug
    cmp eax,WM_MOUSEMOVE
    je near .MouseMove
  %endif
    cmp eax,WM_LBUTTONDOWN
    je near .CaptureClick
    cmp eax,WM_ACTIVATE
    je near .Activate
    cmp eax,WM_CAPTURECHANGED
    je near .CaptureChanged
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
    ;api GetDC, eax              ;get window class display handle
    ;debugwrite "get hdc=%X",eax
    ;mov [hdc],eax
    api GetStockObject, DEFAULT_GUI_FONT
    mov [hfont],eax

    ; create label and list
    push dword lblDeskHwnd
    call CreateChildWindow
    push dword lstDeskStyle
    call CreateChildWindow

    ; create buttons
    push dword cmdGetHwnd
    call CreateChildWindow
    push dword cmdSetStyle
    call CreateChildWindow
    push dword cmdAbout
    call CreateChildWindow

    mov eax,[lstDeskStyle]
    mov [fhwnd],eax

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
    cmp eax,cmdSetStyle.Id
    je .cmdSetStyle
    cmp eax,cmdAbout.Id
    je .cmdAbout
    cmp eax,cmdGetHwnd.Id
    je near .cmdGetHwnd
    ret

.EscPress:
    api PostQuitMessage,0
    ret

.cmdHelp:
    push dword .RetTrue
.cmdAbout:
    api MessageBox, [hwnd],Text.About,ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret

.cmdSetStyle:
    ;api GetWindowLong, [DeskHwnd],GWL_STYLE
    ;debugpause "get style = %x",eax
    ;and eax,~(LVS_TYPEMASK|LVS_SINGLESEL|LVS_SHOWSELALWAYS|LVS_ALIGNLEFT|LVS_AUTOARRANGE|LVS_NOLABELWRAP|LVS_SORTDESCENDING|LVS_SORTASCENDING)
    ;or eax,[DeskStyle]
    ;debugpause "new style = %x",eax
    ;api SetWindowLong, [DeskHwnd],GWL_STYLE,eax
    ;debugpause "set style = %x",eax

    ;api SendMessage, [DeskHwnd],LVM_SETBKCOLOR,0,806090h
    ;api InvalidateRect, [DeskHwnd],NULL,TRUE

    ;api SendMessage, [DeskHwnd],LVM_DELETEALLITEMS,0,0

    api SendMessage, [DeskHwnd],LVM_SETEXTENDEDLISTVIEWSTYLE,0,LVS_EX_GRIDLINES|LVS_EX_FLATSB|LVS_EX_FULLROWSELECT|LVS_EX_CHECKBOXES|LVS_EX_TWOCLICKACTIVATE|LVS_EX_ONECLICKACTIVATE

    ;api GetWindowThreadProcessId, [DeskHwnd],DeskPid
    ;api CreateRemoteThread, [DeskPid],NULL,32768,SomeWhere,DeskHwnd,0,[DeskTid]
    ;api CloseHandle, [DeskTid]
    ret

.cmdGetHwnd:
    api SetCapture, [hwnd]
    mov dword [MouseCaptured],TRUE
    ret

.CaptureClick:
    cmp dword [MouseCaptured],TRUE
    jne .IgnoreMove
    api ReleaseCapture
    api WindowFromPoint, [msg+MSG.pt],[msg+MSG.pt+4]
    push esi,edi
    mov [DeskHwnd],eax
    call NumToString
    api SetWindowText, [lblDeskHwnd],NumToString.Buffer
    pop esi,edi
    ;api GetWindowText,[DeskHwnd],TempData,TempData_size
.IgnoreMove:
    xor eax,eax
    ret 16

.CaptureChanged:
    mov dword [MouseCaptured],FALSE
    xor eax,eax
    ret 16

%ifdef debug
.MouseMove:
    api WindowFromPoint, [msg+MSG.pt],[msg+MSG.pt+4]
    debugwrite "hwnd at point = %X",eax
    xor eax,eax
    ret 16
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; RetFalse on stack
.ListSelected:
    cmp dword [esp+.wParam],lstDeskStyle.Id|(LBN_SELCHANGE<<16)
.SelectedFile:
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
