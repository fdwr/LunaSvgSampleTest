;Elements of the computer used
; Stack
;   one large 'pile' of variables that are stacked on each other and unstacked
;   in the order they were put on, used for calling subprograms and returning
;   back to the caller. each program can have its own stack.
; Interrupt table
;   a 256 entry array located at the base of memory, containing far pointers to
;   all the hardware device handlers and system functions.
; Ports
;   #3C8h, the VGA palette index selector (select the color you want to change)
;   #3C9h, the VGA palette data port (send RGB values to it)
;   #42h, the speaker frequency (makes simple sounds, beeps, chirps...)

;Register used
; a - accumalator, often used for mathematical operations and holding numbers
; b - base register, commonly used for indexing into arrays and structures
; c - counter, what else, counting and loops
; d - dumb register, just kidding about that one, it has to stand for something
;    so I just call it the dummy register
;Other registers not used (all are 16bit or 32bit)
; si - source index
; di - destination index
; sp - stack pointer
; bp - local base stack pointer (not the same as the base register)

;Register suffixes
;  ?l - low eight bits(0-7) of register, or first byte
;  ?h - high eight bits(7-15) of register, or second byte
;  ?x - low sixteen bits(0-15), or first two bytes
; e?x - all thirty-two bits(0-31), or all four bytes
;for example,
;  al - the first 8 bits of the accumalator
;  cx - lower 16 bits of the counter
; esi - 32 bit pointer to some data (exactly what data depends on where it points)

; build with NetWide Assembler (free but good) found with just a search by Yahoo:
;    nasm -f bin -o bintest.com bintest.asm

; When run (as a DOS .COM file), this program should print
;    hello, world
; on three successive lines, then print
;    did it work?
; then wait for a keypress and exit cleanly.

	BITS 16		;use 16 bit coding for this example
	ORG 100h	;set alignment to 256 bytes from segment
	
SECTION .text	;this is where all the code goes
	
	call PrintOpeningText
	call WaitForKeyPress
	cmp al,13	;compare ASCII code returned in AL with 13 (Cr or Enter)
	jz pressedEnter	;if not equal to each other (you pressed a different key)
	mov dx,pressedEnterMessage
	mov ah,9
	int 21h
	jmp die
pressedEnter:
	mov dx,anotherKeyMessage	;letting you know you pressed Enter
	mov ah,9
	int 21h
	;  mov al,01011010b	;write byte to timer control port
	;  			;(10) counter 2; (11) select write order
	;			;and (010) rate generator 
	;  out 43h,al
	mov al,200
	out 42h,al	;send desired frequency in two chunks, low|high
	xor al,al	;set a to zero
	out 42h,al	;send msb (highest byte)
	xor ax,ax	;set ax to zero
	mov es,ax	;set segment es to ax (zero)
	mov cx,[es:46Ch];get starting timer value
	add cx,200	;add two hundred to it
	;call WaitForKeyPress
.loopwait mov dx,[es:46Ch]
	cmp cx,dx
	jl exhausted
	
	mov ah,1	;set ah to function 1, get keyboard status
	int 16h		;use interrupt 16h to call keyboard BIOS
	jz .loopwait	;continue looping until a key is pressed
	call WaitForKeyPress	;grab keypress so it is not waiting behind
	
	xor al,al	;set al to zero
	out 42h,al	;send a low zero  (8bits)
	out 42h,al	;then a high zero (8bits) (8 + 8 = a full 16 bits)
	mov dx,silenced
	mov ah,9
	int 21h
	jmp die
exhausted:
	  mov dx,exhaustedMessage
	  mov ah,9
	  int 21h
die:	mov ax,4C00h	;load ax with DOS function 4Ch (terminate)
			;the following '00' specifies no exit code
	int 21h		;call on DOS to its dirty work and kill this program

PrintOpeningText:
	mov word [counter],3	;set variable counter to number of repeats
	mov bp,dumbtext	;set bp to point to dumbtext
	mov cx,question-dumbtext
	mov bl,9	;move the color in bl, starting with bright blue
.reprint
	call PrintColoredString
	inc bl		;increment bl to change to next color
	dec word [counter]	;decrement counter (same as x--)
	jnz .reprint	;jump back to .reprint while cx is greater than zero
	
	mov dx,question	;set dx to point to question
	mov ah,9	;set ah to DOS function 9h (print some text)
	int 21h		;use interrupt 21h to call DOS
	ret		;return to caller
	
WaitForKeyPress:
	mov ah,0	;set ah to BIOS function 0h (wait for keypress)
	int 16h		;use interrupt 16h to call keyboard BIOS
	ret
	
PrintColoredString:	;color attribute must be in bl, length in cx, pointer in bp
	xor bh,bh	;set screen page to one
	push cx		;save cx by pushing it onto the stack so its value
			;will not be destroyed
	mov ah,3h	;set ah to video BIOS function 3h, read cursor position
	int 10h		;use interrupt 10h to call video BIOS
	pop cx		;restore saved cx to what it was before the call
			;by pulling it from the stack (or as silly Intel likes
			;to say, I guess to be different, popping it off the
			;stack)
	mov ax,1301h	;set ax to video BIOS function 13h, with color on and cursor moveable
	int 10h		;use interrupt 10h to call video BIOS
	ret

SECTION .data	;here is where to store some static data (constants)

dumbtext:
	db '  Are there three colors being printed, blue, green, cyan?',13,10
question:
	db 'Did it work?  Press Enter to make some sound...or another key to quit',13,10,13,10,'$'
pressedEnterMessage:
	db 'You do not want to hear my singing debut? (:-\',13,10,'$'
anotherKeyMessage:
	db 'So it can only hum one monotonous tune...what else would you expect for a demo,',13,10
	db 'an orchestra? Press any key to stop that annoying hum, or just wait until',13,10
	db 'I am out of breath, actually it is a timer. :-o) ',14,32,14,13,10,'$'
silenced: 
	db 'You want me to stop singing? Okay...   :-)$'
exhaustedMessage:
	db 'Phew, that is all the air I have  :-)$'
	
SECTION .bss	;section to store memory variables (rewritable)

counter:
	resw 1