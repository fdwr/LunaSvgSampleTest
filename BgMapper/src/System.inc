; Standard Library - system routines
; by Gaz Jones
; https://web.archive.org/web/20030211000714/http://www.phoenix.gb.net:80/x86/
;
%ifndef _SYSTEM
%define _SYSTEM
[BITS 32]

[section .bss]
%ifdef _MYSYSTEM_ATEXIT_MACRO
_mysystem_atexit_list	resd 64
%else
%ifdef _MYSYSTEM_EXIT_MACRO
_mysystem_atexit_list	resd 64
%endif
%endif

[section .data]
%ifdef _MYSYSTEM_ATEXIT_MACRO
_mysystem_atexit_count	dd 0
%else
%ifdef _MYSYSTEM_EXIT_MACRO
_mysystem_atexit_count	dd 0
%endif
%endif

[section .text]
;
;--------------------------------------------------------------------
;
; Adds an exit routine to the list
;
%ifdef _MYSYSTEM_ATEXIT_MACRO
_mysystem_atexit_2:
	push	eax				; save registers
	push	ebx
	cmp	[_mysystem_atexit_count],dword 64	; space for another function?
	je	_mysystem_atexit_error		; no, end with error
	mov	eax,_mysystem_atexit_list	; eax -> list of exit functions
	mov	ebx,[_mysystem_atexit_count]	; number of functions there already
	shl	ebx,2				; * 4
	add	eax,ebx				; eax -> next position in list
	mov	ebx,[esp + 12]			; get address of function to add
	mov	[eax],ebx			; save address
	inc	dword [_mysystem_atexit_count]	; another function added
	pop	ebx				; restore registers
	pop	eax
	clc					; flag success
	ret
_mysystem_atexit_error:
	pop	ebx				; restore registers
	pop	eax
	stc					; flag error
	ret
%endif
;
;--------------------------------------------------------------------
;
; Terminates the program, calling any exit functions added
;
%ifdef _MYSYSTEM_EXIT_MACRO
_mysystem_exit_2:
        ;lea     esp,[esp + 4]                  ; tidy stack (not needed)
	mov	ecx,[_mysystem_atexit_count]	; get number of exit functions
        test ecx,ecx                            ; none?
	jz	_mysystem_exit_end		; yes, just end here
	dec	ecx				; no, one less  because we're going backwards
	mov	esi,_mysystem_atexit_list	; get the list of functions
	shl	ecx,2				; *4 because it's dwords
	add	esi,ecx				; get to last function address
	shr	ecx,2				; restore number
	inc	ecx
_mysystem_exit_loop:
	push	ecx				; save registers
	push	esi
	call	[esi]				; call the function
	pop	esi				; restore registers
	pop	ecx
	sub	esi,4				; next function back
	dec	ecx				; another one called
	jnz	_mysystem_exit_loop		; call all functions
_mysystem_exit_end:
        ;mov ah,$04c        ;do not exit now
        ;int $21            ;just return, and allow
        ret                 ;caller to terminate
%endif

%endif
