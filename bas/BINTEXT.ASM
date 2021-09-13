;Bintext.Asm for Qbasic bin_text.bas, (4-10-98),(5-15-98), by FDwR
;Routines to convert 8bit binary data into either 6bit or 7bit ASCII text for
;email transfer, or to decode such text back into its original binary data.
;free for copying and personal use, the only cost is keeping my name :-)

;They all use 32bit registers to reduce slow memory accesses in unrolled loops
;for extra speed. However, the memory mode is real, not flat addressing (can
;anybody tell me why Windows reports a GPF whenever I try to read even single
;byte using esi, or any other 32bit register for that matter ?). Conversion
;is accomplished by simple bitshifts, whether encoding or decoding. I haven't
;read any books or looked for info on the net on how to do this, so if anybody
;sees a way the asm main loop can be sped up or improved, please tell me.
;There might be something better, but I put a lot of thought into this one.:-)

;There are four expanded routines. Two are for encoding binary into 6bit text
;and decoding 6bit text to binary. The other two are for 7bit conversion. 6bit
;encoding will output eight bytes for every six it reads, and 7bit encoding
;will output eight bytes for seven it reads. The four separate routines could
;be reduced to two universal routines, but the speed increase is worth wasting
;a little space for the specialised copies.

;From some time tests on my old 386 with a mere 25MHz, I've found that any
;one of these routines could theoretically convert about 1114112 bytes per
;second! That is the same as seventeen pages of 64k each, even while running
;under Windows, quite fast enough for me ;-). Imagine what it might be on a
;newer computer (I never thought my old machine had that much potential). Of
;course, the bad news is that the time tests were done at maximum speed, just
;pure translation without any overhead (except being under Windows) like being
;called from a high level language; but I'm just supposed to be telling you
;the speed of the routines themselves anyway, not the speed of programs that
;might use of them.

;This particular bit of asm was written to be compiled with the cool, free
;Netwide Assembler (Nasm) as an indepedent code fragment (I don't know how to
;mess with all that library stuff yet). You may need to do some rewriting
;first for your own compiler.

;These parameters and registers apply to all the routines
;  Accepts the parameters: conversion%, source:offset, destination:offset, length%
;    conversion tells what to do, encode or decode, 6bit or 7bit  (short int)
;      bit 0 (0-encode,1-decode), bit 1 (0-6bit,1-7bit)
;    source is where to get the raw data                          (far ptr)
;    destination is where to put the manipulated data             (far ptr)
;    length tells how many bytes long the binary data is          (short int)
;      It is always the length of the text, not the binary data;
;      You can change this though below to the length of the data.
;      The reason why it is based on the text length is because the text is
;      always larger than the source data, while the encoding could be either
;      6 bits or 7 bits, the output is always 8bits. It also makes figuring
;      the length divided by the number of unrolled loops a little easier by
;      using simple shifts. Arrays must be in even multiples of eight though.
;  Uses the registers: ds:si, es:di, eax, cx
;    si holds the offset from ds to find the binary data or text
;    di holds the offset from es to put the text or binary data
;    eax is the all purpose register for manipulating data
;    cx is simply a counter register set to length, which can be 0-65535

;The routines might be a little confusing in their unrolled form, but it
;really speeds things up this way by loading things in from memory in short
;reads rather than byte by byte, and eliminating a lot of slow-me-down jumps.
;To help you understand them a little better, I included a sort of visual
;reference of how each instruction affects the contents of the eax register.
;All 32 bits are shown, with each of the four bytes separated. Actually, I had
;to include it just so I could understand it and debug the thing! ;-)

;  symbol key for the bits:
;    1,2,3..   this bit is part of the byte numbered
;    w         that bit has been written to the destination
;    x         simply garbage bits overread from a MOV
;    ù         bit is set by an OR

        bits 16         ;change it if you use this from a 32bit program
        org 0h          ;upon entry, cs must be zero based (far call)

        push ds
        push es
        push bp
        mov bp,sp
       
        mov bx,[bp+10]  ;get the routine to call (one of four possible)
        cmp bx,4        ;check for an invalid parameter, don't want to crash!
        jae SkipToEnd   ;if a non-existant conversion routine is requested of
                        ;it, then simply return, otherwise get other values
        lds si,[bp+12]  ;source data, text or binary
        les di,[bp+16]  ;destination, text or binary
        mov cx,[bp+20]  ;put length into counter
        shl bx,1        ;make 16bit a pointer by multiplying bx by 2
        mov bx,[cs:bx+ConversionJumpTable];get pointer to desired routine
        shr cx,3        ;divide length by the number of unrolled loops
        test cx,cx      ;make sure that there is something to convert
        jz SkipToEnd    ;end if there is no data (zero length)
        cld
        call bx
        SkipToEnd:
        pop bp
        pop es
        pop ds
        retf 12         ;far return, reducing stack by 12 bytes
        ;conversion(2) + source(4) + destination(4) + sourcelength(2) = 12

    ConversionJumpTable:;four types of conversion
        dw Encode6bit,Decode6bit,Encode7bit,Decode7bit

Encode6bit:
;If you want 'length' to specify the length of the binary rather than the
;text, just add this code. It could be written a little better.
;       mov ax,cx
;       xor dx,dx
;       mov cx,6
;       div cx
;       cmp ax,ax
;       jz .SkipToEnd
;       mov cx,ax
        mov dx,64+16384         ;The OR mask, used to turn values into ASCII text
                                ;(64-127) by setting the seventh bit of each byte.
    .TopOfLoop:
        lodsd           ;11111111|22222222|33333333|44444444| (eax...)
        mov ebx,eax     ;11111111|22222222|33333333|44444444|
        shl eax,4       ;    1111|11112222|22223333|33334444|
        shr ax,2        ;  111111|112222  |22223333|33334444|
        shr al,2        ;111111  |112222  |22223333|33334444|
        or ax,dx        ;111111ù |112222ù |22223333|33334444| turn into characters 64-127 by setting the seventh bit of each byte
        stosw           ;wwwwwwww|wwwwwwww|22223333|33334444|
        shr eax,12      ;    2222|33333333|4444    |        |
        shr ax,2        ;  222233|333333  |4444    |        |
        shr al,2        ;222233  |333333  |4444    |        |
        or ax,dx        ;222233ù |333333ù |4444    |        |
        stosw           ;wwwwwwww|wwwwwwww|4444    |        |
        lodsw           ;55555555|66666666|4444    |        |
        shld eax,ebx,12 ;33334444|44445555|55556666|66664444| retrieve copy from bx, rather than rereading from memory
        shr ax,2        ;33444444|445555  |55556666|66664444|
        shr al,2        ;444444  |445555  |55556666|66664444|
        or ax,dx        ;444444ù |445555ù |55556666|66664444|
        stosw           ;wwwwwwww|wwwwwwww|55556666|66664444|
        shr eax,12      ;    5555|66666666|4444    |        | get rid the excess bits from source byte 4
        shr ax,2        ;  555566|666666  |****    |        |
        shr al,2        ;555566  |666666  |        |        |
        or ax,dx        ;555566ù |666666ù |        |        |
        stosw           ;wwwwwwww|wwwwwwww|        |        |

        dec cx
        jnz .TopOfLoop

    .SkipToEnd
        ret

Decode6bit:
;If you want 'length' to specify the length of the binary data rather than
;the binary text, just add the code above.

    .TopOfLoop:       
        lodsd           ;111111  |112222  |222233  |333333  | (eax...)
        shl al,2        ;  111111|112222  |222233  |333333  |
        shl ax,2        ;    1111|11112222|222233  |333333  |
        shr eax,4       ;11111111|22222222|33  3333|33      |
        stosw           ;wwwwwwww|wwwwwwww|33  3333|33      |
        shr eax,12      ;    33  |333333  |        |        |
        shl al,2        ;      33|333333  |        |        |
        shl eax,18      ;        |        |        |33333333|
        lodsw           ;444444  |445555  |        |33333333|
        shl al,2        ;  444444|445555  |        |33333333|
        shr ax,2        ;44444444|5555    |        |33333333|
        rol eax,8       ;33333333|44444444|5555    |        |
        stosw           ;wwwwwwww|wwwwwwww|5555    |        |
        shl eax,12      ;        |        |        |    5555|
        lodsw           ;555566  |666666  |        |    5555|
        shl al,2        ;  555566|666666  |        |    5555|
        shr ax,2        ;55556666|6666    |        |    5555|
        rol eax,4       ;55555555|66666666|        |        |
        stosw           ;wwwwwwww|wwwwwwww|        |        |

        dec cx
        jnz .TopOfLoop

    .SkipToEnd
        ret

Encode7bit:
;If you want 'length' to specify the length of the binary rather than the
;text, just add this code. It could be written a little better.
;       mov ax,cx
;       xor dx,dx
;       mov cx,7
;       div cx
;       cmp ax,ax
;       jz .SkipToEnd
;       mov cx,ax
        mov dx,128+32768        ;The OR mask, used to turn ASCII text into
                                ;extended characters (128-255) by setting the
                                ;eighth bit of each byte.
                                ;This one does not expand the text quite as
                                ;6bit does, but unfortunately, many email
                                ;programs do not support extended characters.
                                ;Maybe that is why I have never seen this
                                ;mode in any attachments.
    .TopOfLoop:       
        lodsd           ;11111111|22222222|33333333|44444444| (eax...)
        mov ebx,eax     ;11111111|22222222|33333333|44444444|
        shl eax,2       ;  111111|11222222|22333333|33444444|
        shr ax,1        ; 1111111|1222222 |22333333|33444444|
        shr al,1        ;1111111 |1222222 |22333333|33444444|
        or ax,dx        ;1111111ù|1222222ù|22333333|33444444| turn into extended characters by ORing
        stosw           ;wwwwwwww|wwwwwwww|22333333|33444444|
        shr eax,14      ;  223333|33334444|44      |        |
        shr ax,1        ; 2233333|3334444 |44      |        |
        shr al,1        ;2233333 |3334444 |44      |        |
        or ax,dx        ;2233333ù|3334444ù|44      |        |
        stosw           ;wwwwwwww|wwwwwwww|44      |        |
        lodsd           ;55555555|66666666|77777777|xxxxxxxx| (<-garbage byte)
        dec si
        shld eax,ebx,6  ;44444455|55555566|66666677|777777  | retrieve copy from bx, rather than rereading from memory
        shr ax,1        ;44444555|5555566 |66666677|777777  |
        shr al,1        ;4444555 |5555566 |66666677|777777  |
        or ax,dx        ;4444555ù|5555566ù|66666677|777777  |
        stosw           ;wwwwwwww|wwwwwwww|66666677|777777  |
        shr eax,15      ; 6666667|7777777 |        |        |
        shr al,1        ;6666667 |7777777 |        |        |
        or ax,dx        ;6666667ù|7777777ù|        |        |
        stosw           ;wwwwwwww|wwwwwwww|        |        |

        dec cx
        jnz .TopOfLoop

    .SkipToEnd
        ret

Decode7bit:
;If you want 'length' to specify the length of the binary data rather than
;the binary text, just add the code above.

;This one single blanked out instruction was reserved in case I wanted to use
;the finishing loop at the bottom, for uneven multiples of eight.
;       mov dx,cx

    .TopOfLoop:       
        lodsd           ;1111111 |1222222 |2233333 |3334444 | (eax...)
        shl al,1        ; 1111111|1222222 |2233333 |3334444 |
        shl ax,1        ;  111111|11222222|2233333 |3334444 |
        shr eax,2       ;11111111|22222222|33333 33|34444   |
        stosw           ;wwwwwwww|wwwwwwww|33333 33|34444   |
        shr eax,14      ;  33333 |3334444 |        |        |
        shl al,1        ;   33333|3334444 |        |        |
        shl eax,17      ;        |        |    3333|33334444|
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
        jnz .TopOfLoop

    .SkipToEnd
        ret

;This is code I was working on to finish uneven lengths, but rather than have
;a separate version of this for each routine, I just decided to make it
;necessary for the caller to only pass even multiples of eight for the length.
;If it is not a even multiple, this asm 'rounds' down for safety, so it does
;not write past the end of an array and mess up some other variables. To round
;it up, just have the caller do it first. If you want to use this finishing
;loop (it does actually work) or just want to know how to do it, it is at
;least in here for you. This one is only for decoding 7bit text, but can
;easily be modified for 6bit.

;SkipUnrolledDecoder:
;        and dx,07h
;        jz .SkipToEnd
;        mov cl,1
;        lodsw
;        jmp BreakIntoDecoderLoop
;TopOfDecoderLoop:
;        lodsb
;        xchg al,ah
;        inc cl
;BreakIntoDecoderLoop:
;        shl al,cl
;        shr ax,cl
;        stosb
;        dec dx
;        jnz TopOfDecoderLoop
;    .SkipToEnd

;These routines took some thought to write (since I had never done anything
;like it before) so if you find them useful for any of your own programs,
;please keep my name in the asm and send me a letter telling me what you
;think of it, questions, or suggestions ;-)

;FDwR@Juno.Com
;FrankDwayne, 17

