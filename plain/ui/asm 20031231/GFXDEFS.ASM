; Graphics Constants/Definitions
;
; Used by gfx.asm
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

%define GfxDefsInc

;%define CRGB15 8
%define CRGB15(r,g,b) ((r & 11111000b)<<7)|((g & 11111000b)<<2)|(b>>3)

; Font Characters (special symbols)
FntChrPlayB     equ 16
FntChrPlayF     equ 17
FntChrFastB     equ 18
FntChrFastF     equ 19
FntChrSlowB     equ 20
FntChrSlowF     equ 21
FntChrSkipB     equ 22
FntChrSkipF     equ 23
FntChrPause     equ 24
FntChrStop      equ 25
FntChrRecord    equ 26
FntChrNote      equ 27
FntChrUp        equ 28
FntChrDown      equ 29
FntChrLeft      equ 30
FntChrRight     equ 31

; GUI Colors
GuiClrBlack     equ 0
GuiClrSGray     equ CRGB15(82,68,100);1
GuiClrDGray     equ CRGB15(100,84,116);1
GuiClrGray      equ CRGB15(112,96,128);2
GuiClrLGray     equ CRGB15(172,158,180);3
GuiClrBGray     equ CRGB15(200,196,216);4
GuiClrWhite     equ CRGB15(255,255,255);5
GuiClrPurple    equ CRGB15(144,104,168);6
GuiClrLPurple   equ CRGB15(160,120,240);7
GuiClrBlue      equ CRGB15(80,80,160);8
GuiClrLBlue     equ CRGB15(80,80,240);9
GuiClrGreen     equ CRGB15(0, 160,0);10
GuiClrLGreen    equ CRGB15(0,240,0);11
GuiClrYellow    equ CRGB15(160,160,0);12
GuiClrLYellow   equ CRGB15(255,240,0);13
GuiClrRed       equ CRGB15(160,0,0);14
GuiClrLRed      equ CRGB15(255,0,0);15

GuiClrFace      equ GuiClrGray
GuiClrTop       equ GuiClrWhite
GuiClrBtm       equ GuiClrBlack
GuiClrLeft      equ GuiClrLGray
GuiClrRight     equ GuiClrDGray

GuiClrHighlight equ CRGB15(112+72,96+72,128+88)
GuiClrBright    equ CRGB15(112+48,96+48,128+56)
GuiClrLight     equ CRGB15(112+24,96+24,128+24)
GuiClrNeutral   equ GuiClrGray
GuiClrDim       equ CRGB15(112-24,96-24,128-24)
GuiClrDark      equ CRGB15(112-40,96-40,128-40)
GuiClrShadow    equ CRGB15(112-60,96-60,128-60)

; GUI Color Combos
GuiClrTxtNormal equ GuiClrBGray
GuiClrTxtActive equ GuiClrWhite
GuiClrTxtTyped  equ GuiClrLPurple
GuiClrTxtDim    equ GuiClrLGray
GuiClrTxtBright equ GuiClrWhite


%ifdef WinVer
%define UseDisplayBuffer        ;Windows ver always uses off screen buffer
%undef UseDefaultVgaScreen
%endif

; Screen constants
Screen:
%ifdef UseDefaultVgaScreen
.Height         equ 200
.Width          equ 320
.Adr            equ 0A0000h     ;physical address of screen
%endif
.Bytes          equ .Height * .Width*2
%ifdef UseDisplayBuffer
 section bss
 %ifdef DosVer
  alignb 4
  .Buffer:      resb .Bytes     ;preallocate display buffer
 %elifdef WinVer
  .Buffer       equ 0           ;will be allocated later
 %endif
 alignb 4
 .RedrawRange   resd Screen.Height*2 ;array of left/right edges to redraw
__SECT__
%else
 .Buffer        equ .Adr        ;no virtual screen, write directly to it
%endif


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; The Window's version assumes the main window has ALREADY been created, even
; if it isn't visible yet.
%macro InitGfx 0

 %ifdef WinVer
    ;more to come...
    ; initialize DirectX only if requested by user (otherwise GDI)

    api CreateDIBSection, [hdc],Display.BmpHeader,DIB_RGB_COLORS, Display.Ptr,NULL,NULL
    test eax,eax
    mov esi,%%PuiErrMsgDibCreate
    jz near GuiErrMsgEnd
    mov [Display.hdib],eax
    api CreateCompatibleDC, [hdc]
    test eax,eax
    ;mov esi,%%PuiErrMsgDccCreate
    jz near GuiErrMsgEnd
    mov [Display.hdcc],eax
    api SelectObject, eax,[Display.hdib]

   %ifdef UseGuiPalette
    mov esi,[Display.Palette]
    sub esi,byte 4              ;point two words before, sig and length
    api CreatePalette, esi
    mov [hpal],eax              ;store logical palette handle
    api SelectPalette, [hdc],eax,FALSE
    api RealizePalette, [hdc]
    ;call TransferScreen (do later)
   %endif

[section text]
%%PuiErrMsgDibCreate: db "Could not create display surface!? (CreateDIBSection)",0
__SECT__

 %elifdef DosVer
  ; Initialize graphics screen
  %ifdef UseDefaultVgaScreen
    ; This init routine is just a generic standard to use. One tailored
    ; to more advanced video modes (like initializing VESA) could take its
    ; place, but it MUST correctly set the Display variables (height, width,
    ; and memory ptr)
    ;call ClearScreen
    mov eax,13h                 ;Video BIOS: Set video mode to graphics
    int 10h

   %ifdef UseGuiPalette
    mov esi,[Display.Palette]
    call SetPalette
   %endif
  %endif

 %endif

 %ifdef UseDisplayBuffer
    call ClearRedrawArea        ;!!essential to prevent crashes
 %endif
%endmacro

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Doesn't do much.
%macro DeinitGfx 0
 %ifdef DosVer
  %ifdef UseDefaultVgaScreen
    mov eax,0F00h
    int 10h
    cmp al,3
    je .AlreadyTextMode
    mov eax,3                   ;Video BIOS: Set video mode to text
    int 10h
.AlreadyTextMode:
  %endif

 %elifdef WinVer
    ; Currently does nothing for Windows version, but here as stub
    ; just in case some day it needs to.
 %endif
%endmacro


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%ifdef UseGuiFonts
%macro IncDefFonts 0

%ifdef UseSmallScreen
align 4, db 0
GuiFontLetters equ $-(16*32)
    incbin "..\gui\fnt_smal.pxl"
FontDefHeight   equ 8
FontDefHbody    equ 6
FontDefHshift   equ 3
FontDefWidth    equ 7
FontDefAvgWidth equ 3
FontDefSep      equ 1
FontDefCharShl  equ 5           ;*32

GuiFontSizes   equ $-16
    ; 2002-01-21 Retire small font set (insufficient on highres displays)
    db 6,5,5,5,5,6,5,5,5,4,5,5,5,5,5,5  ;special characters
    db 3,1,3,5,3,4,4,2,2,2,3,3,2,3,1,3  ;punctuation
    db 3,3,3,3,3,3,3,3,3,3,1,2,3,3,3,3  ;0-9
    db 4,3,3,3,3,3,3,3,3,1,3,3,3,5,3,3  ;A-O
    db 3,3,3,3,3,3,3,5,3,3,3,2,3,2,3,3  ;P-Z
    db 2,3,3,3,3,3,3,3,3,1,2,3,1,5,3,3  ;a-o
    db 3,3,3,2,3,3,3,5,3,3,3,3,1,3,4,3  ;p-z

%else
align 4, db 0
GuiFontLetters equ $-(16*64)
    incbin "..\gui\fnt_larg.pxl"
FontDefHeight   equ 16
FontDefHbody    equ 12
FontDefHshift   equ 4
FontDefWidth    equ 14
FontDefAvgWidth equ 6
FontDefSep      equ 1
FontDefCharShl  equ 6           ;*64

GuiFontSizes:
    db  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ;control characters
    db 12,12,14,14,12,12,12,12,12,12,12, 8,12,12,12,12  ;special characters
    db  6, 2, 6,10, 6, 8, 8, 4, 4, 4, 6, 6, 4, 6, 2, 6  ;punctuation
    db  6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 2, 4, 6, 6, 6, 6  ;0-9
    db  8, 6, 6, 6, 6, 6, 6, 6, 6, 2, 6, 6, 6,10, 6, 6  ;A-O
    db  6, 6, 6, 6, 6, 6, 6,10, 6, 6, 6, 4, 6, 4, 6, 6  ;P-Z
    db  4, 6, 6, 6, 6, 6, 6, 6, 6, 2, 4, 6, 2,10, 6, 6  ;a-o
    db  6, 6, 6, 4, 6, 6, 6,10, 6, 6, 6, 6, 2, 6, 8, 6  ;p-z

    ; 2002-05-15 Added ANSI upper range characters
    db  6, 6, 4, 6, 8, 8, 6, 6, 6,10, 6, 6, 8, 6, 6, 6  ;128-143 *
    db  6, 4, 4, 8, 8, 6, 6, 8, 8, 8, 4, 6, 8, 6, 6, 6  ;144-159 *
    db  4, 2, 6, 6, 6, 6, 2, 6, 6,10, 6,10, 6, 6, 8, 6  ;160-175 *
    db  6, 6, 4, 4, 4, 6, 8, 6, 6, 4, 8,10, 8, 8, 8, 6  ;176-191 *
    db  6, 6, 6, 6, 6, 6, 8, 6, 6, 6, 6, 6, 2, 2, 2, 2  ;AEI
    db  8, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6  ;OYU
    db  6, 6, 6, 6, 6, 6, 8, 6, 6, 6, 6, 6, 2, 2, 2, 2  ;aei
    db  6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6  ;ouy

%endif
%endmacro
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%ifdef UseGuiPalette
%macro IncDefPalette 0
    %ifndef Screen.PalColors
        %assign Screen.PalColors 16
    %endif
    alignb 4,db 0
    %ifdef WinVer               ;palette header
    dw 300h                     ;Win3.11 signature
    dw Screen.PalColors         ;number of colors
    %endif
GuiPalette:
    ; scaled *4 for 16bit conversion 2003-05-03
    ;incbin "guicolor.pal"
    ;incbin "testpic.pal"

    db 0,0,0,0,         100,84,116,0,   120,104,136,0,  164,152,184,0,  200,180,220,0, 255,255,255,0
    db 144,104,168,0,   160,120,240,0,  80,80,160,0,    80,80,240,0, 0, 160,0,0,       0,240,0,0
    db 160,160,0,0,     255,240,0,0,    160,0,0,0,      255,0,0,0
    ; shifted up *4 and dword aligned 2002-07-16
    ;db 0,0,0,0,          25*4,21*4,29*4,0, 30*4,26*4,34*4,0, 41*4,38*4,46*4,0, 50*4,45*4,55*4,0, 255,255,255,0
    ;db 36*4,26*4,42*4,0, 40*4,30*4,60*4,0, 20*4,20*4,40*4,0, 20*4,20*4,60*4,0, 0,40*4,0,0,       0,60*4,0,0
    ;db 40*4,40*4,0,0,    255,60*4,0,0,     40*4,0,0,0,       255,0,0,0

    ;  slightly bluer shade 2001-11-03
    ;db 0,0,0,    25,21,29, 30,26,34, 41,38,46, 50,45,55, 63,63,63
    ;db 36,26,42, 40,30,60, 20,20,40, 20,20,60,  0,40,0,   0,60,0
    ;db 40,40,0,  63,60,0,  40,0,0,   63,0,0
    ;  palette as of 2001-07-07
    ;db 0,0,0,    24,20,26, 30,26,32, 41,38,44, 50,45,53, 63,63,63
    ;db 36,26,42, 40,30,60, 20,20,40, 20,20,60,  0,40,0,   0,60,0
    ;db 40,40,0,  63,60,0,  40,0,0,   63,0,0
    ;  original palette before 2001-04-02
    ;db 0,0,0,   24,22,26, 29,27,31, 39,37,41, 49,46,52, 63,63,63
    ;db 32,0,32, 0,0,32,   0,32,0,   32,30,0,  32,0,0
    ;db 63,0,63, 0,0,63,   0,63,0,   63,60,0,  63,0,0
%endmacro
%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
%ifdef UseGuiCursor
 %ifdef UseSmallScreen
    Cursor.Size     equ 16
    Cursor.SizeShl  equ 4

  %macro IncDefCursors 0
GuiCursor:
.Default:
.Pointer:
    incbin "..\gui\cursors.pxl",0,256
    dd 0,15                     ;hot spot row/col
.Caret:
    incbin "..\gui\cursors.pxl",256*1,256
    dd 5,0
.Move:
    incbin "..\gui\cursors.pxl",256*2,256
    dd 8,8
.Blank:
    incbin "..\gui\cursors.pxl",256*3,256
    dd 0,0
  %endmacro
 %else
    Cursor.Size     equ 32
    Cursor.SizeShl  equ 5

  %macro IncDefCursors 0
GuiCursor:
.Default:
.Pointer:
    incbin "..\gui\cursorsl.pxl",0,Cursor.SizeOf
    dd 0,30                    ;hot spot row/col
.Caret:
    incbin "..\gui\cursorsl.pxl",2048*1,2048
    dd 10,0
.Move:
    incbin "..\gui\cursorsl.pxl",2048*2,2048
    dd 16,16
.Blank:
    incbin "..\gui\cursorsl.pxl",2048*3,2048
    dd 0,0
  %endmacro
 %endif
%endif
