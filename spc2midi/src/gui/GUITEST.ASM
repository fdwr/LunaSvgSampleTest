;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; GUI objects test
; Messy temporary file for testing purposes.  
; Peekin (Dwayne Robinson)
;
; The real GUI code:
;   GuiDefs.asm - structure definitions, constants, messages, macros
;   GuiCode.asm - common communication functions (input, output, messages)
;   GuiObj.asm - object code for common items (buttons, lists, containers)
;   GfxDefs.asm - graphics definitions, constants, macros
;   Gfx.asm - graphics functions (squares, lines, fonts, pictures)

; Parameter Notation:
;   Before each routine, you may see a set of parameters in parenthesis. The
;   first set are the parameters in. The second set, if even present, are the
;   parameters out, or return values. Routines may either accept parameters on
;   the stack or directly by register. Unlike C routines, expect these
;   functions to modify any/all general registers, but leave alone any segment
;   registers, esp, and ebp. So save any that need to be retained.

; Returns Values:
;   Most GUI functions and object items indicate an error by setting cf. When
;   sending messages, cf means the message was unrecognized or ignored. For
;   example, keyboard input sent to a label (which can't accept key input)
;   would be ignored, and carry would be set.

; Pseudocode:
;   For some of the more complex functions I kept the pseudocode. It should
;   make the code easier to understand. Sometimes I need to reread it just to
;   understand again.


%define debug
GuiDebugMode       equ 0
; 0-none 1-show messages 2-debug overlay 4-redraw everything 8-color rotation
; 16-show mouse area 32-show owner messages

[section code code]
CodeStart:
[section data data]
DataStart:
[section text data]
TextStart:
[section bss bss]
BssStart:

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; global program variables
section bss

Program:
%define Program.NameDef  "GUI Test"
%define Program.TitleDef "Peekin's GUI Test Program"
%define Program.ClassDef "PknGuiTest"
%ifdef DosVer
.DataSelector:       resd 1  ;necessary for interrupt handlers
;.Env:               resd 1  ;command environment strings
;.PspSelector:       resd 1  ;selector to PSP
;.ParamCount:        resd 1  ;number of parameters
;.ParamTable:        resd 1  ;array of pointers to each one
;.PicBaseMaster:     resb 1
;.PicBaseSlave:      resb 1
%endif
.BaseAddress        equ 400000h ;base address of program (Windows module handle)

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Include GUI & graphics definitions/constants/macros
section code

%define GuiVer
%define UseWindowCode           ;include defs and code for window
%define UseFrameCode            ;frame
%define UseWindowBgCode         ;window background
%define UseMainBgCode           ;main gui background
%define UseTitleBarCode
%define UseTextPromptCode
%define UseLabelCode
%define UseImageCode
%define UseBorderCode
%define UseScrollHandleCode
%define UseButtonCode
%define UseAtrListCode          ;attribute list
%define UseTabStripCode
%define UseAtrBarCode           ;attribute bar
%define UseListCode
;%define UseFloatMenuCode
%define UseEmbedMenuCode
Timer.MaxItems equ 16
%include "guidefs.asm"          ;GUI messages and object definitions

%define UseGuiGfx               ;use extra graphics routines specific to GUI
%define UseDisplayBuffer 1      ;draw to buffer before copying to screen
%define UseGuiPalette           ;include the standard GUI palette
%define UseGuiCursor            ;use mouse and cursor
%define UseGuiFonts             ;include standard handdrawn fonts
;%define UseSmallScreen
%ifdef WinVer
 Screen.Height       equ 452
 Screen.Width        equ 640
 ;Screen.Height       equ 4
 ;Screen.Width        equ 4
 ;Screen.Height       equ 320
 ;Screen.Width        equ 200
 ;Screen.Height       equ 284 ;(chartest)
 ;Screen.Width        equ 308
%else
 %define UseDefaultVgaScreen     ;use standard (but old) mode 320x200:256
 ;Screen.Height       equ 200
 ;Screen.Width        equ 320
 ;Screen.Adr          equ 0A0000h     ;physical address of screen
%endif
%include "gfxdefs.asm"          ;graphics color constants, font characters...

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Include Windows definitions/constants/macros
%ifdef WinVer
%define UseWindowStyles
%define UseWindowControls
%define UseWindowMsgs
%define UseWindowPaint
%define UseWindowGfx
%define UseWindowSysVars
;%define UseWindowHooks
;%define UseDxDraw
;%define UseCom
%include "mywininc.asm"         ;standard Windows constants, structs...

section data
align 4, db 0
hwnd:   dd 0                    ;window handle
hdc:    dd 0                    ;class device context
hpal:   dd 0                    ;palette handle
;tid:   dd 0                    ;thread identifier

wc:
istruc WNDCLASS
at WNDCLASS.style,         dd CS_CLASSDC
at WNDCLASS.lpfnWndProc,   dd MsgProc
at WNDCLASS.cbClsExtra,    dd 0
at WNDCLASS.cbWndExtra,    dd 0
at WNDCLASS.hInstance,     dd Program.BaseAddress ;(default image base is at 4MB)
at WNDCLASS.hIcon,         dd NULL
at WNDCLASS.hCursor,       dd NULL
at WNDCLASS.hbrBackground, dd NULL ;COLOR_BTNFACE + 1 (no flickery bg brush)
at WNDCLASS.lpszMenuName,  dd NULL
at WNDCLASS.lpszClassName, dd Program.Class
iend

rect:
point:
dd 0,            0             ;left,top
dd Screen.Width, Screen.Height ;right,bottom

section bss
msg:    resb MSG_size
ps:     resb PAINTSTRUCT_size

%else
 %macro debugwrite 1-*
 %endmacro
%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
section code

global Main
Main:
%ifdef DosVer
    mov dword [Program.DataSelector],ds  ;data selector
    ;mov dword [Program.PspSelector],es  ;PSP selector
    ;mov [Program.Env],ebp               ;and command environment strings
    push ds
    pop es
%endif

%ifdef WinVer
    ; Defeat Window's on demand page loading so that the executable file is
    ; simply read sequentially instead of the system jumping everywhere.
    ; It gets the process out of the way all at once, rather than bits and
    ; pieces here and there. No post load disk clicking (except other DLLs).
    mov esi,CodeStart
    mov ecx,TextEnd
    sub ecx,esi                 ;TextEnd-CodeStart = total page bytes
    shr ecx,12                  ;/4096 = total pages
.NextPage:
    mov eax,[esi]               ;force page fault
    add esi,4096                ;next 4k page
    dec ecx
    jg .NextPage
%endif

%if GuiDebugMode & 33
    mov eax,esp
    sub eax,byte 32+12
    mov [PrintDebugMessage.SpIndent],eax
%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
%ifdef WinVer


    ;debugpause "Total mem = %d", (BssEnd-BssStart); + (DataEnd-DataStart)
    CreateGuiWin                ;create main ui window
    push dword MainWindow       ;window data structure
    InitGfx                     ;initialize graphics
    InitGui                     ;initialize user interface elements
    api ShowWindow, [hwnd],SW_SHOWDEFAULT

    nop                         ;soley for debugging
    nop
    nop

    debugwrite "entering main loop"
.NoMsg:
    call .Redraw
    api WaitMessage

.NextMsg:
    xor eax,eax
    api PeekMessage, msg, eax,eax,eax,PM_REMOVE
    test eax,eax
    jz .NoMsg
    mov eax,[msg+MSG.message]
    cmp eax,WM_TIMER
    je near .Timer
    ;debugwinmsg "thread msg=%X %s",eax,edx

    cmp eax,WM_KEYFIRST
    jb .NotKeyMsg
    cmp eax,WM_KEYLAST
    jbe near .KeyMsg
.NotKeyMsg:
    cmp eax,WM_MOUSEFIRST
    jb .NotMouseMsg
    cmp eax,WM_MOUSELAST
    jbe near .MouseMsg
.NotMouseMsg:
    ;cmp eax,WM_TIMER
    ;je near .Timer
    cmp eax,WM_PAINT
    je near MsgProc.ThreadPaint
    cmp eax,WM_QUIT
    je .Quit

    api DispatchMessage, msg
    jmp .NextMsg

;컴컴컴컴컴컴컴컴컴컴
.Quit:
    ;debugwrite "terminating program"
    push dword MainWindow       ;window data structure (redundant push)
    DeinitGui
.Terminate:
    api ExitProcess,[msg+MSG.wParam]

;컴컴컴컴컴컴컴컴컴컴
; (dword main window, eax=message)
.KeyMsg:
    call GetKeyboardMsg
    jc near .NextMsg

    cmp al,Msg.KeyPress
    jne .NotPress               ;ignore releases and characters
    cmp ah,VK_F2
    je near .FakeMouse
    cmp ah,VK_F9
    je near .ClearBuffer
    cmp ah,VK_F10
    je near .RedrawAll
    cmp ah,VK_F11
    je near .ClearWindow
    cmp ah,VK_F12
    je near .Quit
.NotPress:
    debugwrite "MainWindow: sending keypress %X",eax
    ;push dword MainWindow      ;window data structure
    call SendKeyMsg             ;send keypress to active window
    ;lea esp,[esp+4]
    jnc near .NextMsg

    mov eax,[Keyboard.LastMsg]  ;access character and scancode
    debugwrite "MainWindow: item ignored key msg =%X",eax
    cmp al,Msg.KeyPress
    jne near .NextMsg           ;ignore releases

    debugwrite "MainWindow: item ignored key press %X",eax

    and eax,KeyMsgFlags.Repeat|65280
    cmp eax,(VK_ESCAPE<<8) ;quit?
    je near .Quit

    mov esi,TabKeys
    call ScanForKey
    jc near .NextMsg
    mov eax,[TabMsgsTbl+ecx*4]
    ;push dword 0               ;pass on dummy index
    ;push dword MainWindow      ;window data structure
    call SetItemFocus           ;set active focus
    ;add esp,byte 8
    jmp .NextMsg

.ClearWindow:
    api Rectangle, [hdc],0,0,Screen.Width,Screen.Height
    jmp .NextMsg

.RedrawAll:
    or dword [Display.RedrawFlags],Display.RedrawItems
    or dword [MainWindow+GuiObj.Flags],GuiObj.RedrawBg
    mov dword [MainWindow+WindowObj.RedrawTopLeft],0
    mov dword [MainWindow+WindowObj.RedrawBtmRight],Screen.Height|(Screen.Width<<16)
    jmp .NextMsg

.ClearBuffer:
    call HideCursor
    ;or dword [Display.RedrawFlags],Display.RedrawItems
%if 0 ;black/gray hash pattern
    cld
    mov eax,02000200h
    mov edi,[Display.Ptr];Screen.Buffer
    mov edx,Screen.Height
.ClearNextRow:
    mov ecx,Screen.Width/4
    rep stosd
    ror eax,8
    dec edx
    jg .ClearNextRow
%else ;black mesh
    mov edi,Screen.Buffer
    mov eax,00FF00FFh
    mov ebx,Screen.Height
.NextRow:
    mov ecx,Screen.Width/4
.NextCol:
    and [edi],eax
    add edi,byte 4
    dec ecx
    jg .NextCol
    rol eax,8
    dec ebx
    jg .NextRow
%endif
    call DrawCursor
    ;api InvalidateRect, [hwnd],NULL,FALSE
    xor eax,eax
    api InvalidateRect, [hwnd],eax,eax
    jmp .NextMsg

    cmp ah,VK_F1
    jne .NotCapture
    push eax
    push ebp
    mov ebp,esp
    sub esp,256
    debugwrite "Before test function esp=%X",esp
%if 1
    ;api SetSystemPaletteUse, [hdc],SYSPAL_STATIC
    ;push dword SYSPAL_STATIC
    ;push dword [hdc]
    ;extern SetSystemPaletteUse
    ;call [SetSystemPaletteUse]
    ;api RealizePalette, [hdc]

    api SelectPalette, [hdc],[hpal],FALSE
    ;api UnrealizeObject, [hpal]
    api RealizePalette, [hdc]
%elif 0
    mov eax,Msg.SetItemFocus|FocusMsgFlags.Specified|FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.SetContainer|FocusMsgFlags.ByMouse
    mov ebx,window21
    call SendContainerMsg
%endif
    debugwrite "After test function esp=%X",esp
    mov esp,ebp
    pop ebp
    pop eax
.NotCapture:

.FakeMouse:
    MOUSEEVENTF_LEFTDOWN equ 2
    MOUSEEVENTF_LEFTUP   equ 4
    api mouse_event, MOUSEEVENTF_LEFTDOWN, 0,0, 0,0
    api mouse_event, MOUSEEVENTF_LEFTUP,   0,0, 0,0
    jmp .NextMsg

;컴컴컴컴컴컴컴컴컴컴
; (dword main window, eax=message)
.MouseMsg:
    call GetMouseMsg
    jc near .NextMsg

    test dword [Mouse.Buttons],Mouse.RightPress ;<- redundant program quit
    jz .NotPrsRls
    cmp dword [Cursor.Row],30    ;quit?
    jae .NotPrsRls
    cmp dword [Cursor.Col],30    ;quit?
    jb near .Quit
.NotPrsRls:

    test dword [Mouse.Buttons],Mouse.LeftPress
    jz .NoMouseActivate
    test dword [GuiFlags],GuiFlags.Suspended
    jz .NoMouseActivate
    push eax
    xor eax,eax
    api SetWindowPos, [hwnd],HWND_TOP, eax,eax, eax,eax, SWP_NOMOVE|SWP_NOSIZE|SWP_NOSENDCHANGING
    pop eax
.NoMouseActivate:

    ;debugwrite "mouse %d %d %X fk=%X",[Cursor.Row],[Cursor.Col],[Mouse.Buttons],[msg+MSG.wParam]
    push dword [Cursor.Col]
    push dword [Cursor.Row]
    push dword MainWindow       ;send mouse message to window cursor is over or window which grabbed focus
    call SendMouseMsg           ;click/move/enter/exit
    add esp,byte 12

   %if GuiDebugMode & 16
    mov al,5
    mov ebx,MainWindow
    call HighlightMouseArea
    call ShowMouseInfo
    api InvalidateRect, [hwnd],NULL,FALSE
   %endif
    jmp .NextMsg

;컴컴컴컴컴컴컴컴컴컴
.Timer:
    ;mov eax,[msg+MSG.time]
    ;sub eax,[Timer.Now]
    ;debugwrite "time value now=%d  dif=%d",[msg+MSG.time],eax
    push dword .NextMsg
    jmp SendTimeMsgs

;컴컴컴컴컴컴컴컴컴컴
.Redraw:
    test byte [Display.RedrawFlags],Display.RedrawItems|Display.RedrawCursor|Display.RedrawPalette|Display.CursorMoved
    jz .NoRedraw
.RedrawNow:

    call HideCursor
    test byte [Display.RedrawFlags],Display.RedrawItems
    jz .RedrawCursor            ;only cursor moved or palette changed

    call SaveDisplayVars        ;save main window's display vars
    push dword MainWindow
    call SendRedrawComplex      ;redraw all main items, cascading down to each contained item
    ;call SendRedrawSimple       ;redraw all main items, cascading down to each contained item
    pop ebx                     ;discard window ptr
    and dword [MainWindow+GuiObj.Flags],~GuiObj.Redraw
    api InvalidateRect, [hwnd],Display.Clips,FALSE
    ;api InvalidateRect, [hwnd],NULL,FALSE
    call RestoreDisplayVars     ;restore main window's display vars

.RedrawCursor:
    call DrawCursor
    and byte [Display.RedrawFlags],~(Display.RedrawItems|Display.RedrawCursor|Display.RedrawPalette|Display.CursorMoved)
.NoRedraw:
    ret


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
MsgProc:
    params .hwnd, .message, .wParam, .lParam

    mov eax,[esp+.message]
    ;debugwinmsg "win msg=%X %s W=%X L=%X", eax,edx,[esp+.wParam+4],[esp+.lParam]

    ;cmp eax,WM_DESTROY
    ;je near .Destroy
    ;jmp [DefWindowProc]

    ; WM_KEYDOWN, WM_SYSKEYDOWN send key msg
    ; WM_SETFOCUS flag active
    ; WM_KILLFOCUS flag inactive
    ; WM_ENTERMENULOOP flag inactive
    ; WM_EXITMENULOOP flag active (partially)
    ; WM_PALETTECHANGED call UpdateColors
    ; WM_QUERYNEWPALETTE call RealizePalette

;   cmp eax,WM_CREATE
;   je .Create
;   cmp eax,WM_NCCREATE
;   je .NcCreate
;   cmp eax,WM_ACTIVATE
;   je near .Activate

    cmp eax,WM_QUERYNEWPALETTE
    je near .SetPalette
    ;cmp eax,WM_PALETTECHANGED
    ;je near .PaletteChanged
    cmp eax,WM_TIMER
    je near .Timer
    cmp eax,WM_PAINT
    je near .Paint
    cmp eax,WM_CAPTURECHANGED
    je near .CaptureChanged
    ;cmp eax,WM_SETCURSOR
    ;je .RetTrue
    ;cmp eax,WM_NCACTIVATE       ;never redraw title bar!
    ;je near .RetFalse
    cmp eax,WM_NCCALCSIZE       ;tell Windows to not mess with our client area
    je .RetFalse
    cmp eax,WM_NCPAINT
    je .RetFalse
    cmp eax,WM_NCHITTEST
    je .RetTrue
    cmp eax,WM_WINDOWPOSCHANGING
    je .RetFalse
    cmp eax,WM_ERASEBKGND
    je .RetTrue
    cmp eax,WM_WINDOWPOSCHANGED
    je .RetFalse
    cmp eax,WM_MOVING
    je .RetTrue
    ;cmp eax,WM_CANCELMODE
    ;je .RetFalse
    cmp eax,WM_SETFOCUS
    je .GainFocus
    cmp eax,WM_KILLFOCUS
    je .LoseFocus

    cmp eax,WM_DESTROY
    je .Destroy
    ;cmp eax,...

    jmp [DefWindowProc]

.RetTrue:
    mov eax,TRUE
    ret 16

.Destroy:
    ;debugwrite "destroying window"
    api PostQuitMessage,0
.RetFalse:
    xor eax,eax
    ret 16

.GainFocus:
    mov eax,Msg.KeyIn|KeyMsgFlags.WindowInOut|KeyMsgFlags.SetItem
    and dword [GuiFlags],~(GuiFlags.Suspended|GuiFlags.InMenu)
    and dword [MainWindow+GuiObj.Flags],~GuiObj.ContainerFocus
    ;call .GetExclusiveColors
    jmp short .SetFocus
.LoseFocus:
    mov eax,Msg.KeyOut|KeyMsgFlags.WindowInOut
    or dword [GuiFlags],GuiFlags.Suspended
    or dword [MainWindow+GuiObj.Flags],GuiObj.ContainerFocus
    ;api SetSystemPaletteUse, [hdc],SYSPAL_STATIC
.SetFocus:
    test dword [GuiFlags],GuiFlags.Active
    jz .InactiveFocus
    push dword MainWindow, eax, esi,edi,ebx
    call SetItemFocus.OfActive
    mov eax,[esp+4]
    call SetKeyFocus.OfActive
    pop edx, eax,esi,edi,ebx
.InactiveFocus:
    xor eax,eax
    ret 16

.ThreadPaint:
    sub esp,byte 12             ;dummy stack adjustment
    push dword [msg+MSG.hwnd]
    push dword Main.NextMsg
.Paint:
    push esi,edi,ebx
    call Main.Redraw            ;combine any required redrawing into this
    api BeginPaint, [esp+.hwnd+16],ps
    ;api BeginPaint, [hwnd],ps
    call TransferScreen
    ;api EndPaint, [hwnd],ps
    api EndPaint, [esp+.hwnd+16],ps
    pop esi,edi,ebx
    xor eax,eax
    ret 16


%if 0
.GetExclusiveColors:
    api SetSystemPaletteUse, [hdc],SYSPAL_NOSTATIC
    api SelectPalette, [hdc],[hpal],FALSE
    api UnrealizeObject, [hpal]
    api RealizePalette, [hdc]
    api SendMessage, HWND_BROADCAST, WM_SYSCOLORCHANGE, 0,0
    ret
%endif

%if 0
.HitTest:
    movzx edx,word [esp+.lParam+2]
    sub edx,[wndTop]
    mov eax,HTCAPTION
    cmp edx,22
    jb .HitCaption
    mov eax,HTCLIENT
.HitCaption:
    ret 16
%endif

%if 0
.Moving:
    mov eax,[esp+.lParam]
    test dword [eax+24],SWP_NOMOVE
    jnz .MovingNowhere
    mov ecx,[eax+8]
    mov edx,[eax+12]
    ;debugwrite "!!Moved row=%d",edx
    mov [wndTop],edx
    mov [wndLeft],ecx
.MovingNowhere:
    xor eax,eax
    ret 16
%endif

; This is only reached if a menu or exclusive dialog is active.
; Otherwise, timer events are handled directly in the main thread loop,
; shortcutting the message dispatching.
.Timer:
    api GetMessageTime
    mov [Timer.Now],eax
    call SendTimeMsgs
    test byte [Display.RedrawFlags],Display.RedrawItems|Display.RedrawCursor|Display.RedrawPalette|Display.CursorMoved
    jz .NoRedraw
    xor eax,eax
    api PostMessage, [hwnd],WM_PAINT, eax,eax
.NoRedraw:
    xor eax,eax
    ret 16

.CaptureChanged:
    debugwrite "capture changed %X",[esp+.lParam]
    mov edx,[esp+.lParam]
    xor eax,eax
    cmp [hwnd],edx
    je .CaptureSame
    mov [Mouse.hwnd],eax
.CaptureSame:
    ret 16

%if 0
.Activate:
    mov eax,[esp+.wParam]
    cmp ax,WA_INACTIVE
    je .Inactive
    test eax,0FFFF0000h
    jnz .Inactive
    ;api ShowWindow, [hwnd],SW_RESTORE
.Inactive:
    ;jmp [DefWindowProc]
    xor eax,eax
    ret 16
%endif

.SetPalette:
    ;api UnrealizeObject, [hpal]
    api SelectPalette, [hdc],[hpal],FALSE
    api RealizePalette, [hdc]
    debugwrite "palette realized, colors=%d",eax
    mov eax,TRUE                ;palette realized
    ;xor eax,eax
    ret 16

%if 0
.PaletteChanged:
    mov eax,[esp+.wParam]
    cmp [hwnd],eax
    je .PaletteSelf
    ;api UnrealizeObject, [hpal]
    ;api RealizePalette, [hdc]
    ;debugwrite "palette changed, colors=%d",eax
    api UpdateColors, [hdc] ;(slow)
.PaletteSelf:
    xor eax,eax
    ;or dword [Display.RedrawFlags],Display.RedrawPalette
    ;api InvalidateRect, [hwnd],eax,eax ;NULL,FALSE
    ret 16
%endif


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
%elifdef DosVer

    push dword MainWindow       ;window data structure
    InitGfx
    InitGui

%if 1
    mov edi,Screen.Buffer+(320*100)+4
    xor eax,eax
    mov ecx,16
.NextColorBar:
    mov [edi],eax
    mov [edi+4],eax
    mov [edi+320],eax
    mov [edi+324],eax
    add edi,640
    add eax,01010101h
    loop .NextColorBar
%endif

    nop
    nop
    nop

;컴컴컴컴컴컴컴컴컴컴
.Top:
.GetKey:
    call GetKeyboardMsg
    jc near .NoKeyChange        ;return value is irrelevant if cf set
%if GuiDebugMode & 1
    mov ebx,eax
    DebugMessage "keypress"
%endif
    cmp ah,VK_F12;ESCAPE            ;quit?
    je near .Quit

%if 0
    ; clear screen on every keypress
    cmp al,Msg.KeyPress
    jne .IgnoreRelease
    pusha
 %if 0
    call .ClearScreenBuffer
 %elif 1
    or dword [MainWindow+GuiObj.Flags],GuiObj.RedrawBg
    mov dword [MainWindow+WindowObj.RedrawTopLeft],0
    mov dword [MainWindow+WindowObj.RedrawBtmRight],Screen.Height|(Screen.Width<<16)
 %endif
    popa
.IgnoreRelease:
%endif

    ;push dword MainWindow      ;window data structure
    call SendKeyMsg             ;send keypress to active window
    ;lea esp,[esp+byte 4]
    jnc .GetKey

    cmp ah,VK_ESCAPE            ;quit?
    je near .Quit

    mov eax,[Keyboard.LastMsg]  ;access character and scancode
    cmp al,Msg.KeyPress
    jne .GetKey                 ;ignore releases
    mov esi,TabKeys
    call ScanForKey
    jc .NotTab

.Tab:
    mov eax,[TabMsgsTbl+ecx*4]
    ;push dword 0               ;pass on dummy index
    ;push dword MainWindow      ;window data structure
    call SetItemFocus           ;set active focus
    ;add esp,byte 8
    jmp short .GetKey

.NotTab:
    ;test eax,KeyMsgFlags.Repeat
    ;jnz .GetKey
    cmp ah,VK_F9
    jne .NotFullRedraw
    or dword [MainWindow+GuiObj.Flags],GuiObj.RedrawBg
    mov dword [MainWindow+WindowObj.RedrawTopLeft],0
    mov dword [MainWindow+WindowObj.RedrawBtmRight],Screen.Height|(Screen.Width<<16)
    jmp .GetKey
.NotFullRedraw:

    push dword .GetKey
    cmp ah,VK_F7
    je .ClearScreenBuffer
    cmp ah,VK_F8
    je .ClearScreen
    ret

.ClearScreen:
   %if GuiDebugMode & 33
    mov dword [PrintDebugMessage.Row],0
   %endif

    cld
    mov eax,02000200h
    ;or dword [MainWindow+GuiObj.Flags],GuiObj.RedrawPartial
    mov edi,Screen.Buffer
    mov edx,Screen.Height
.ClearNextBufferRow:
    mov ecx,Screen.Width/4
    rep stosd
    ror eax,8
    dec edx
    jg .ClearNextBufferRow

.ClearScreenBuffer:
    or dword [Display.RedrawFlags],Display.RedrawItems
    cld
    mov eax,02000200h
    mov edi,Screen.Adr
    mov edx,Screen.Height
.ClearNextRow:
    mov ecx,Screen.Width/4
    rep stosd
    ror eax,8
    dec edx
    jg .ClearNextRow
    ;call DrawCursor
    ret
.NoKeyChange:

;컴컴컴컴컴컴컴컴컴컴
.GetMouse:
   %if GuiDebugMode & 16
    call ShowMouseInfo
    mov al,14
    mov ebx,MainWindow
    call HighlightMouseArea
   %endif
    call GetMouseMsg            ;press/release/move
    jc .NoMouseChange

    ;or dword [MainWindow+GuiObj.Flags],GuiObj.RedrawBg
    ;mov dword [MainWindow+WindowObj.RedrawTopLeft],0
    ;mov dword [MainWindow+WindowObj.RedrawBtmRight],Screen.Height|(Screen.Width<<16)

    test dword [Mouse.Buttons],Mouse.RightPress ;<- redundant program quit
    jz .NotPrsRls
    cmp dword [Cursor.Row],30    ;quit?
    jb near .Quit
.NotPrsRls:

    ;DebugMessage "Mouse change"
    push dword [Cursor.Col]
    push dword [Cursor.Row]
    push dword MainWindow       ;send mouse message to window cursor is over or window which grabbed focus
    call SendMouseMsg           ;click/move/enter/exit
    add esp,byte 12
.NoMouseChange:

;컴컴컴컴컴컴컴컴컴컴
    call SendTimeMsgs

;컴컴컴컴컴컴컴컴컴컴
; tell any items that need to redraw themselves to do it now

.Redraw:
    test byte [Display.RedrawFlags],Display.RedrawItems|Display.RedrawCursor
    jz .NoRedraw
    ;test dword [MainWindow+GuiObj.Flags],GuiObj.Redraw
    ;jnz .DoRedraw

    call HideCursor
    test byte [Display.RedrawFlags],Display.RedrawItems
    jz .RedrawCursor

    call SaveDisplayVars        ;save main window's display vars
    push dword MainWindow
    call SendRedrawComplex      ;redraw all main items, cascading down to each contained item
    pop ebx                     ;discard window ptr
    and dword [MainWindow+GuiObj.Flags],~GuiObj.Redraw
    call RestoreDisplayVars     ;restore main window's display vars

.RedrawCursor:
    call DrawCursor
  %ifdef UseDisplayBuffer
    call TransferScreen
  %endif
    and byte [Display.RedrawFlags],~(Display.RedrawItems|Display.RedrawCursor)
.NoRedraw:

   %if GuiDebugMode & 16
    mov al,15
    mov ebx,MainWindow
    call HighlightMouseArea
   %endif
    test dword [GuiFlags],GuiFlags.Active
    jnz near .Top

;컴컴컴컴컴컴컴컴컴컴
.Quit:
    push dword MainWindow       ;window data structure (redundant push)
    DeinitGui

;컴컴컴컴컴컴컴컴컴컴
;.EndProg:
    ;mov eax,3h                  ;Video BIOS: Set video mode to text
    ;int 10h
    mov eax,4C00h               ;DOS: Terminate program
    int 21h

%else
    %error "Must be DOS or Windows"

%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
section data
align 4
TabMsgsTbl:
    dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative
    dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.Reverse
    dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative
    dd FocusMsgFlags.SetItem|FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.Reverse
    dd FocusMsgFlags.SetItem|FocusMsgFlags.Relative
    dd FocusMsgFlags.SetItem|FocusMsgFlags.Relative|FocusMsgFlags.Reverse
    dd FocusMsgFlags.SetItem|FocusMsgFlags.Relative
    dd FocusMsgFlags.SetItem|FocusMsgFlags.Relative|FocusMsgFlags.Reverse
    dd FocusMsgFlags.SetGroup|FocusMsgFlags.Relative|FocusMsgFlags.Reverse
    dd FocusMsgFlags.SetGroup|FocusMsgFlags.Relative
TabKeys:
    db 2,VK_RIGHT,  0,VK_CONTROL
    db 2,VK_LEFT,   0,VK_CONTROL
    db 2,VK_DOWN,   0,VK_CONTROL
    db 2,VK_UP,     0,VK_CONTROL
    db 0,VK_RIGHT
    db 0,VK_LEFT
    db 0,VK_DOWN
    db 0,VK_UP
    db 2,VK_TAB,    0,VK_SHIFT
    db 0,VK_TAB
    db -1
section code


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
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
; 2002-09-03
; (eax=number, edi=destination, ?ecx=maximum length, ?ebx=radix)
; (esi=ptr to first significant digit, ebx=radix used; none)
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
    lea esi,[edi+1]         ;return ptr to first significant character
	ret

.FillInBlanks:
    mov al,[.FillChar]      ;fill in with spaces, zeroes, asterisks
    lea esi,[edi+1]         ;return ptr to first significant character
    dec ecx                 ;one less than current count
    ;mov edx,ecx
    std                     ;move backwards
    rep stosb               ;for number of characters remaining
    ;mov ecx,edx            ;return offset of first digit
    cld                     ;for dumb Windows sake (so it doesn't crash)
    ret

section data
align 4
.DefMaxLen      equ 10
.MaxLen:        dd .DefMaxLen
.FillChar:      db ' '
.NumberTable:   db "0123456789ABCDEF"
section bss
.Buffer:    resb .DefMaxLen
section code


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
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


%if GuiDebugMode & 33
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Sheesh, this little routine to help me debug everything else was complex
; enough to need some debugging of its own.
PrintDebugMessage:
%if 1
    pushf
    pusha
    push dword [Font.Colors]

    mov eax,ebx                 ;item ptr (assuming it is called from one)
    ;mov eax,esp
    ;sub eax,[.SpIndent]
    ;neg eax
    ;sub eax,byte 32+12
    mov edi,NumToString.Buffer
    mov ecx,8                   ;length
    mov ebx,16                  ;radix hex
    call NumToString.UsingDLRadix
    mov byte [NumToString.Buffer+8],'-'

    push dword 2                ;bg color
    push dword 8|(120<<16)      ;height/width
    mov eax,[.Row]
    push eax                    ;row
    add eax,byte 7              ;advance row down
    cmp eax,200-8-7
    jb .RowOk
    xor eax,eax
.RowOk:
    mov [.Row],eax
    call DrawRect.NoClip
    ;add esp,byte 12

    ; set indent based on stack depth
    mov ecx,esp
    sub ecx,[.SpIndent]
    neg ecx
    shr ecx,3                   ;/8
    and ecx,127
    shl ecx,16
    or [esp],ecx

    ; draw separator
    push dword 120|(5<<16)      ;width & color
    push dword [.Row]
    call DrawHline
    ;add esp,byte 8

    ; draw item address
    push dword 9
    push dword NumToString.Buffer
    push dword [esp+8+8]        ;row calculated from above
    mov dword [Font.Colors],GuiClcTxtTyped
    call BlitString
    ;add esp,byte 12

    ; draw message
    mov esi,[esp+8+32+4+12+8+12]
    call GetStringLength
    push ecx
    push esi
    push dword [esp+8]          ;row calculated from above
    add word [esp+2],36
    mov dword [Font.Colors],GuiClcTxtNormal
    call BlitString ;.AlreadyClipped
    add esp,byte 12+8+12+12

    or dword [MainWindow+GuiObj.Flags],GuiObj.RedrawPartial
    pop dword [Font.Colors]
    popa
    popf
    ret 4
%else
    pushf
    push eax
    push edx
    mov ah,9
    mov edx,[esp+12]
    int 21h
    mov eax,[.Row]
    inc eax
    cmp eax,24
    jb .RowOk
    push ebx
    mov ah,2                    ;set cursor
    xor ebx,ebx                 ;page 0
    xor edx,edx                 ;row/col 0
    int 10h                     ;Video BIOS
    xor eax,eax
    pop ebx
.RowOk:
    mov [.Row],eax
    pop edx
    pop eax
    popf
    ret 4
%endif
section data
.Row:       dd 0
.SpIndent:  dd 0
section code
%endif


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
%if GuiDebugMode & 16
HighlightMouseArea:
    movzx edi,word [ebx+WindowObj.MouseTop]
    add di,[ebx+GuiObj.Top]
    call .BlitRow
    movzx edi,word [ebx+WindowObj.MouseBtm]
    add di,[ebx+GuiObj.Top]
    call .BlitRow
    movzx edi,word [ebx+WindowObj.MouseLeft]
    add di,[ebx+GuiObj.Left]
    call .BlitColumn
    movzx edi,word [ebx+WindowObj.MouseRight]
    add di,[ebx+GuiObj.Left]
    jmp .BlitColumn
    ;ret

;(edi=row, al=color)
.BlitRow:
    cmp edi,Screen.Height
    jae .EndRowColumnBlit
  %if Screen.Width=320
    mov ecx,edi
    shl edi,8
    shl ecx,6
    lea edi,[Screen.Buffer+edi+ecx]
  %else
    imul edi,Screen.Width
    add edi,Screen.Buffer
  %endif
    mov edx,2
    mov ecx,Screen.Width/2
.NextRowColumn:
    mov byte [edi],al
    add edi,edx
    loop .NextRowColumn
.EndRowColumnBlit:
    ret
;(edi=column, al=color)
.BlitColumn:
    cmp edi,Screen.Width
    jae .EndRowColumnBlit
    add edi,Screen.Buffer
    mov ecx,Screen.Height/2
    mov edx,Screen.Width*2
    jmp short .NextRowColumn
%endif


;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
%if GuiDebugMode & 16
ShowMouseInfo:
    mov dword [NumToString.MaxLen],5
    mov eax,[MainWindow+WindowObj.MouseItem]
    cmp eax,NullGuiItem
    jne .MouseItem
    mov dword [Text.MouseObj+1],"null"
    jmp short .MouseNull
  .MouseItem:
    mov edi,Text.MouseObj
    call NumToString.UsingDest
  .MouseNull:

    mov eax,[MainWindow+WindowObj.KeyItem]
    cmp eax,NullGuiItem
    jne .KeyItem
    mov dword [Text.KeyObj+1],"null"
    jmp short .KeyNull
  .KeyItem:
    mov edi,Text.KeyObj
    call NumToString.UsingDest
  .KeyNull:

    mov eax,[Cursor.Row]
    mov edi,Text.MousePos
    mov ecx,3
    call NumToString.UsingDLen
    mov eax,[Cursor.Col]
    mov edi,Text.MousePos+4
    mov ecx,3
    call NumToString.UsingDLen

    movzx eax,word [MainWindow+WindowObj.MouseTop]
    mov edi,Text.MouseRange+0
    call NumToString.UsingDest
    movzx eax,word [MainWindow+WindowObj.MouseBtm]
    mov edi,Text.MouseRange+6
    call NumToString.UsingDest
    movzx eax,word [MainWindow+WindowObj.MouseLeft]
    mov edi,Text.MouseRange+12
    call NumToString.UsingDest
    movzx eax,word [MainWindow+WindowObj.MouseRight]
    mov edi,Text.MouseRange+18
    call NumToString.UsingDest
    push dword 2
    push dword FontDefHeight|(Screen.Width<<16) ;height/width
    push dword Screen.Height-FontDefHeight ;row
    call DrawRect.NoClip
    push dword Text.DebugInfo_Len
    push dword Text.DebugInfo
    push dword Screen.Height-FontDefHeight|(2<<16) ;row/col
    mov dword [Font.Colors],GuiClcTxtBright
    call BlitString
    add esp,byte 12+12
    ret
%endif

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

    %include "guicode.asm"      ;core GUI functions
    %include "guiobjs.asm"      ;item code, buttons, prompts, menus
    %include "gfx.asm"          ;graphics routines, font, and palette

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
section data
align 4, db 0

%assign Screen.PalColors 236
IncDefPalette
;incbin "testpic.pal",64
incbin "dev\buttonx8.pal";,64
IncDefCursors
IncDefFonts

align 4, db 0
    ; This is the top of the heirarchy, the container that contains all
    ; others. Technically it can be named anything, since none of it is
    ; hard coded into the GUI routines. No item is aware of anything but its
    ; container and siblings, making things a lot more abstract, and yet,
    ; a lot simpler!
    MainWindow.Idx equ 0
    MainWindow.Gic equ NullGuiItem
    DefItem MainWindow,WindowCode,NullGuiItem,GuiObj.Redraw|GuiObj.RedrawHandled|GuiObj.RedrawComplex|GuiObj.MouseFocus|GuiObj.FixedPosition|GuiObj.FixedLayer|GuiObj.KeyFocus, 0,0,Screen.Height,Screen.Width
    ;DefWindow NullGuiItem,0,0 ;<- use for an empty field
    ;DefContainedItem mainbg
    ;DefWindowEnd
    ;DefItem mainbg,MainBgCode,0,MainBgObj.DefFlags, 0,0,Screen.Height,Screen.Width
    ;    DefTitleBar Program.Title,Program.Title_size,TitleBarObj.HelpButton|TitleBarObj.CloseButton|TitleBarObj.MinButton

    ; otherwise include external object list
    ;%include "items8.asm"
    ;%include "tmvall.asm"
    %include "guiout.asm"
    ;%include "spcmain.asm"



section text

;%ifdef WinVer
Program.Class:   db Program.ClassDef,0
Program.Title:   db Program.TitleDef,0
Program.Title_size equ ($-Program.Title)-1
;%endif

Text:
%if GuiDebugMode & 16
.DebugInfo:     db "Cursor:"
.MousePos:      db "000x000 Mouse:"
.MouseObj:      db "00000 Range:"
.MouseRange:    db "00000:00000x00000:00000 Key:"
.KeyObj:        db "00000"
.DebugInfo_Len  equ $-.DebugInfo
%endif

[section code]
CodeEnd:
[section data]
DataEnd:
[section text]
TextEnd:
[section bss]
BssEnd:
