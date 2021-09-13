;
;       op32
;
;	'386 unique instructions
;
;       For disassembly in 32 bit mode
;
code2seg	segment
farroutine	proc	far
		mov	ax,4c00H
		int	21H	; if this file is executed, just terminate
farroutine	endp	
;
code2seg	ends
;
;
codeseg	segment
;
	assume ds:nothing
	assume es:nothing
	assume ss:nothing
	assume cs:codeseg
	db	90h,90h,90h,90h,90h,90h,90h,90h  ; ensure alignment
;
;	s-i-b byte instructions
;
	db	0,0ch,0c0h			; add  [eax+8*eax],cl               
	db	0,4ch,0c0h,33h			; add  [eax+8*eax+33],cl            
	db	0,8ch,0c0h,11h,22h,33h,44h	; add  [eax+8*eax+44332211],cl      
	db	0,8ch,80h,11h,22h,33h,44h	; add  [eax+4*eax+44332211],cl      
	db	0,8ch,40h,11h,22h,33h,44h	; add  [eax+2*eax+44332211],cl      
	db	0,8ch,44h,11h,22h,33h,44h	; add  ss:[esp+2*eax+44332211],cl   
	db	26h,0,8ch,44h,11h,22h,33h,44h	; add  es:[esp+2*eax+44332211],cl   
;
;  illustrating the 32 bit addressing modes
;
;
;                                               mod   reg   r/m
;                                                00   011  VARIES
	db	8bh,00011000b                   ; mov  ebx,[eax]
	db	8bh,00011001b                   ; mov  ebx,[ecx]
	db	8bh,00011010b                   ; mov  ebx,[edx]
	db	8bh,00011011b                   ; mov  ebx,[ebx]
	db	8bh,00011100b,0                 ; mov  ebx,[eax+eax]
	db	8bh,00011101b,11h,22h,33h,44h   ; mov  ebx,[d32]
	db	8bh,00011110b                   ; mov  ebx,[esi]
	db	8bh,00011111b                   ; mov  ebx,[edi]

;                                               mod   reg    r/m
;                                                01   011   VARIES
	db	8bh,01011000b,11h               ; mov  ebx,[eax+11]
	db	8bh,01011001b,11h               ; mov  ebx,[ecx+11]
	db	8bh,01011010b,11h               ; mov  ebx,[edx+11]
	db	8bh,01011011b,11h               ; mov  ebx,[ebx+11]
	db	8bh,01011100b,0,11h             ; mov  ebx,[eax+eax+11]
	db	8bh,01011101b,11h               ; mov  ebx,ss:[ebp+11]
	db	8bh,01011110b,11h               ; mov  ebx,[esi+11]
	db	8bh,01011111b,11h               ; mov  ebx,[edi+11]

;                                               mod   reg    r/m
;                                                10   011   VARIES
	db	8bh,10011000b,11h,22h,33h,44h   ; mov  ebx,[eax+44332211]
	db	8bh,10011001b,11h,22h,33h,44h   ; mov  ebx,[ecx+44332211]
	db	8bh,10011010b,11h,22h,33h,44h   ; mov  ebx,[edx+44332211]
	db	8bh,10011011b,11h,22h,33h,44h   ; mov  ebx,[ebx+44332211]
	db	8bh,10011100b,0,11h,22h,33h,44h ; mov  ebx,[eax+eax+44332211]
	db	8bh,10011101b,11h,22h,33h,44h   ; mov  ebx,ss:[ebp+44332211]
	db	8bh,10011110b,11h,22h,33h,44h   ; mov  ebx,[esi+44332211]
	db	8bh,10011111b,11h,22h,33h,44h   ; mov  ebx,[edi+44332211]

;                                               mod   reg    r/m
;                                                11   011   VARIES
	db	8bh,11011000b                   ; mov  ebx,[eax]
	db	8bh,11011001b                   ; mov  ebx,[ecx]
	db	8bh,11011010b                   ; mov  ebx,[edx]
	db	8bh,11011011b                   ; mov  ebx,[ebx]
	db	8bh,11011100b                   ; mov  ebx,[esp]
	db	8bh,11011101b                   ; mov  ebx,[ebp]
	db	8bh,11011110b                   ; mov  ebx,[esi]
	db	8bh,11011111b                   ; mov  ebx,[edi]

;  s-i-b byte
;
;                                            mod   reg     ss    index    base
;                                             00   011   VARIES   000     000
	db	8bh,00011100b,00000000b         ;  mov  ebx,[eax+1*eax]
	db	8bh,00011100b,01000000b         ;  mov  ebx,[eax+2*eax]
	db	8bh,00011100b,10000000b         ;  mov  ebx,[eax+4*eax]
	db	8bh,00011100b,11000000b         ;  mov  ebx,[eax+8*eax]

;                                            mod   reg    ss    index    base
;                                             00   011    11   VARIES     000
	db	8bh,00011100b,11000000b         ;  mov  ebx,[eax+8*eax]
	db	8bh,00011100b,11001000b         ;  mov  ebx,[eax+8*ecx]
	db	8bh,00011100b,11010000b         ;  mov  ebx,[eax+8*edx]
	db	8bh,00011100b,11011000b         ;  mov  ebx,[eax+8*ebx]
	db	8bh,00011100b,00100000b         ;  mov  ebx,[eax]
	db	8bh,00011100b,11101000b         ;  mov  ebx,[eax+8*ebp]
	db	8bh,00011100b,11110000b         ;  mov  ebx,[eax+8*esi]
	db	8bh,00011100b,11111000b         ;  mov  ebx,[eax+8*edi]

;                                            mod   reg    ss    index    base
;                                             00   011    11      111   VARIES
	db	8bh,00011100b,11111000b         ;  mov  ebx,[eax+8*edi]
	db	8bh,00011100b,11111001b         ;  mov  ebx,[ecx+8*edi]
	db	8bh,00011100b,11111010b         ;  mov  ebx,[edx+8*edi]
	db	8bh,00011100b,11111011b         ;  mov  ebx,[ebx+8*edi]
	db	8bh,00011100b,11111100b         ;  mov  ebx,[esp+8*edi]
	db	8bh,00011100b,11111101b,11h,22h,33h,44h  
	                                        ;  mov  ebx,[44332211+8*edi]
	db	8bh,00011100b,11111110b         ;  mov  ebx,[esi+8*edi]
	db	8bh,00011100b,11111111b         ;  mov  ebx,[edi+8*edi]

;                                            mod   reg     ss    index    base
;                                             01   011    11      111   VARIES
	db	8bh,01011100b,11111000b,11h     ;  mov  ebx,[eax+8*edi+11]
	db	8bh,01011100b,11111001b,11h     ;  mov  ebx,[ecx+8*edi+11]
	db	8bh,01011100b,11111010b,11h     ;  mov  ebx,[edx+8*edi+11]
	db	8bh,01011100b,11111011b,11h     ;  mov  ebx,[ebx+8*edi+11]
	db	8bh,01011100b,11111100b,11h     ;  mov  ebx,ss:[esp+8*edi+11]
	db	8bh,01011100b,11111101b,11h     ;  mov  ebx,[ebp+8*edi+11]
	db	8bh,01011100b,11111110b,11h     ;  mov  ebx,[esi+8*edi+11]
	db	8bh,01011100b,11111111b,11h     ;  mov  ebx,[edi+8*edi+11]

;                                            mod   reg     ss    index    base
;                                             10   011    11      111   VARIES
    db  8bh,10011100b,11111000b,11h,22h,33h,44h ;  mov  ebx,[eax+8*edi+d32]
    db  8bh,10011100b,11111001b,11h,22h,33h,44h ;  mov  ebx,[ecx+8*edi+d32]
    db  8bh,10011100b,11111010b,11h,22h,33h,44h ;  mov  ebx,[edx+8*edi+d32]
    db  8bh,10011100b,11111011b,11h,22h,33h,44h ;  mov  ebx,[ebx+8*edi+d32]
    db  8bh,10011100b,11111100b,11h,22h,33h,44h ;  mov  ebx,ss:[esp+8*edi+d32]
    db  8bh,10011100b,11111101b,11h,22h,33h,44h ;  mov  ebx,[ebp+8*edi+d32]
    db  8bh,10011100b,11111110b,11h,22h,33h,44h ;  mov  ebx,[esi+8*edi+d32]
    db  8bh,10011100b,11111111b,11h,22h,33h,44h ;  mov  ebx,[edi+8*edi+d32]

;
;			80386 peculiar prefix bytes
;
	db	64h		;fs:
	mov	byte ptr [bx],35
	db	65h		;gs:
	mov	byte ptr [bx],35
	db	66h		;16 bit operand
	adc	cx,1300
	db	66h		;16 bit operand
	adc	ax,1300
	db	67h		;16 bit address
	mov	ax,[2211]
	dw	90h,90h

;
codeseg	ends
;

	end
