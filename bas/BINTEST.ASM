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
;   #40h, the speaker frequency (makes simple sounds, beeps, chirps...)

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
	jnz WrongKey	;if not equal to each other (you pressed a different key)
	  mov dx,pressedEnter
	  mov ah,9
	  int 21h
	  jmp die
:WrongKey
	  mov dx,anotherKey
	  mov ah,9
	  int 21h
	  mov al,1011010b	;write byte to timer control port
	  			;(10) counter 2; (11) select write order
				;and (010) rate generator 
	  out 43h,al
	  mov ax,200
	  out 42h,ax
.loopwait call WaitForKeyPress
	  cmp al,13
	  jnz .loopwait
	  mov dx,silenced
	  mov ah,9
	  int 21h	
:die	mov ax,4C00h	;load ax with DOS function 4Ch (terminate)
			;the following '00' specifies no exit code
	int 21h		;call on DOS to its dirty work and kill this program

:PrintOpeningText
	mov cx,3	;set counter to number of repeats
.reprint
	mov dx,dumbtext	;set dx to point to dumbtext
	mov ah,9	;set ah to DOS function 9h (print some text)
	push cx		;temporarily save cx by pushing it onto the stack,
			;so DOS does not destroy it
	int 21h		;use interrupt 21h to call DOS
	pop cx		;restore saved cx by to what it was before the call
			;by pulling it from the stack (or as silly Intel likes
			;to say, I guess to be different, popping it off the
			;stack)
	loop reprint	;jump back to .reprint while cx is greater than zero
	
	mov dx,question	;set dx to point to question
	mov ah,9	;set ah to DOS function 9h (print some text)
	int 21h		;use interrupt 21h to call DOS
	ret		;return to caller
	
:WaitForKeyPress
	mov ah,0	;set ah to BIOS function 0h (wait for keypress)
	int 16h		;use interrupt 16h to call BIOS
	ret

SECTION .data	;here is where to reserve some data space

:dumbtext
	db '  Dwayne here just doing a test of this things capabilities',13,10,'$'
:question
	db 'Did it work?  Press Enter to continue...or another key to see what happens','$'
:pressedEnter
	db 'Right on! See ya later',13,10,'$'
:anotherKey
	db 'Wrong key! prepare for your computer yell at you forever',13,10
	db 'Or at least until you press the right key...:-O ',14,32,14,'$'
:silenced
	db 'You silenced me :-)$'