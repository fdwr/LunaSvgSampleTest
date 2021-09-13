; Tilemap Viewer - Savestate/Rom array viewer
; PeekinSoŸt (c)2001
;
; By Dwayne Robinson (FDwR@hotmail.com)
; http://fdwr.tripod.com/snes.htm
; Assembly compiled with NASM and WDOSX
;
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

%define ProgVersion ".200"

[section code code]
[section data data]
[section bss bss]
global Main


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GuiDebugMode       equ 0
%define UseGuiGfx               ;use extra graphics routines specific to GUI
%define UseDefaultVgaScreen     ;use standard (but old) mode 320x200:256
%define UseVirtualScreen        ;draw to buffer before copying to screen
%define UseGuiPalette           ;include the standard GUI palette
%define UseGuiCursor            ;use mouse and cursor
%define UseGuiFonts             ;include standard small fonts
%define UseSmallScreen

%define UseWindowCode           ;include defs and code for window
%define UseTitleBarCode
%define UseTextPromptCode
%define UseLabelCode
%define UseImageCode
%define UseBorderCode
%define UseScrollHandleCode
%define UseButtonCode
%define UseAtrListCode
%define UseMainBgCode
%define UseTabStripCode
%define UseAtrBarCode
%define UseListCode

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section .bss
; global program variables
Program:
.DataSelector:      resd 1  ;necessary for interrupt handlers
;.PspSelector:       resd 1  ;selector to PSP
;.ParamCount:        resd 1  ;number of parameters
;.ParamTable:        resd 1  ;array of pointers to each one
;.Env:               resd 1  ;command environment strings
;.PicBaseMaster:     resb 1
;.PicBaseSlave:      resb 1

%include "..\gui\gfxdefs.asm"   ;graphics color constants, font characters...
%include "..\gui\guidefs.asm"   ;GUI messages and object definitions

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section .text

Main:
    ;mov [Program.ParamCount],esi   ;save the number of parameters,
    ;mov [Program.ParamPtrs],edi    ;array of pointers to each one,
    ;mov [Program.Env],ebp          ;and command environment strings
    ;mov [Program.PspSelector],es
    mov dword [Program.DataSelector],ds
    push ds
    pop es

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GuiLoop:
    push dword MainWindow       ;window data structure
    InitGfx
    InitGui

.Top:
.GetKey:
    call GetKeyboardMsg
    jc .NoKeyChange             ;return value is irrelevant if cf set
    cmp ah,VK_ESCAPE            ;quit?
    je near .Exit
    ;push dword MainWindow       ;window data structure
    call SendKeyMsg             ;send keypress to active window
    ;lea esp,[esp+byte 4]
    jnc .GetKey
.NoKeyChange:

.GetMouse:
    call GetMouseMsg            ;press/release/move
    jc .NoMouseChange
    push dword [Cursor.Col]
    push dword [Cursor.Row]
    push dword MainWindow       ;send mouse message to window cursor is over or window which grabbed focus
    call SendMouseMsg           ;click/move/enter/exit
    add esp,byte 12
.NoMouseChange:

    call SendTimeMsgs

    ; tell any items that need to redraw themselves to do it now
    btr dword [Cursor.Redraw],0
    jc .CursorChanged
    test dword [MainWindow+GuiObj.Flags],GuiObj.Redraw
    jz .NoRedraw
.CursorChanged:
   %ifndef UseVirtualScreen
    call HideCursorImage
   %endif
    test dword [MainWindow+GuiObj.Flags],GuiObj.Redraw
    jz .RedrawCursor
    call SaveDisplay            ;save main window's display vars
    push dword MainWindow
    call SendRedrawMsgsLayered  ;redraw all main items, cascading down to each contained item
    pop ebx                     ;discard window ptr
    and dword [MainWindow+GuiObj.Flags],~GuiObj.Redraw
    call RestoreDisplay         ;restore main window's display vars
.RedrawCursor:
   %ifdef UseVirtualScreen
    call DrawCursorImage
    call TransferScreen
    call HideCursorImage
   %else
    call DrawCursorImage
   %endif
.NoRedraw:
    jmp .Top

.Exit:
    DeinitGui
    pop ebx
    ;jmp EndProgram


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
EndProgram:
    mov eax,4C00h               ;die
    int 21h


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

    %include "..\gui\guicode.asm"      ;core GUI functions
    %include "..\gui\guiobjs.asm"      ;item code, buttons, prompts, menus
    %include "..\gui\gfx.asm"          ;graphics routines, font, and palette


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section .data
align 4

FrameCounter    equ TickCountPtr ;dd 0

IncDefPalette
IncDefCursors
IncDefFonts

align 4
        ; This is the top of the heirarchy, the container that contains all
        ; others. Technically, it could be named anything.
        %define GuiObjContainer NullGuiItem
        MainWindow.Idx equ 0
        DefItem MainWindow,WindowCode,NullGuiItem,GuiObj.Redraw|GuiObj.RedrawBg|GuiObj.MouseFocus|GuiObj.FixedPosition|GuiObj.FixedLayer, 0,0,Screen.Height,Screen.Width
        DefWindow NullGuiItem,0,0

        %define GuiObjContainer MainWindow
        %include "..\gui\tmvgui.asm"


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section .bss
ProcessList:
        DefProcessList 16
