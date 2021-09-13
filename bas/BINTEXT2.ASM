;bintext2.asm to Qbasic bin_text.bas, 4-98
;used to convert 8bit binary data into 7bit ASCII for email transfer
;see bintext1.asm for converting text back into binary data
;uses 32bit registers in unrolled loop for extra speed, so don't expect this
;to work on a 286

;accepts the parameters:
;  source&, destination&, length%
;    source is where to find the binary data
;    destination is where to output the text
;    length is how many bytes long the source is
;uses the registers
;  ds:si, es:di, eax, cx
;    si holds the offset from ds to find the binary data
;    di holds the offset from es to put the text
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
        ;remove this later!
        mov ax,0b800h
        mov es,ax
        xor di,di
        ;remove that later!
        mov ax,[bp+18]
        xor dx,dx
        mov cx,7
        div cx
        mov cx,ax
        ;not all completed yet
        test cx,cx
        jz SkipToEnd ;if zero then skip code below

TopOfUnrolledDecoder:        
        ;This would all look a little less intimidating to understand if it
        ;was written in a loop with smaller units, but it would also be many
        ;times slower. This way it saves time by loading things in from memory
        ;in quick 32bit bursts rather than byte by byte, and eliminating a lot
        ;of time-consuming jumps. I included a sort of visual reference of
        ;what the reigisters look like at each step to see how each
        ;instruction affects it, to help you understand it. Actually I had to
        ;include it just so I could understand and debug it!
        lodsd           ;11111111|22222222|33333333|44444444| (eax)
        mov ebx,eax     ;11111111|22222222|33333333|44444444| (ebx is a copy)
        shl eax,2       ;  111111|11222222|22333333|33444444| (eax again...)
        shr ax,1        ; 1111111|1222222 |22333333|33444444|
        shr al,1        ;1111111 |1222222 |22333333|33444444|
        or ax,128+32768 ;1111111û|1222222û|22333333|33444444| turn into extended characters by setting the high bits of each byte
        stosw           ;wwwwwwww|wwwwwwww|22333333|33444444|
        shr eax,14      ;  223333|33334444|44      |        |
        shr ax,1        ; 2233333|3334444 |44      |        |
        shr al,1        ;2233333 |3334444 |44      |        |
        or ax,128+32768 ;2233333û|3334444û|44      |        |
        stosw           ;wwwwwwww|wwwwwwww|44      |        |
        lodsd           ;55555555|66666666|77777777|x!@$%*?=| (<-garbage byte)
        dec si
        shr ebx,22      ;444444  |        |        |        | (ebx)
        shld eax,ebx,6  ;44444455|55555566|66666677|777777  | (eax again...)
        shr ax,1        ;44444555|5555566 |66666677|777777  |
        shr al,1        ;4444555 |5555566 |66666677|777777  |
        or ax,128+32768 ;4444555û|5555566û|66666677|777777  |
        stosw           ;wwwwwwww|wwwwwwww|66666677|777777  |
        shr eax,14      ;  666666|77777777|        |        |
        shr ax,1        ; 6666667|7777777 |        |        |
        shr al,1        ;6666667 |7777777 |        |        |
        or ax,128+32768 ;6666667û|7777777û|        |        |
        stosw           ;wwwwwwww|wwwwwwww|        |        |

        dec cx
        jnz TopOfUnrolledDecoder

SkipToEnd:
        pop bp
        pop es
        pop ds
        retf 10 ;source(4) + destination(4) + length(2)
