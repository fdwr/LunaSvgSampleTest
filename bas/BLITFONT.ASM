;fast font blitter for Qbasic; blits fonts from BIOS table to mode 13 screen
;includes clipping, transparency, any color, and arbitrary rows or columns
;the drawbacks so far are that characters must be 8x8, and the screen mode
;must be mode 13 - may change later...

;variables passed onto it include
;  letter as ASCII character  
;  row as signed integer (negative values won't produce an error)
;  col as signed integer (same as above)
;  color in the range 0 to 255

 BITS 16
 ORG 0
 
; push word 15
; push word 50 
; push word 50
; push word 65
 
; push cs
; call startblit
 
; add sp,8

; mov ax,4C00h
; int 21h

startblit:
 push ds        ;save all necessary variables for restoration later
 push es
 push bp

	mov bp,sp
	mov ax,0F000h   ;ROM Bios segment for letter bitmaps
	mov ds,ax
	mov ax,0A000h   ;screen base segment
	mov es,ax
	mov si,[bp+10]  ;get letter (ASCII character code)
	shl si,3        ;multiply by sixty-four by shifting left six
	add si,0FA6Eh   ;add an ofset of 64110 to get letters base

;----------------------------------clip the row and height
;bx=row  si=source  di=destination
	mov bx,[bp+12]  ;get row into BX
	test bx,bx      ;compare row against row to test for sign
	jns row_greater_than_zero
 ;===if row less than zero
	sub si,bx       ;add row to source
	add bx,8        ;subtract row from eight
	xor di,di       ;make destination base zero
	jmp row_evaluate
row_greater_than_zero:
 ;===else row zero or greater
	mov ax,bx       ;copy row to AX for following multiply instruction
	mov di,320
	mul di          ;multiply ax by 320 to get destination
	mov di,ax
	neg bx
	add bx,200      ;add 200 to get letter height
	cmp bx,8
	js row_on_border;height is less than eight if positive (no sign)
	mov bx,8
row_on_border:
row_evaluate:
	cmp bx,1        ;compare height counter (ax) over one
			;everything ok? height should be in BL
	js near end_of_blitter

;----------------------------------clip the column and width
;dx=col  cl=preshift  di=destination
	mov dx,[bp+14]  ;get col
	test dx,dx      ;compare col (bx) against zero using test
	jns col_greater_than_zero
 ;===if col less than zero
	mov cx,dx       ;copy col to CX
	neg cl          ;negate CL to get pre-shift
	add dx,8        ;subtract positive col from eight to get width
		;both source and destination are unchanged
	jmp col_evaluate
col_greater_than_zero:
 ;===else col zero or greater
	add di,dx       ;add column ofset to destination
			;source remains unchanged
	xor cl,cl       ;make pre-shift (cl) equal to zero
	neg dx
	add dx,320      ;add 320 to col to get width
	cmp dx,8
	js col_evaluate;width is less than eight if positive (no sign)
	mov dx,8
col_evaluate:
	cmp dx,1        ;compare width counter (bx) over one
	js near end_of_blitter
	mov ch,dl

	neg dx          ;make DL negtive for next instruction
	add dx,320       ;determine actual wrap distance
			;by subtracting width from 320
	mov al,[bp+16]  ;move in color value

;----------------------------------start the screen blitting using clips
;al=row of bits  cl=preshift  ch=columns  bh=column counter  bl=row counter
;di=screen position  si=font table  dx=screen wrap

next_row:               ;read in an entire row, eight bits in a byte
	mov ah,[si]     ;load byte from source into AH, incrementing SI
	inc si
	shl al,cl       ;pre-shift the bytemap to adjust for column ofset
	mov bh,ch       ;copy CH to BH as column counter
next_bit:
	shl ah,1        ;shift the bytemap by one to set carry flag
	jnc do_not_draw
	stosb
	dec bh
	jnz next_bit
	jmp done_with_row
do_not_draw:
	inc di
	dec bh
	jnz next_bit
done_with_row:
	add di,dx
	dec bl
	jnz next_row    ;go back and get next row
;----------------------------------
end_of_blitter:
	pop bp          ;restore segments and base pointer for Qbasic
	pop es          ;unless you want Qb to crash
	pop ds

	;ret
	retf 8  ;reduce stack by 4*2 (four parameters two bytes each)
