; SPC700 64 byte ROM
;
; Compiles into SPCROM.DAT
;
    db 0CDh,0EFh          ;FFC0 MOV     X,#$EF
    db 0BDh               ;FFC2 MOV     SP,X
    db 0E8h,000h          ;FFC3 MOV     A,#$00        
    db 0C6h               ;FFC5 MOV     (X),A         
    db 01Dh               ;FFC6 DEC     X
    db 0D0h,0FCh          ;FFC7 BNE     $FFC5
    db 08Fh,0AAh,0F4h     ;FFC9 MOV     $F4,#$AA
    db 08Fh,0BBh,0F5h     ;FFCC MOV     $F5,#$BB
    db 078h,0CCh,0F4h     ;FFCF CMP     $F4,#$CC
    db 0D0h,0FBh          ;FFD2 BNE     $FFCF
    db 02Fh,019h          ;FFD4 BRA     $FFEF
    db 0EBh,0F4h          ;FFD6 MOV     Y,$F4
    db 0D0h,0FCh          ;FFD8 BNE     $FFD6 (wait until it is zero)
    db 07Eh,0F4h          ;FFDA CMP     Y,$F4
    db 0D0h,00Bh          ;FFDC BNE     $FFE9
    db 0E4h,0F5h          ;FFDE MOV     A,$F5
    db 0CBh,0F4h          ;FFE0 MOV     $F4,Y
    db 0D7h,000h          ;FFE2 MOV     [$00]+Y,A
    db 0FCh               ;FFE4 INC     Y
    db 0D0h,0F3h          ;FFE5 BNE     $FFDA
    db 0ABh,001h          ;FFE7 INC     $01
    db 010h,0EFh          ;FFE9 BPL     $FFDA
    db 07Eh,0F4h          ;FFEB CMP     Y,$F4         
    db 010h,0EBh          ;FFED BNE     $FFE9
    db 0BAh,0F6h          ;FFEF MOVW    YA,$F6        
    db 0DAh,000h          ;FFF1 MOVW    $00,YA        
    db 0BAh,0F4h          ;FFF3 MOVW    YA,$F4        
    db 0C4h,0F4h          ;FFF5 MOV     $F4,A
    db 0DDh               ;FFF7 MOV     A,Y           
    db 05Dh               ;FFF8 MOV     X,A           
    db 0D0h,0DBh          ;FFF9 BNE     $FFD6
    db 01Fh,000h,000h     ;FFFB JMP     [$0000+X]     
    db 0C0h               ;DI     (FFFE = reset vector)
    db 0FFh               ;STOP                  
