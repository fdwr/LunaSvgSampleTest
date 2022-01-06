section .text
bits 32
global _WdosxStart

GuiDebugMode    equ 4
%define UseGuiGfx               ;use extra graphics routines specific to GUI
%define UseGuiPalette           ;include the standard GUI palette
%define UseGuiCursor            ;use mouse and cursor
%define UseGuiFonts             ;include standard small fonts

%define UseWindowCode           ;include defs and code for window
;%define UseTitleBarCode
%define UseLabelCode
;%define UseTextPromptCode
;%define UseImageCode
;%define UseBorderCode
;%define UseScrollHandleCode
%define UseButtonCode
;%define UseAtrListCode
;%define UseMainBgCode

Screen:
.Height     equ 200
.Width      equ 320
.Adr        equ 0A0000h
.Bytes      equ .Height * .Width
section .bss
.Buffer:    resb Screen.Bytes
section .text

%include "guidefs.asm"          ;GUI messages and object definitions

;컴컴컴컴컴컴컴컴컴컴
;Variables

section .bss
alignb 4
Fire:
.Height     equ 200
.Width      equ 320
.ShadeRange equ 80
.ShadeSep   equ 40
.Buffer:    resb (.Height+8+3)*.Width
.RndValue:  resw 0BFFCh
.Timer:     resb 1

;컴컴컴컴컴컴컴컴컴컴
;GUI data

section .data
        MainWindow.Idx equ 0
        %define GuiObjContainer NullGuiItem
        DefGuiObj MainWindow,WindowCode,IgnoreMsg,GuiObj.RedrawBg, 0,0,Screen.Height,Screen.Width
MainWindow:
        DefWindow btnFast,0,0
        %define GuiObjContainer MainWindow
        %include "fireitem.asm"

    dd EndProg
btnQuit.Owner:

section .bss
ProcessList:
        DefProcessList 1

CurrentTime     equ 46Ch
FrameCounter    equ CurrentTime ;dd 0

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
section .text

_WdosxStart:

    push ds
    pop es

;컴컴컴컴컴컴컴컴컴컴
;Initialize graphics screen
    mov eax,13h                 ;Video BIOS: Set video mode to graphics
    int 10h

    ;create fire palette
    cld
    mov edi,Fire.Buffer
    mov ecx,768/4
    xor eax,eax
    rep stosd
    ;xor ecx,ecx

    mov edi,Fire.Buffer
    mov dl,3
PaletteGen:                     ; alternate palette generation
    xor eax,eax                 ; (Patrick Sundberg)
    push edi
    xor ebx,ebx                 ;zero accumulator
    ;ecx=0
    mov cl,Fire.ShadeRange-1
.L1:
    mov [edi],al
    add ebx,(4194304/Fire.ShadeRange)<<16
    adc eax,0
    add edi,byte 3
    loop .L1
    ;ecx=0
    mov cl,256-Fire.ShadeRange+1
.L2:
    mov [edi],al
    add edi,byte 3
    loop .L2
    pop edi
    add edi,Fire.ShadeSep*3+1
    dec dl
    jg PaletteGen

%if 0
    cld
    xor eax,eax
    mov edi,Screen.Ptr
.NextColor:
    stosb
    inc al
    jnz .NextColor
%endif

    mov esi,GuiPalette
    mov ecx,16                  ;count of colors
    call SetPalette.GivenCount
    mov eax,16                  ;index to start at
    mov ecx,240                 ;count of colors
    mov esi,Fire.Buffer+(16*3)
    call SetPalette.GivenIndexes

;컴컴컴컴컴컴컴컴컴컴
;Clear fire buffer
    cld
    mov edi,Fire.Buffer
    mov ecx,(320*203)/4
    xor eax,eax
    rep stosd

;컴컴컴컴컴컴컴컴컴컴
;Initialize mouse driver/cursor
    mov esi,GuiCursor.Default
    xor edx,edx                 ;top row (hot spot offset)
    mov ecx,15                  ;left column
    call SetCursorImage
    mov dword [Cursor.Row],Screen.Height/2
    mov dword [Cursor.Col],Screen.Width/2
    mov eax,21h                 ;mouse driver: reset
    int 33h
    cmp ax,0FFFFh
    jne .NoMouseDriver
    mov [Mouse.NumButtons],bl
    mov eax,13h                 ;mouse driver: set threshold speed
    mov edx,7FFDh
    int 33h
.NoMouseDriver:
    ;call GrabCursorImage

;컴컴컴컴컴컴컴컴컴컴
MainGuiLoop:
    push dword MainWindow       ;window data structure

;Initialize GUI items
    mov eax,Msg.Created
    call SendMsgAllItems
    call SetKeyFocus.AllItems
    ;add esp,byte 4

.Top:
.GetKey:
    call GetKeyboardMsg
    jc .NoKey                   ;return value is irrelevant if cf set
    cmp ah,27                   ;escape key?
    je near EndProg
    ;push dword MainWindow       ;window data structure
    call SendKeyMsg             ;send keypress to active window
    ;lea esp,[esp+4]
    jc .NoKey
    jmp short .GetKey
.NoKey:

.GetMouse:
    call GetMouseMsg            ;press/release/move
    jc .NoMouse
    push dword [Cursor.Col]
    push dword [Cursor.Row]
    push dword MainWindow       ;send mouse message to window cursor is over or window which grabbed focus
    call SendMouseMsg           ;click/move/enter/exit
    add esp,byte 12
.NoMouse:

;컴컴컴컴컴컴컴컴컴컴
;Render flame background and gui items

%if 0
    call AdvanceFlames

    mov esi,Fire.Buffer
    mov edi,Screen.Adr
    mov ecx,(Screen.Height*Screen.Width)/4
    rep movsd

    in al,60h
    cmp al,1
    jne .Top

%else

    mov al,[CurrentTime]
    test [btnFast+ButtonObj.Value],byte ButtonObj.Pressed
    jnz .Fast
    cmp [Fire.Timer],al
    je .SkipRedraw
.Fast:
    mov [Fire.Timer],al

    call AdvanceFlames
    call AdvanceFlames
    cld
    mov esi,Fire.Buffer
    mov edi,Screen.Buffer
    mov ecx,(Fire.Height*Fire.Width)/4
    rep movsd

    ;call HideCursorImage
    call SaveDisplay            ;save main window's display vars
    push dword MainWindow
    call SendRedrawMsgs         ;redraw all main items, cascading down to each contained item
    and dword [MainWindow+GuiObj.Flags],~GuiObj.Redraw
    pop ebx                     ;discard window ptr
    call RestoreDisplay         ;restore main window's display vars
    call GrabCursorImage
    call DrawCursorImage

    cld
    mov esi,Screen.Buffer
    mov edi,Screen.Adr
    mov ecx,(Screen.Height*Screen.Width)/4
    rep movsd
.SkipRedraw:

    jmp .Top
%endif

;컴컴컴컴컴컴컴컴컴컴
EndProg:
    mov ax,03h
    int 10h
    mov eax,4C00h
    int 21h

;컴컴컴컴컴컴컴컴컴컴
AdvanceFlames:

;--Flame animation, smoothing--
    xor edx,edx
    mov ecx,Fire.Width
    xor eax,eax
    mov ebx,101
    mov edi,Fire.Buffer
.L3:
    mov ax,[edi+639]
    add al,ah                         
    setc ah
    mov dl,[edi+641]
    add eax,edx
    mov dl,[edi+1280]
    add eax,edx
    shr eax,2
    jz .ZERO                    ; cool a bit...
    dec eax
  ;>>palette hack code
    cmp al,16
    jae .ZERO
    xor al,al
  ;<<end phc
.ZERO:
    stosb
    add eax,edx                 ; double the height
    shr eax,1                          
  ;>>palette hack code
    cmp al,16
    jae .ClrFine
    xor al,al
.ClrFine:
  ;<<end phc
    mov [edi+319],al                   
    loop .L3
    mov ecx,Fire.Width
    add edi,ecx                 ;skip a line
    dec ebx
    jg .L3


;--Flame generator bottom bar--
    mov ecx,320
    ; assumes edi=generator bar offset (bottom of flame buffer)
.L4:
    ;in ax,40h                  ; read from timer
    ;push ax
    ;add ax,[Fire.RndValue]
    ;pop word [Fire.RndValue]   ; "seed" is first two bytes of code
    ;mov ah,al
    mov ax,33797
    mul word [Fire.RndValue]
    inc ax
    mov [Fire.RndValue],ax
    and ah,03Fh
    add ah,100;0CFh
    mov al,ah
    stosw
    stosw
    loop .L4


;--Flame feedback--
; feeds fire back into itself for more turbulent flame variation
    mov ecx,320
    mov edi,Fire.Buffer+(320*(200+4))  ;plasma (likely my favorite)
.FfNext:
    ;mov al,[edi+(320*-161)]  ;top of flames feed back into bottom
    ;add al,[edi+(320*-101)]  ;top of flames feed back into bottom
    ;mov al,[edi+(320*-121)]  ;top of flames feed back into bottom
    mov al,[edi+(320*-150)]  ;top of flames feed back into bottom
    ;shl al,5                     ;select top three bits
    ;and al,111011b
    shl al,3                     ;select top bits
    ;xor al,1010110b
    add [edi],al
    inc edi
    loop .FfNext

    ret

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

    %include "guicode.asm"      ;core GUI functions
    %include "gfx.asm"          ;graphics routines, font, and palette
    %include "guiobjs.asm"      ;item code, buttons, prompts, menus
