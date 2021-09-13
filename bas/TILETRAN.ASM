;Tile Translating routines, 5-8-98, FDwR
;For comments, improvements, or code additions, my address is FDwR@Juno.com

;Used to convert game console sprite formats into more useable linear bitmaps.
;It can blit the result to a bitmap in memory or directly to the screen.
;The code uses 32bit registers but 16bit memory addressing; for some stupid
;reason, whenever I try to read any bit of information using flat addressing
;the computer locks up or reports a GPF error. Even when doing nothing but
;harmlessly reading, it states my program has done an illegal operation \:-(
;It acts like it is Chernobyl, ready to blow up the whole computer. Maybe I
;want it to do that illegal operation! Despite that, is it is super fast. It
;took me quite a while to perfect it to where it is at, choosing all the
;right registers for optimum performance and removing all unecessary memory
;references that would slow it down, so if anybody out there decides to
;use it in their own viewer, it would be fair to include my name in it. I
;would not mind a friendly letter either ;-)

;Although it is designed for interface with Qbasic (the SpriteView example),
;the essential core is good with any language. This version is written to be
;compiled by the cool and free 'Netwide Assembler', using
;	nasm -f bin tiletran.asm -o tiletran.com
;then converted into data or put into a library for the Qbasic program, but
;it can also be stored in a COFF file to be used in a compiler like DJGPP
;with a few changes (and no stupid AT&T syntax conversion needed).

;If you do change it to 32bit coding, be sure to edit the BITS statement
;and parameter retrieving accordingly. You might also change all the memory
;references to their 32bit equivalents (si=esi, bx=ebx...). The RETF must be
;removed if you plan to use this with only near calls.

;Routines for SNES and GameBoy
;Plan to eventually support NES and Sega
;SNES (all tiles are 8x8, colormapped palettes)
;  1bit,1bpl,2clr    linear monochrome
;  2bit,2bpl,4clr    bitplane interleaved
;  3bit,3bpl,8clr    unnatural mode used for storage
;  4bit,4bpl,16clr   native sprite format used by PPU
;  8bit,8bpl,256clr  mostly used for highcolor still images
;  8bit,1bpl,256clr  mode 7, used for rotational effects and such
;GameBoy (all tiles are 8x8, grayscale palettes)
;  1bit,1bpl,2clr   linear monochrome
;  2bit,2bpl,4clr   bitplane interleaved
;
;Note that the first two modes of the SNES are the same as the two used by
;the GameBoy, so the very same routine can be used for both systems. The
;high color 8bit modes are of course only for the SNES. If anybody out there
;has detailed info on the NES format, please tell me.

;------------------------------------------------------------------------

bits 16	;how do you define a silly segment to be 32bit code?
	;if calling from a 16bit program without causing a GPF
org 0

;------------------------------------------------------------------------
Section .text

SNES_GB_bitplane_separated:
;this routine works for both SNES and Gameboy graphics
;parameters passed:
;  dword  source      --> ds:si
;  dword  destination --> es:di
; (dword  jump table  --> fs:bx) to be added later ?
;    as for now, there are only a five known bitmodes, so they can all be
;    contained right here in this routine
;  word   bitplanes
;  word   linear bitmap width
;registers used:
;  bx=jump table index
;  cl=bitplanes
;  ch=row counter
;  cl+=plane counter
;  ch+=bitplane row data		(<---input)
;  eax=left row (pixel columns 0-3)	(output-->)
;  edx=right row (pixel columns 4-7)	(output-->)
;  si=raw source data
;  di=linear bitmap destination
;  bp=bitmap width (or screen width, if mode 13h)
;  cs=code segment, and for now, the jump table segment too
;  ds=source segment
;  es=destination segment
; (fs=jump table segment) to be added later
;notation
;  cl+ and ch+ mean the upper 16 bits of eax, only accessible after they
;  have been shifted down (or actually, when the lower bits are shifted up)
;  To save the bitplanes and row counter so they are not overwritten, they
;  are simply shifted up into the 'safe' part of ecx. This saves a tiny bit
;  of time by not writing and rereading their values to memory.
;what it does
;   Basically, it uses a table to tell how the planes are parsed up, then
; loops the number of bitplanes, ORing each bitplane onto the pixel row and
; rolling them until the full pixel depth for eight pixels is achieved.

	push ds
	push es
	push bp
	mov bp,sp

	lds si,[bp+10]	;get all the parameters and put them in their registers
	les di,[bp+14]
	mov ax,0A000h	;<--temporarily put here for safety, it can be removed
	mov es,ax
	mov cx,[bp+18]	;get number of bitplanes
	mov bx,cx
	shl bx,1
	mov bx,[cs:bx+BitplanePtrTable]
	mov bp,[bp+20]	;get bitmap width last
	mov ch,8	;set row counter to 8 rows

;Now that all the setup is done, here is the most important part of it.
;This is not the fastest code for translation, but it is the most versatile,
;being able to handle any bitmode without compromising on too much speed.

.nextrow
	mov al,cl	;copy bitplanes
	shl ecx,16	;save bitplanes and row counter 
	mov cl,al	;set plane counter to number of planes
	xor eax,eax	;set both to zero
	xor edx,edx

.nextbitplane
;cl=bitplane counter
;ch=data
;bx=source jump index
	add si,[cs:bx]	;move source to next bitplane (same row) using table
	add bx,2
	mov ch,[si]	;get next bitplane
	
	shr ch,1	;bt and shr take just as long, but shr is smaller
	jnc .1
	or edx,01000000h
.1	shr ch,1
	jnc .2
	or edx,00010000h
.2	shr ch,1
	jnc .3
	or edx,00000100h
.3	shr ch,1
	jnc .4
	or edx,00000001h
.4	shr ch,1
	jnc .5
	or eax,01000000h
.5	shr ch,1
	jnc .6
	or eax,00010000h
.6	shr ch,1
	jnc .7
	or eax,00000100h
.7	shr ch,1
	jnc .8
	or eax,00000001h
.8
	ror eax,1	;roll pixels left to not let the next bitplane clobber this one
	ror edx,1	;rolling right would reverse the the bits, not desirable,
			;unless you reverse everything

	dec cl
	jnz .nextbitplane

	shr ecx,16	;get access to bitplanes and row counter
	rol eax,cl	;you need to compensate for the prior ror's by rolling it
			;left by an equal number of times it was rolled right above,
			;which is the number of bitplanes
	mov [es:di],eax	;write first four left pixels
	rol edx,cl	;it stinks that you can not use anything but cl \:-(
	mov [es:di+4],edx	;write second four right pixels
	add di,bp	;add bitmap width to dest for next row down

	dec ch
	jnz near .nextrow

	pop bp
	pop es
	pop ds
	retf 12

;Bitplane tables for SNES_GB_bitplane_separated routine. As for now, there
;are only a five known bitmodes, so they can all be contained right here in
;this routine (the jump tables actually take up more space than code though).
Section .data

BitplanePtrTable:
		dw SNES_?,SNES_8x8x1,SNES_8x8x2,SNES_8x8x3,SNES_8x8x4,SNES_?,SNES_?,SNES_?,SNES_8x8x8
SNES_?:		;undefined mode, just select bitmode 1
SNES_8x8x1:	;SNES bit modes 1, 2, and GameBoy use the same table
SNES_8x8x2:
GameBoy_8x8x2:	dw 0,1,1,1,1,1,1,1
		dw 1,1,1,1,1,1,1,1
SNES_8x8x3:	dw 0,1,15,-14,1,14,-13,1,13,-12,1,12,-11,1,11,-10,1,10,-9,1,9,-8,1,8
SNES_8x8x4:	dw 0,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1,-15,1,15,1
SNES_8x8x8:	dw 0,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1,-47,1,15,1,15,1,15,1

;------------------------------------------------------------------------
Section .text

SNES_mode7:
;this routine works for mode 7 SNES graphics in ROMs
;only uncompressed uninterleaved graphics
;parameters passed
;  dword  source      --> ds:si
;  dword  destination --> es:di
;  word   linear bitmap width
;registers used
;  cl=row counter
;  ds=source segment
;  si=raw source data
;  es=destination segment
;  di=linear bitmap destination
;  bp=bitmap width
	push ds
	push es
	push bp
	mov bp,sp

	lds si,[bp+10]
	les di,[bp+14]
	mov dx,[bp+18]
	sub dx,8
	mov cl,8
	cld
.nextrow
	movsd		;write first four left pixels
	movsd		;write second four right pixels
	add di,dx	;add bitmap width to dest for next row down
	dec cl
	jnz .nextrow
	
	pop bp
	pop es
	pop ds

	retf 10

SNES_mode7_interleaved:
;this routine works for mode 7 SNES graphics in savestates
;only uncompressed interleaved graphics
;parameters passed
;  dword  source      --> ds:si
;  dword  destination --> es:di
;  word   linear bitmap width
;registers used
;  cl=row counter
;  ds=source segment
;  si=raw source data
;  es=destination segment
;  di=linear bitmap destination
;  bp=bitmap width
	push ds
	push es
	push bp
	mov bp,sp

	lds si,[bp+10]
	les di,[bp+14]
	mov dx,[bp+18]
	sub dx,8
	mov cl,8
	cld
.nextrow
	mov eax,[si]	;pixels are interleaved with tile data, so there are
	shl ax,8	;only two pixels per four four bytes
	shl eax,8	;shifting condenses the pixels together to the upper 16 bits of eax
	mov ebx,[si+4]	;get next four pixels
	shl bx,8	;shift next two pixels down to 16 lowest bits of ebx
	shr ebx,8
	shrd eax,ebx,16	;combine the first two pixels from eax with the second two pixels from ebx
	stosd		;write first four left pixels
	mov eax,[si+8]	;same thing here as above
	shl ax,8
	shl eax,8
	mov ebx,[si+12]
	shl bx,8
	shr ebx,8
	shrd eax,ebx,16
	stosd		;write second four right pixels
	add si,16	;move source 16 bytes forward (only 8 pixels though)
	add di,dx	;add bitmap width to dest for next row down
	dec cl
	jnz .nextrow
	
	pop bp
	pop es
	pop ds

	retf 10