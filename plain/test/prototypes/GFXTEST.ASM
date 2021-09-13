;Spc2Midi - Graphics test

bits 32                         ;flat addressing is great!
global _WdosxStart              ;great (free!) extender

section code

_WDOSXStart:
    push ds
    pop es

    mov eax,13h                 ;Video BIOS: Set video mode to graphics
    int 10h
    mov esi,GuiPalette
    xor eax,eax
    mov ecx,16
    call SetPalette.GivenIndexes
    call ClearScreen

%if 1
.NextString:
    call ClearScreen
    push word 5             ;color
    push dword 2|(200<<16)  ;height/width
    push dword 156|(20<<16) ;row/col
    call DrawBox
    add esp,byte 10
    push dword TestString3-TestString2;total number of characters
    push dword TestString2
    ;push dword [.TextPos]
    push dword 150|(-2<<16)     ;start at row/column
    call BlitString
    add esp,byte 12
    dec dword [Display.LeftClip]
    ;dec dword [Display.RightClip]
    ;add dword [.TextPos],1<<16
    xor eax,eax
    int 16h
    cmp al,27
    jne .NextString
    jmp .End

;.TextPos:   dd 150|(20<<16)     ;start at row/column
%endif

    push dword 5                ;color
    push dword 20|(30<<16)
    push dword 80|(275<<16)
.NextBox:
    call DrawBox
  .NoSize:
    add dword [esp],00050010h
    dec dword [esp+8]
    jns .NextBox
    ;add esp,byte 12

    push dword 112              ;total number of characters
    push dword 16
    push dword TestString
    push dword 10|(10<<16)      ;start at row 10, column 10
.NextCharRow:
    call BlitString
    add dword [esp],byte 9      ;next row down
    sub dword [esp+12],byte 16  ;one row less of characters
    ja .NextCharRow
    ;add esp,byte 16

    push word 1             ;color
    push dword 20|(200<<16) ;height/width
    push dword 90|(10<<16)  ;row/col
    call DrawBox
    ;add esp,byte 10

    mov [Font.Colors],word 0203h;white/gray
    push dword TestString2_Len
    push dword TestString2
    push dword 98|(20<<16)     ;start at row 100, column 20
    call BlitString
    ;add esp,byte 12

    push word 0                 ;color
    push dword 30|(200<<16)     ;height/width
    push dword 120|(10<<16)     ;row/col
    call DrawBox
    ;add esp,byte 10
    push word 1                 ;color
    push dword 30|(200<<16)     ;height/width
    push dword 150|(10<<16)     ;row/col
    call DrawBox
    ;add esp,byte 10

    mov [Font.Colors],word 060Bh;start with purple
    push dword TestString3_Len
    push dword TestString3
    push dword 128|(20<<16)     ;start at row 100, column 20
.NextTextRow:
    call BlitString
    add dword [esp],byte 9      ;next row down
    add [Font.Colors],word 0101h;next color
    cmp [esi],byte 0            ;check if last string
    jne .NextTextRow
    ;add esp,byte 12

    push word 7                 ;color
    push dword 70|(60<<16)      ;height/width
    push dword 15|(155<<16)     ;row/col
    call DrawBox
    ;add esp,byte 10
    push dword 5                ;color
    push dword 10|(50<<16)      ;height/width
    push dword 20|(160<<16)     ;row/col
.NextShade:
    call DrawBox
    add dword [esp],byte 10
    dec dword [esp+8]
    jns .NextShade
    ;add esp,byte 12

    add esp,byte 12+16+10+12+10+10+12+10+12

    xor eax,eax                 ;BIOS: Wait for keypress
    int 16h
.End:
    mov eax,3h                  ;Video BIOS: Set video mode to text
    int 10h
    mov eax,4C00h               ;DOS: Terminate program
    int 21h


;------------------------------------------------------------

    %include "gfx.asm"
    ;include graphics routines, font, and palette

;------------------------------------------------------------
section data

TestString:
%assign Chr 16
%rep 112
    db Chr
    %assign Chr Chr+1
    ;%if (Chr & 15) = 0
    ;    db 0
    ;%endif
%endrep
    db 0

TestString2:
    db "Just testing my font blitter.. it seems to work :)"
TestString2_Len equ $-TestString2

TestString3:
    db FntChrSlowF, " Slow  "
    db FntChrPlayF, " Play  "
    db FntChrStop,  " Stop  "
    db FntChrRecord," Record"
    db FntChrPause, " Pause "
    db 0
TestString3_Len equ 8
