;Tile Translating routines, 5-8-98, FDR

;!! not completely finished yet, do not compile and execute without care !!

;Used to convert game console sprite formats into more useable linear bitmaps
;It can blit the result to a bitmap in memory or directly to the screen.
;The code uses 32bit registers but 16bit memory addressing; for some stupid
;reason, whenever I try to read any bit of information using flat addressing
;the computer locks up or reports a GPF error. Even when doing nothing but
;harmlessly reading, it states my program has done an illegal operation \:-(
;It acts like my program is Chernobyl, ready to blow up the whole computer.
;Maybe I want it to do that illegal operation! Despite that, is it is super
;fast. It took me quite a while to perfect to where it is at, balancing all
;the registers for optimum performance and removing all unecessary memory
;references that would slow it down, so if anybody out there decides to use
;it in their viewer would be fair to include my name in it :-)

;supports SNES, GameBoy
;plan to eventually support NES, Sega
;SNES (all tiles are 8x8, associated palettes)
;  1bit,1bpl,2clr   linear
;  2bit,2bpl,4clr   interleaved, palette
;  3bit,3bpl,8clr
;  4bit,4bpl,16clr  sprite format
;  8bit,8bpl,256clr
;  8bit,1bpl,256clr mode 7
;GameBoy (all tiles are 8x8, grayscale)
;  2bit,2bpl,4clr   interleaved

	bits 16	;how do you define a silly segment to be 32bit code?
;	org 0
	org 100h

;---temporary
	mov ax,13h
	int 10h
	
	push word 320
	push word 2
	push ds
	push word Test_tile_table
	push word 0A000h
	push word 0
	push ds
	push word Test_tile
	push word 13	;this is a dummy value, just used to make the stack even 
	call SNES_Gameboy_bitplane_separated

	mov ax,4C00h
	int 21h

Section .text

SNES_Gameboy_bitplane_separated:
;this routine works for both SNES and Gameboy graphics
;parameters passed:
;  dword  source       segment:offset
;  dword  destination  segment:offset
;  dword  jump table   segment:offset
;  word   bitplanes
;  word   linear bitmap width
;registers used:
;  bx1=jump table index
;  cl1=bitplanes
;  ch1=height counter
;  cl2=plane counter
;  ch2=bitplane row data		(<---input)
;  eax=left row (pixel columns 0-3)	(output-->)
;  edx=right row (pixel columns 4-7)	(output-->)
;  si=raw source data
;  di=linear bitmap destination
;  bp=bitmap width (or screen width, if mode 13h)
;  ds=source segment
;  es=destination segment
;  fs=jump table segment
;notation
;  ah1 - low ah in eax, bits 8-15
;  bl2 - high bl in ebx, bits 16-23, requires a 16 bit roll to access
;  ax2 - high ax in eax, bits 16-31, requires a 16 bit roll to access
;summary
;   Basically, it uses a table to tell how the planes are parsed up, then
; loops the number of bitplanes, ORing each bitplane onto the pixel row and
; rolling them until the full pixel depth for eight pixels is achieved.

	push ds
	push es
	push bp
	mov bp,sp

	mov si,[bp+10]	;initialize all variables with the right values
	mov ds,[bp+12]
	mov di,[bp+14]
	mov es,[bp+16]
;	mov ax,0A000h	;set to screen for now to be safe (:-)
;	mov es,ax
;	xor di,di
	mov bx,[bp+18]	;load table base into bx
	mov fs,[bp+20]
	mov cl,[bp+22]	;get number of bitplanes
;	mov bp,[bp+24]	;get bitmap width last
	mov bp,320	;set bitmap width to screen width for now
			;after all, the screen is really just a large bitmap
	mov ch,8	;set height counter to 8 rows
;If it seems it seems like a lot of setup, that is because it was originally
;designed to to be called from a Qb program. The important part starts below.
;This is not the fastest code for translation, but it is the most versatile,
;being able to handle any bitmode without compromising on too much speed.

.nextrow
	mov al,cl	;copy bitplanes
	rol ecx,16	;save bitplanes and height counter 
	mov cl,al	;set plane counter to number of planes
	xor eax,eax	;set both to zero
	xor edx,edx

.nextbitplane
;cl=bitplane counter
;ch=data
;bx=source jump index
	mov ch,[si]	;get next bitplane
	add si,[fs:bx]	;move source to next bitplane (same row) using table
	add bx,2
	
	shr ch,1	;bt and shr take just as long, but shr is smaller
	jnc .1
	or eax,00000001h
.1	shr ch,1
	jnc .2
	or eax,00000100h
.2	shr ch,1
	jnc .3
	or eax,00010000h
.3	shr ch,1
	jnc .4
	or eax,01000000h
.4	shr ch,1
	jnc .5
	or edx,00000001h
.5	shr ch,1
	jnc .6
	or edx,00000100h
.6	shr ch,1
	jnc .7
	or edx,00010000h
.7	shr ch,1
	jnc .8
	or edx,01000000h
.8
	ror eax,1	;roll pixels right to not let the next bitplane clobber this one
	ror edx,1	;rolling left would reverse the the bits (not desirable)

	dec cl
	jnz .nextbitplane

	ror ecx,16	;get access to bitplanes and height counter
	rol eax,cl	;compensate for the prior ror's by rolling left by bitplanes
	mov [es:di],eax	;write first four left pixels
	rol edx,cl	;it stinks that you can not use anything bu cl \:-(
	mov [es:di+4],edx	;write last four right pixels
	add di,bp	;add bitmap width to dest for next row down

	dec ch
	jnz near .nextrow

	pop bp
	pop es
	pop ds
;	retf 16
	ret 16

SNES_mode7:	;! not finished !
;this routine only works for mode 7 SNES graphics
;parameters passed
;  source       segment:offset
;  destination  segment:offset
;  linear bitmap width
;registers used
;  bl=height counter
;  si=raw source data
;  di=linear bitmap destination
;  bp=bitmap width
;  ds=source segment
;  es=destination segment
	mov bl,8
	sub bp,8
.nextrow
	movsd
	movsd
	add si,8
	add di,bp

	dec bl
	jnz .nextrow
	
;	pop

	retf

Section .data

Test_tile:;2bpl non-interleaved
	db 00111100b;1
	db 00111100b;2
	db 01000010b;1
	db 01111110b;2
	db 10011001b;1
	db 11100111b;2
	db 10111101b;1
	db 11000011b;2
	db 11100111b;1
	db 10000001b;2
	db 10111101b;1
	db 11000011b;2
	db 01011010b;1
	db 01100110b;2
	db 00111100b;1
	db 00111100b;2

	db 00111100b
	db 01000010b
	db 10011001b
	db 10111101b
	db 11100111b
	db 10111101b
	db 01011010b
	db 00111100b

	db 00111100b
	db 01111110b
	db 11100111b
	db 11000011b
	db 10000001b
	db 11000011b
	db 01100110b
	db 00111100b

Test_tile_table:
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1
	dw 1

	dw 8
	dw -7
	dw 8
	dw -7
	dw 8
	dw -7
	dw 8
	dw -7
	dw 8
	dw -7
	dw 8
	dw -7
	dw 8
	dw -7
	dw 8
	dw -7