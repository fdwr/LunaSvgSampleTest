;
;       op16
;
;	80x86 instructions
;
;       For disassembly in 16 bit mode
;
code2seg	segment
farroutine	proc	far
		mov	ax,4c00H
		int	21H	; if this file is executed, just terminate
farroutine	endp	
;
code2seg	ends
;
dataseg		segment
alpha		dw	0
nearindirect	dw	beta
farindirect	dd	farroutine
dataseg	ends
;
codeseg	segment
;
	assume ds:dataseg
	assume es:nothing
	assume ss:nothing
	assume cs:codeseg
;
;	ensure disassembler synchronization
;
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
;
;	examples of addressing modes
;
;                           mod   r/m
;                            00  VARIES
	db	10h,00000000b          ;  adc   [bx+si],al
	db	10h,00000001b          ;  adc   [bx+di],al
	db	10h,00000010b          ;  adc   ss:[bp+si],al
	db	10h,00000011b          ;  adc   ss:[bp+di],al
	db	10h,00000100b          ;  adc   [si],al
	db	10h,00000101b          ;  adc   [di],al
	db	10h,00000110b,11h,22h  ;  adc   [2211],al
	db	10h,00000111b          ;  adc   [bx],al
;
;                           mod   r/m
;                            00  VARIES
	db	10h,01000000b,11h   ;  adc   [bx+si+11],al
	db	10h,01000001b,11h   ;  adc   [bx+di+11],al
	db	10h,01000010b,11h   ;  adc   ss:[bp+si+11],al
	db	10h,01000011b,11h   ;  adc   ss:[bp+di+11],al
	db	10h,01000100b,11h   ;  adc   [si+11],al
	db	10h,01000101b,11h   ;  adc   [di+11],al
	db	10h,01000110b,11h   ;  adc   ss:[bp+11],al
	db	10h,01000111b,11h   ;  adc   [bx+11],al
;
;                           mod   r/m
;                            00  VARIES
	db	10h,10000000b,11h,22h   ;  adc   [bx+si+2211],al
	db	10h,10000001b,11h,22h   ;  adc   [bx+di+2211],al
	db	10h,10000010b,11h,22h   ;  adc   ss:[bp+si+2211],al
	db	10h,10000011b,11h,22h   ;  adc   ss:[bp+di+2211],al
	db	10h,10000100b,11h,22h   ;  adc   [si+2211],al
	db	10h,10000101b,11h,22h   ;  adc   [di+2211],al
	db	10h,10000110b,11h,22h   ;  adc   ss:[bp+2211],al
	db	10h,10000111b,11h,22h   ;  adc   [bx+2211],al
;
;	another 32 examples of addressing modes
;
	pop	[bx+si]
	pop	[bx+di]
	pop	ss:[bp+si]
	pop	ss:[bp+di]
	pop	[si]
	pop	[di]
	add     ax,[0006]   ; illustrate immediate addressing with add
                            ; instruction, since there's no immediate pop
	pop	[bx]
	pop	[08+bx+si]
	pop	[09+bx+di]
	pop	ss:[0aH+bp+si]
	pop	ss:[0bH+bp+di]
	pop	[0cH+si]
	pop	[0dH+di]
	pop	ss:[0eH+bp]
	pop	[0fH+bx]
	pop	[1010H+bx+si]
	pop	[1011H+bx+di]
	pop	ss:[1012H+bp+si]
	pop	ss:[1013H+bp+di]
	pop	[1014H+si]
	pop	[1015H+di]
	pop	ss:[1016H+bp]
	pop	[1017H+bx]
	pop	ax
	pop	cx
	pop	dx
	pop	bx
	pop	sp
	pop	bp
	pop	si
	pop	di
;
;	illustrate segment register usage
;
	pop	[bx]		; default is ds:
	pop	cs:[bx]
	pop	ss:[bx]
	pop	ds:[bx]
	pop	es:[bx]
	pop	[bp]		; default is ss:
	pop	cs:[bp]
	pop	ss:[bp]
	pop	ds:[bp]
	pop	es:[bp]
;
nearroutine	proc	near
nearroutine	endp
;
;	8088 instructions in alphabetical order
;	(as in Intel's "iAPX 88 Book")
;
	aaa
	aad
	aam
	aas
	adc	cx,[bx]
	adc	cx,alpha
	adc	cx,13
	adc	ax,13
	add	cx,[bx]
	and	cx,[bx]
	call	nearroutine
	call	farroutine
	call	nearindirect
	call	farindirect
	cbw
	clc
	cld
	cli
	cmc
	cmp	cx,[bx]
	cmpsb
	cmpsw
	cwd
	daa
	das
	dec	ax
	dec	al
	dec	byte ptr [bx]
	div	cx
;
;	esc			floating point operations
;
;                               (not valid for my assembler)
;
	db	0d9H,0faH	;	fsqrt
	db	0d9H,0fdH	;	fscale
	db	0d9H,0f8H	;	fprem
	db	0d9H,0fcH	;	frndint
	db	0d9H,0f4H	;	fxtract
	db	0d9H,0e1H	;	fabs
	db	0d9H,0e0H	;	fchs
	db	0d9H,0f2H	;	fptan
	db	0d9H,0f3H	;	fpatan
	db	0d9H,0f0H	;	f2xm1
	db	0d9H,0f1H	;	fyl2x
	db	0d9H,0f9H	;	fyl2xp1
	db	0dbH,0e3H	;	finit
	db	0dbH,0e0H	;	feni
	db	0dbH,0e1H	;	fdisi
	db	0d9H,028H	;	fldcw          [bx+si]
	db	0d9H,038H	;	fstcw          [bx+si]
	db	0ddH,038H	;	fstsw          [bx+si]
	db	0dbH,0e2H	;	fclex
	db	0d9H,030H	;	fstenv          [bx+si]
	db	0d9H,020H	;	fldenv          [bx+si]
	db	0ddH,030H	;	fsave          [bx+si]
	db	0ddH,020H	;	frstor          [bx+si]
	db	0d9H,0f7H	;	fincstp
	db	0d9H,0f6H	;	fdecstp
	db	0ddH,0c0H	;	ffree
	db	0d9H,0d0H	;	fnop
	db	09bH		;	fwait
	db	0d9H,000H	;	fld st(0),dword [bx+si]
	db	0dfH,028H	;	fld st(0),LONG INT [bx+si]
	db	0dbH,028H	;	fld st(0),temp real [bx+si]
	db	0d9H,0c0H	;	fld st(0),st(i)
	db	0d9H,010H	;	fst int,st(0) [bx+si]
	db	0ddH,0d0H	;	fst st(i),st(0) [bx+si]
	db	0d9H,018H	;	fstp st(0) int/real
	db	0dfH,038H	;	fstp st(0) long int
	db	0d8H,0d8H	;	fcomp st(i)
	db	0deH,0d9H	;	fcompp
	db	0d9H,0e4H	;	ftst
	db	0d9H,0e5H	;	fxam
	db	0d9H,0e8H	;	fld1
	db	0d9H,0eeH	;	fldz
	db	0d9H,0e4H	;	ftst
	db	0d9H,0eaH	;	fldl2e
	db	0d9H,0ebH	;	fldpi
	db	0d9H,0ecH	;	fldlg2
	db	0d9H,0edH	;	fldln2
;
	hlt
	idiv	dx
	imul	bx
	in	ax,67
	in	ax,dx
	inc	dl
	inc	dx
	int	3
	int	33
	into
	iret
	ja	$+33
	jnbe	$+33
	jae	$+34
	jnb	$+34
	jb	$+35
	jnae	$+35
	jbe	$+36
	jna	$+36
	jc	$+37
	jcxz	$+38
	je	$+39
	jz	$+39
	jg	$+40
	jnle	$+40
	jge	$+41
	jnl	$+41
	jl	$+42
	jnge	$+42
	jle	$+43
	jng	$+43
	jmp	nearroutine
	jmp	farroutine
	jnc	$+44
	jne	$+45
	jnz	$+45
	jno	$+46
	jns	$+47
	jnp	$+48
	jpo	$+48
	jo	$+49
	jp	$+50
	jpe	$+50
	js	$+51
	lahf
	lds	cx,[bx]
	lea	cx,[bx]
	les	cx,[bx]
	lock	add ax,1
	lodsw
	lodsb
	loop	$+33
	loope	$+34
	loopz	$+34
	loopnz	$+35
	loopne	$+35
	mov	ax,bx
	mov	byte ptr [bx],35
	mov	bx,34
	mov	ax,35
	mov	[bx+345],ax
	mov	alpha,ax
	mov	ax,[345]
	mov	ds,ax
	mov	[bx+346],ds
	movsb
	movsw
	mul	bx
	neg	byte ptr [bx]
	nop
	not	byte ptr [bx]
	or	[bx+34],cx
	or	byte ptr [bx+35],78
	or	ax,67
	out	88,ax
	out	dx,al
	pop	[bx+890]
	pop	ax
	pop	ds
	popf
	push	[bx+879]
	push	bx
	push	ds
	pushf
	rcl	byte ptr [bx],1
	rcr	byte ptr [bx],cl
	rep	stosb
	repe	stosb
	repne	stosb
beta	proc	near
	ret
	ret	3
beta	endp
delta	proc	far
	ret
	ret	3
delta	endp
	rol	dx,1
	rol	dx,cl
	ror	dx,1
	ror	byte ptr [bx+3],cl
	sahf
	sal	cx,1
	sal	dx,cl
	sar	dx,1
	sar	dx,cl
	sar	dx,1
	sar	dx,cl
	sbb	dx,cx
	sbb	dx,1
	sbb	al,3
	scasw
	scasb
	shr	ax,1
	shr	ax,cl
	stc
	std
	sti
	stosb
	sub	dx,cx
	sub	dx,3
	sub	ax,3
	test	dx,cx
	wait
	xchg	[bx+45],cx
	xchg	ax,cx
	xlat
	xor	cx,78
;
;	80186 & V20 instructions
;
	db	62h,0		;bound
	db	0c8h,33,44,5	;enter procedure
	db	69h,0,33,44	;imul immediate
	db	69h,0c0h,33,44	;imul immediate
	db	6bh,0,33	;imul immediate
	db	6bh,0c0h,33	;imul immediate
	db	6ch		;ins dx
	db	0f2h,6ch	;ins dx repeated by count in cx
	db	0c9h		;leave procedure
	db	6eh		;outs dx
	db	0f2h,6eh	;outs dx repeated by count in cx
	db	61h		;popa
	db	68h,33h,44h	;push immediate
	db	6ah,33h		;push immediate
	db	60h		;pusha
	db	0c0h,00h,3	;ROL memory by count
	db	0c0h,08h,3	;ROR memory by count
	db	0c0h,10h,3	;RCL memory by count
	db	0c0h,18h,3	;RCR memory by count
	db	0c0h,20h,3	;SHL/SAL memory by count
	db	0c0h,28h,3	;SHR memory by count
	db	0c0h,38h,3	;SAR memory by count
;
	db 90H,90H,90H,90H,90H,90H,90H,90H,90H		; alignment

;
;			80386 unique prefix bytes
;
	db	64h		;fs:
	mov	byte ptr [bx],11h
	db	65h		;gs:
	mov	byte ptr [bx],11h
;
	db	66h		;32 bit operand
	adc	cx,2211h
	dw	4433h
;
	db	66h		;32 bit operand
	adc	ax,2211h
	dw	4433h
;
	db	67h		;32 bit address
	mov	ax,alpha
	dw	4433h
;
	db	66h		;32 bit operand
	db	67h		;32 bit address
	mov	ax,alpha
	dw	4433h
	nop
	nop
	nop
	nop
	nop
	nop
	nop
;
;			80386 unique instructions
;
	db	0fh,22h,0c0h	;mov CR0,eax
	db	0fh,22h,0c8h	;           illegal
	db	0fh,22h,0d0h	;mov CR2,eax
	db	0fh,22h,0d8h	;mov CR3,eax
	db	0fh,22h,0e0h	;           illegal
	db	0fh,22h,0e8h	;           illegal
	db	0fh,22h,0f0h	;           illegal
	db	0fh,22h,0f8h	;           illegal

	db	0fh,20h,0c0h	;mov eax,CR0
	db	0fh,20h,0c8h	;           illegal
	db	0fh,20h,0d0h	;mov eax,CR2
	db	0fh,20h,0d8h	;mov eax,CR3
	db	0fh,20h,0e0h	;           illegal
	db	0fh,20h,0e8h	;           illegal
	db	0fh,20h,0f0h	;           illegal
	db	0fh,20h,0f8h	;           illegal

	db	0fh,23h,0c0h	;mov DR0,eax
	db	0fh,23h,0c8h	;mov DR1,eax
	db	0fh,23h,0d0h	;mov DR2,eax
	db	0fh,23h,0d8h	;mov DR3,eax
	db	0fh,23h,0e0h	;           illegal
	db	0fh,23h,0e8h	;           illegal
	db	0fh,23h,0f0h	;mov DR6,eax
	db	0fh,23h,0f8h	;mov DR7,eax

	db	0fh,21h,0c0h	;mov eax,DR0
	db	0fh,21h,0c8h	;mov eax,DR1
	db	0fh,21h,0d0h	;mov eax,DR2
	db	0fh,21h,0d8h	;mov eax,DR3
	db	0fh,21h,0e0h	;           illegal
	db	0fh,21h,0e8h	;           illegal
	db	0fh,21h,0f0h	;mov eax,DR6
	db	0fh,21h,0f8h	;mov eax,DR7

	db	0fh,26h,0c0h	;           illegal
	db	0fh,26h,0c8h	;           illegal
	db	0fh,26h,0d0h	;           illegal
	db	0fh,26h,0d8h	;           illegal
	db	0fh,26h,0e0h	;           illegal
	db	0fh,26h,0e8h	;           illegal
	db	0fh,26h,0f0h	;mov TR6,eax
	db	0fh,26h,0f8h	;mov TR7,eax

	db	0fh,24h,0c0h	;           illegal
	db	0fh,24h,0c8h	;           illegal
	db	0fh,24h,0d0h	;           illegal
	db	0fh,24h,0d8h	;           illegal
	db	0fh,24h,0e0h	;           illegal
	db	0fh,24h,0e8h	;           illegal
	db	0fh,24h,0f0h	;mov eax,TR6
	db	0fh,24h,0f8h	;mov eax,TR7

	db	0fh,24h,0f8h	;mov eax,TR7
	db	0fh,24h,0f9h	;mov ecx,TR7
	db	0fh,24h,0fah	;mov edx,TR7
	db	0fh,24h,0fbh	;mov ebx,TR7
	db	0fh,24h,0fch	;mov esp,TR7
	db	0fh,24h,0fdh	;mov ebp,TR7
	db	0fh,24h,0feh	;mov esi,TR7
	db	0fh,24h,0ffh	;mov edi,TR7
	seta	al
	setae	[bx]
	setb	ah
	setbe	[bx+si]
;
codeseg	ends
;

	end
