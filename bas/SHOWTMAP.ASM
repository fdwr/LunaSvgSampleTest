; Show Tile Map screen scrolling asm
; Peekin
; 2001-5-10
;
; ScrollScreen (RowDif, ColDif)
;
; Scrolls tiles already drawn on screen so that only newly revealed portions
; need to be redrawn.
;
; Positive values for RowDif scroll down, negative scroll up.
; Positive values for ColDif scroll right, negative scroll left.

    bits 16
    org 0

    %assign ScreenWidth  320
    %assign ScreenHeight 192
    %assign RowDif 12
    %assign ColDif 14

ScrollScreen:
    pushf                       ;Qbasic crashes when dir flag is changed!
    push ds                     ;It also crashes if the segment registers
    push es                     ;are not restored. So nice of the help text
    push bp                     ;to not tell about very important points
    mov bp,sp                   ;like these!

    mov ax,0A000h               ;screen segment
    mov ds,ax
    mov es,ax

    ; if RowDif > 0
    ;   scroll down
    ;   src=(ScreenHeight - 1 - RowDif) * ScreenWidth
    ;   dest=(ScreenHeight - 1) * ScreenWidth
    ; else
    ;   scroll up
    ;   src=-RowDif * ScreenWidth
    ;   dest=0
    ; endif
    mov ax,[bp+RowDif]
    mov bx,ScreenHeight
    mov si,ScreenWidth
    neg ax                      ;-RowDif
    mov dx,si                   ;screen row increment
    jg .ScrollUp
.ScrollDown:                    ;scroll down, but count up
    add bx,ax                   ;ScreenHeight + -RowDif
    jle .End                    ;no rows to scroll
    mov di,(ScreenHeight-1)*ScreenWidth
    add ax,ScreenHeight-1       ;ScreenHeight - 1 + -RowDif
    neg dx                      ;negate screen row increment
    jmp short .MulRowDif
.ScrollUp:                      ;scroll rows up, but count down
    sub bx,ax                   ;ScreenHeight - -RowDif
    jle .End                    ;no rows to scroll
    xor di,di                   ;destination=0
.MulRowDif:
    imul si,ax                  ;*ScreenWidth

    ; if ColDif > 0
    ;   scroll right
    ; else
    ;   scroll left
    ; endif
    mov cx,[bp+ColDif]
    mov ax,ScreenWidth
    test cx,cx
    jle .ScrollLeft
.ScrollRight:                   ;scroll right, but count left
    sub ax,cx                   ;ScreenWidth - ColDif
    jle .End
    add si,ax
    add di,ScreenWidth-2
    sub si,byte 2
    std                         ;copy backward
    jmp short .EndColDif
.ScrollLeft:                    ;scroll left, but count right
    add ax,cx                   ;ScreenWidth + ColDif
    jle .End
    sub si,cx
    cld                         ;copy forward
.EndColDif:

    shr ax,1                    ;\2 copy words

.NextRowLeft:
    push si
    push di
    mov cx,ax
    rep movsw
    pop di
    pop si
    add di,dx
    add si,dx
    dec bx
    jg .NextRowLeft

.End:
    pop bp
    pop es
    pop ds
    popf
    retf 2+2                    ;and last but not least, stack overflow
                                ;occurs without clearing 4 bytes of parameters
