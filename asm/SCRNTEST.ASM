; this is my first test of nasm as an assambler and asmedit for a assembly
; shell, so far I'm really impressed
; it should set the screen mode to mode 13h and blit a whole bunch of colored
; pixels to it. Eventually it will be turned into a full fledged bitmap pixel
; blitter with clipping and lightning speed. There will also be an speedy
; bitmap tiler that tiles any specified bitmap across a window

	BITS 16
	ORG 100h
	
	SECTION .text
	
	jmp setscrn
	
endall	mov ax,4c00h
	int 21h
	
;this is the begining of the program
setscrn mov ax,13h
	int 10h
	
; blitpixels
	push es ;save current extra segment...
	mov ax,0a000h
	mov es,ax
	mov cx,64000 ;that's how many pixels will be output
	xor di,di ;cancel out DI with itself to set it to zero
nextpixel
	stosb ;write pixel color (AL) to screen destination (DI) and increment
	inc al ;increment color by one
	;and al,0Fh ;loop back to zero when reaches 15
	loop nextpixel	
	
	pop es ;...and restore it here
	
print_leaving_message
	mov ah,9
	mov dx, stuff_to_say
	int 21h
	
	jmp endall
	
	SECTION .data
	
stuff_to_say
	db 'Did this print?',13,10,'$'