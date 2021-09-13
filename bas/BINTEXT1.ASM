;bintext1.asm to Qbasic bin_text.bas, 4-98
;used to convert 7bit ASCII text back into 8bit binary data
;see bintext2.asm for converting binary data into text
;uses 32bit registers in unrolled loop for extra speed

;accepts the parameters:
;  source&, destination&, length%
;    source is where to find the text
;    destination is where to output the binary data
;    length is how many bytes long the source is
;uses the registers
;  ds:si, es:di, eax, cx
;    si holds the offset from ds to find the text
;    di holds the offset from es to put the binary data
;    eax is the all purpose register for holding values read in, shifting
;     then around, and keeping them for output
;    cx is simply a counter register set to length, which can be 1-65536

        bits 16
        org 0

        push ds
        push es
        push bp
        mov bp,sp
        
        lds si,[bp+10]
        les di,[bp+14]
        mov cx,[bp+18]
        ;remove this later!
        mov ax,0b800h
        mov es,ax
        xor di,di
        ;remove that later!

        ;not all completed yet
        mov dx,cx
        shr cx,3
        jz SkipUnrolledDecoder ;if zero then skip code below

TopOfUnrolledDecoder:        
        lodsd           ;1111111 |1222222 |2233333 |3334444 | (eax...)
        shl al,1        ; 1111111|1222222 |2233333 |3334444 |
        shl ax,1        ;  111111|11222222|2233333 |3334444 |
        shr eax,2       ;11111111|22222222|33333 33|34444   |
        stosw           ;wwwwwwww|wwwwwwww|33333 33|34444   |
        ror eax,14      ;  33333 |3334444 |        |        |
        shl al,1        ;   33333|3334444 |        |        |
        rol eax,17      ;        |        |    3333|33334444|
        lodsw           ;4444555 |5555566 |    3333|33334444|
        shl al,1        ; 4444555|5555566 |    3333|33334444|
        shr ax,1        ;44445555|555566  |    3333|33334444|
        rol eax,12      ;33333333|44444444|55555555|66      |
        stosw           ;wwwwwwww|wwwwwwww|55555555|66      |
        shl eax,6       ;        |        |      55|55555566|
        lodsw           ;6666667 |7777777 |      55|55555566|
        shl al,1        ; 6666667|7777777 |      55|55555566|
        shr ax,1        ;66666677|777777  |      55|55555566|
        rol eax,10      ;55555555|66666666|77777777|        |
        stosw           ;wwwwwwww|wwwwwwww|77777777|        |
        shr eax,16      ;77777777|        |        |        |
        stosb           ;wwwwwwww|        |        |        |
        
        dec cx
        jnz TopOfUnrolledDecoder

SkipUnrolledDecoder:
        and dx,07h
        jz SkipToEnd
        mov cl,1
        lodsw
        jmp BreakIntoDecoderLoop
TopOfDecoderLoop:
        lodsb
        xchg al,ah
        inc cl
BreakIntoDecoderLoop:
        shl al,cl
        shr ax,cl
        stosb
        dec dx
        jnz TopOfDecoderLoop

SkipToEnd:
        pop bp
        pop es
        pop ds
        retf 10 ;source(4) + destination(4) + length(2)
