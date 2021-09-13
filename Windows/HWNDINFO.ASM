; Hwnd Info (c)PeekinSoft
; Dwayne Robinson (FDwR@hotmail.com)
; 2003-02-24 Born
; 2003-02-24 Updated
; 2003-06-27 Changed button to Pause
;            Added DispatchMessage since Explorer for XP freezes if not there
;
; Purpose:
;   Simply gets information from the hovered window.

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
%define UseGdiFonts
;%define UseResources
%include "mywininc.asm"         ;standard Windows constants, structs...


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text

ProgramTitle:   db "Hwnd Info 1.1" ;,0
NullString:     db 0

ClassNames:
.Program:       db "PknHwndInfo",0
.Button:        db "BUTTON",0
.Label:         db "STATIC",0
.List:          db "LISTBOX",0
;.Tooltip:      db "TOOPTIPS_CLASS",0
.Edit:          db "EDIT",0
;.Progress:     db "msctls_progress32",0

ErrMsg:
.NoWindow:      db "Failed to create window.",0

Text:
.About:         db "Displays info about the hovered window."
                db 10,10
                db "Dwayne Robinson",10
                db "FDwR@hotmail.com",10
                db "PeekinSoft 2003-02-24"
                db 0
.ListStyles:    db "Handle",0
                db "Position",0
                db "Characters",0
                db "Font",0
                db 0
StrTrue:        db "true",0
StrFalse:       db "false",0

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

DefWndControl lstWndAtrs,       200, ClassNames.List,    NullString,        WS_VSCROLL|WS_TABSTOP|WS_GROUP|LBS_NOINTEGRALHEIGHT|LBS_NOTIFY,WS_EX_STATICEDGE, 8,8, 152,15*13+4
DefWndControl txtWndText,       201, ClassNames.Edit,   NullString,         ES_AUTOHSCROLL|WS_TABSTOP,WS_EX_STATICEDGE,                8,8*27, 152,16
;DefWndControl txtWndText,      201, ClassNames.Label,   NullString,         WS_VISIBLE,WS_EX_STATICEDGE,                8,8*22, 152,16*4
DefWndControl cmdPause,         300, ClassNames.Button, "&Pause",   BS_CHECKBOX|BS_AUTOCHECKBOX|BS_PUSHLIKE|WS_TABSTOP|WS_GROUP,0, 8+52*0,8*30, 48*2,24
DefWndControl cmdAbout,      IDHELP, ClassNames.Button, "&About",           WS_TABSTOP,0,     8+52*2,8*30, 48,24

;DefWndControl txtJapTest,       123, ClassNames.Edit,   NullString,         ES_AUTOHSCROLL,WS_EX_STATICEDGE,                8,8*22, 152,16

%if 0
;LOGFONT
lf:
dd 12 ;height
dd 0 ;width
dd 0 ;escapement
dd 0 ;orientation
dd FW_DONTCARE ;weight
db FALSE ;italic
db FALSE ;underline
db FALSE ;strikeout
db SHIFTJIS_CHARSET ;MAC_CHARSET,RUSSIAN_CHARSET,
db OUT_TT_PRECIS
db CLIP_DEFAULT_PRECIS
db DEFAULT_QUALITY
db DEFAULT_PITCH|FF_DONTCARE
db "MS Gothic"
align 4,db 0
%endif

section bss
msg:    resb MSG_size
;ps:     resb PAINTSTRUCT_size

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Global program vars

section data
align 4, db 0
WndHwnd:        dd 0            ;window handle of desktop listview
WndPid:         dd 0
WndTid:         dd 0
WndStyle:       dd 0
WndExStyle:     dd 0
WndTextLen:     dd 0
MlGetText:      dd 0
MlSetText:      dd 0
SelfTid:        dd 0

section bss
WndText_size    equ 4096
WndText:        resb WndText_size
WndClass:       resb 256
TempString:     resb 1024


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
    api CreateWindowEx, WS_EX_ACCEPTFILES|WS_EX_CONTROLPARENT|WS_EX_TOPMOST, ClassNames.Program, ProgramTitle, WS_VISIBLE|WS_SYSMENU|WS_CAPTION|WS_MINIMIZEBOX, CW_USEDEFAULT,CW_USEDEFAULT, 8*22-2,8*37, NULL, NULL, wc.BaseAddress, NULL
    debugwrite "window handle=%X", eax
    test eax,eax
    jz near EndWithErrMsg
    ;mov [hwnd],eax

%if 0
    mov edi,Text.ListStyles
.NextStyle:
    api SendMessage, [lstWndAtrs],LB_ADDSTRING,0,edi
    mov eax,1024            ;maximum length of characters, bottom byte null
    mov ecx,eax             ;make a copy of max length for later
    ;cld                    ;as always, look forward
    repne scasb             ;search for the end, until character is found
    cmp byte [edi],0
    jne .NextStyle
%endif
    api SetTimer,[hwnd],1,500,NULL

    api GetCurrentThreadId
    mov [SelfTid],eax

    api RegisterWindowMessage, "ML_GETTEXT"
    mov [MlGetText],eax
    api RegisterWindowMessage, "ML_SETTEXT"
    mov [MlSetText],eax

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main Message Loop

    debugwrite "entering main loop"
    jmp short .Next

.Top:
    mov eax,[msg+MSG.message]
    debugwinmsg "process msg=%X %s W=%X L=%X", eax,edx,[msg+MSG.wParam],[msg+MSG.lParam]
    api IsDialogMessage, [hwnd],msg
    test eax,eax
    jnz .Next
    api DispatchMessage, msg
.Next:
    xor eax,eax
    api GetMessage, msg, eax,eax,eax
    test eax,eax
    ;js .MsgError (don't bother checking for errors)
    jg .Top

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Termination

.End:
    debugwrite "ending"
    api KillTimer,[hwnd],1
    api DestroyWindow, [hwnd]
    api ExitProcess, [msg+MSG.wParam]


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    ;debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]

    cmp eax,WM_COMMAND
    je near .Command
    ;cmp word [esp+.wParam+2],BN_CLICKED
    ;je near .ButtonPushed
    ;cmp word [esp+.wParam+2],LBN_SELCHANGE
    ;je near .ListSelected
  %ifdef debug
    cmp eax,WM_MOUSEMOVE
    je near .MouseMove
  %endif
    ;cmp eax,WM_LBUTTONDOWN
    ;je near .CaptureClick
    ;cmp eax,WM_CAPTURECHANGED
    ;je near .CaptureChanged
    cmp eax,WM_TIMER
    je near .ShowWindowInfo
    cmp eax,WM_ACTIVATE
    je near .Activate
    cmp eax,WM_HELP
    je near .cmdHelp
    cmp eax,WM_DESTROY
    je .Destroy
    cmp eax,WM_CREATE
    je .Create
.DefProc:
    extern DefWindowProc
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

    ;api CreateFontIndirect, lf
    api GetStockObject, DEFAULT_GUI_FONT
    mov [hfont],eax

    ; create info list
    push dword lstWndAtrs
    call CreateChildWindow
    push dword txtWndText
    call CreateChildWindow
    ;push dword txtJapTest
    ;call CreateChildWindow

    ; create buttons
    push dword cmdPause
    call CreateChildWindow
    ;push dword cmdSetStyle
    ;call CreateChildWindow
    push dword cmdAbout
    call CreateChildWindow

    mov eax,[lstWndAtrs]
    mov [fhwnd],eax

    xor eax,eax
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.Activate:
    cmp word [esp+.wParam],WA_INACTIVE
    je .LoseFocus
    debugwrite "new focus hwnd=%X",[fhwnd]
    api SetFocus, [fhwnd]
    ;api SetTimer,[hwnd],1,500,NULL
    xor eax,eax
    ret 16
.LoseFocus:
    api GetFocus
    test eax,eax
    jz .NullFocus
    mov [fhwnd],eax
    debugwrite "old focus hwnd=%X",eax

    ;destroy timer if necessary
    ;api SendMessage, [cmdPause],BM_GETSTATE, 0,0
    ;test eax,eax
    ;jz .Paused
    ;api KillTimer,[hwnd],1
;.Paused:

    xor eax,eax
.NullFocus:
    ret 16

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; RetFalse on stack
.Command:
    mov eax,[esp+.wParam]
    push dword .RetFalse
    cmp eax,IDCANCEL
    je .cmdCancel
    ;cmp eax,cmdSetStyle.Id
    ;je .cmdSetStyle
    cmp eax,cmdAbout.Id
    je .cmdAbout
    cmp eax,txtWndText.Id|(EN_SETFOCUS<<16)
    je .txtGotFocus
    cmp eax,cmdPause.Id
    je near .cmdPause
    ret

.cmdCancel:
    api PostQuitMessage,0
    ret

.cmdHelp:
    push dword .RetTrue
.cmdAbout:
    ; attempt to active IME :-(  does not work
    ;api LoadKeyboardLayout, "00000411", 0;KLF_ACTIVATE|KLF_REORDER
    ;api ActivateKeyboardLayout, 0411h, 0
    ;?? api ImmConfigureIME, 0411h,[hwnd],1,NULL
    ;api DefWindowProc, [hwnd],WM_INPUTLANGUAGECHANGEREQUEST, TRUE,411411h
    ;api PostMessage, [hwnd],WM_INPUTLANGUAGECHANGEREQUEST, TRUE,4110411h

    api MessageBox, [hwnd],Text.About,ProgramTitle,MB_OK|MB_ICONINFORMATION ;|MB_SETFOREGROUND
    ret

.txtGotFocus:
    api PostMessage, [txtWndText],EM_SETSEL, 0,-1
    ret

%if 0
.cmdSetStyle:
    api GetWindowLong, [WndHwnd],GWL_STYLE
    mov [WndStyle],eax
    debugwrite "window style = %x",eax

    ;api InvalidateRect, [WndHwnd],NULL,TRUE

    ;api SendMessage, [WndHwnd],LVM_SETEXTENDEDLISTVIEWSTYLE,0,LVS_EX_GRIDLINES|LVS_EX_FLATSB|LVS_EX_FULLROWSELECT|LVS_EX_CHECKBOXES|LVS_EX_TWOCLICKACTIVATE|LVS_EX_ONECLICKACTIVATE

    ;api GetWindowThreadProcessId, [WndHwnd],WndPid
    ;api CreateRemoteThread, [WndPid],NULL,32768,SomeWhere,WndHwnd,0,[WndTid]
    ;api CloseHandle, [WndTid]
    ret
%endif

.cmdPause: ;destroy timer if necessary
    api SendMessage, [cmdPause],BM_GETCHECK, 0,0
    test eax,eax
    jnz .ClickPaused
    api SetTimer,[hwnd],1,500,NULL
    ret
.ClickPaused:
    api KillTimer,[hwnd],1
    ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
.ShowWindowInfo:

    ;api GetDesktopWindow

    ;add dword [msg+MSG.pt], byte 10
    ;add dword [msg+MSG.pt+4], byte 20
    api WindowFromPoint, [msg+MSG.pt],[msg+MSG.pt+4]
    ;api ChildWindowFromPoint, eax, [msg+MSG.pt],[msg+MSG.pt+4]
    ;api ChildWindowFromPointEx, eax, [msg+MSG.pt],[msg+MSG.pt+4], CWP_ALL
    cmp [WndHwnd],eax ;***
    je near .NoWindowChange
    mov [WndHwnd],eax

    api GetWindowThreadProcessId, eax,WndPid
    cmp eax,[SelfTid]
    je near .NoWindowChange
    mov [WndTid],eax

    push esi,edi

    xor edx,edx
    api SendMessage, [lstWndAtrs],LB_RESETCONTENT,edx,edx

    push "handle=%X",dword [WndHwnd]
    call .AddString

    api GetClassName, [WndHwnd],WndClass,256
    push "class=%s",dword WndClass
    call .AddString

    api GetWindowLong, [WndHwnd],GWL_WNDPROC
    push "wndproc=%X",eax
    call .AddString

    api GetWindowLong, [WndHwnd],GWL_STYLE
    mov [WndStyle],eax
    push "style=%X",eax
    call .AddString

    api GetWindowLong, [WndHwnd],GWL_EXSTYLE
    mov [WndExStyle],eax
    push "ex_style=%X",eax
    call .AddString

    api GetWindowLong, [WndHwnd],GWL_HWNDPARENT
    push "parent=%X",eax
    call .AddString

    api GetWindow, [WndHwnd],GW_OWNER
    ;mov [WndOwner],eax
    push "owner=%X",eax
    call .AddString

    api GetWindowLong, [WndHwnd],GWL_ID
    push "menuid=%X",eax
    call .AddString

    push "process_id=%X",dword [WndPid]
    call .AddString
    push "thread_id=%X",dword [WndTid]
    call .AddString

    api GetWindowLong, [WndHwnd],GWL_HINSTANCE
    mov [WndStyle],eax
    push "modulebase=%X",eax
    call .AddString

    api IsWindowUnicode, [WndHwnd]
    mov esi,StrTrue
    test eax,eax
    jnz .IsUnicode
    mov esi,StrFalse
.IsUnicode:
    push "unicode=%s",esi
    call .AddString

    api IsWindowEnabled, [WndHwnd]
    mov esi,StrTrue
    test eax,eax
    jnz .IsEnabled
    mov esi,StrFalse
.IsEnabled:
    push "enabled=%s",esi
    call .AddString

    ; get text from app (checking first that it is not frozen)
    mov dword [WndText],0 ;just in case no text is copied
    xor edx,edx
    api SendMessageTimeout, [WndHwnd], WM_GETTEXTLENGTH, edx,edx, SMTO_ABORTIFHUNG,2000,WndTextLen
    test eax,eax
    jz .AppFrozen

    api DefWindowProc, [WndHwnd], WM_GETTEXT, WndText_size,WndText
    push eax
    push "textlen=%d",dword [WndTextLen]
    call .AddString
    mov esi,WndText
    pop eax
    cmp [WndTextLen],eax
    je .ShowWndText
    String StrAccessDenied,"<access was denied>",0
    mov esi,StrAccessDenied
.ShowWndText:
    api SetWindowText, [txtWndText],esi

    ; <testing>
    ;api GetWindowText, [WndHwnd],WndText,WndText_size
    ;api SendMessageW, [WndHwnd],WM_GETTEXT, WndText_size,WndText
    ;- get Unicode text from status bar
    ;api SendMessageTimeout, [WndHwnd], WM_USER+13, 0,WndText, SMTO_ABORTIFHUNG,4000,0
    ;and eax,65535
    ;- get Japanese using undocumented message
    ;api SendMessageTimeout, [WndHwnd], [MlGetText], 0,WndText, SMTO_ABORTIFHUNG,4000,WndTextLen
    ;String TestText, dw 'H','i',0
    ;api SendMessageTimeout, [WndHwnd], [MlSetText], 0,TestText, SMTO_ABORTIFHUNG,4000,0
.AppFrozen:

    push "mlgettext=%4X", dword [MlGetText]
    call .AddString

    pop esi,edi
.NoWindowChange:
    xor eax,eax
    ret 16

; (string, value)
.AddString:
    api wsprintf, TempString,[esp+8],[esp+8]
    add esp,byte 12
    api SendMessage, [lstWndAtrs],LB_ADDSTRING,0,TempString
    ret 8

%if 0
.CaptureChanged:
    mov dword [MouseCaptured],FALSE
    xor eax,eax
    ret 16
%endif

%ifdef debug
.MouseMove:
    api WindowFromPoint, [msg+MSG.pt],[msg+MSG.pt+4]
    debugwrite "hwnd at point = %X",eax
    xor eax,eax
    ret 16
%endif

%if 0
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; RetFalse on stack
.ListSelected:
    cmp dword [esp+.wParam],lstWndAtrs.Id|(LBN_SELCHANGE<<16)
.SelectedFile:
    ret
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Copies a control structure onto parameter stack and calls CreateWindowEx.
; Sets the font for each control, assumes the standard GUI font has already
; been obtained.
CreateChildWindow:
    debugwrite "creating child window"

    push esi,edi
    mov esi,[esp+4+8]
    xor eax,eax                 ;null window creation data
    push eax                    ;null parameter
    push dword wc.BaseAddress
    push dword [esi+WndControlStruct.hId]
    push dword [hwnd]           ;handle of parent window
    ;cld
    sub esp,byte 8*4
    add esi,byte WndControlStruct.dwExStyle
    mov ecx,8
    mov edi,esp
    rep movsd
    api CreateWindowEx
    debugwrite "child window=%d",eax

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
section bss
.Buffer:        resb .DefMaxLen+1
section code
%endif
