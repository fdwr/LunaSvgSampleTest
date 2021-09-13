; Convert.asm - conversion functions from one image pixel data to another
;
; 20040815 Dwayne Robinson
;
; Many of these are not written in assembler for speed's sake, but rather
; simply because it was easier (and cleaner than multiple ugly type casts).

%define CONVERT_ASM
%include "convert.h"

[section .text]

gsym ConvertFormatFrom
.dest	equ 4
.src	equ 8
.count	equ 12
.format	equ 16
.alpha	equ 20
%define espb esp+12
	push ebx
	push esi
	push edi
	mov esi,[espb+.src]
	mov edi,[espb+.dest]
	mov ecx,[espb+.count]
	mov edx,[espb+.format]
	mov ebx,[espb+.alpha]	; only some function use this
	call dword [.Jtbl+edx*4]
	pop edi
	pop esi
	pop ebx
	ret

align 4
.Jtbl:
	dd .LE1
	dd .BE1			; black and white
	dd .LE2
	dd .BE2			; 4 color
	dd .LE4
	dd .BE4			; 16 color
	dd .LE8
	dd .BE8			; 256 color
	dd .LE16
	dd .BE16		; raw 16bit
	dd .LE32
	dd .BE32		; raw 32bit
	dd .BGRA5551
	dd .RGBA5551	; 15bit with 1bit alpha
	dd .BGR565
	dd .RGB565		; 16bit
	dd .BGR888
	dd .RGB888		; 24bit
	dd .BGRA8888
	dd .RGBA8888	; 32bit with alpha

.LE1:
	mov edx,[esi]
	mov eax,edx
	shl eax,7
	mov al,dl
	shl eax,7
	mov al,dl
	shl eax,7
	mov al,dl
	and eax,01010101h
	mov [edi],eax
	sub ecx,byte 4
	jle .LE1end

	mov eax,edx
	shl eax,7
	mov al,bl
	shl eax,7
	mov al,dl
	shl eax,3
	mov al,dl
	shr al,4
	and eax,01010101h
	mov [edi+4],eax

	inc esi
	add edi,byte 8
	sub ecx,byte 4
	jg .LE1
.LE1end:
	ret
.BE1:		; black and white
	mov edx,[esi]
	mov eax,edx
	shl eax,9
	mov al,dl
	shl eax,9
	mov al,dl
	shl eax,2
	mov al,dl
	shr al,7
	and eax,01010101h
	mov [edi],eax
	sub ecx,byte 4
	jle .BE1end

	mov eax,edx
	shl eax,9
	mov al,dl
	shl eax,9
	mov al,dl
	shl eax,6
	mov al,dl
	shr al,3
	and eax,01010101h
	mov [edi+4],eax

	inc esi
	add edi,byte 8
	sub ecx,byte 4
	jg .BE1
.BE1end:
	ret
.LE2:
%if 0
	mov eax,[esi]
	mov edx,eax
	rol eax,16
	mov ah,dh
	and eax,0xFFFFFF
	add esi,byte 3
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .Next
%endif
	ret
.BE2:		; 4 color
%if 0
	mov eax,[esi]
	mov edx,eax
	rol eax,16
	mov ah,dh
	and eax,0xFFFFFF
	add esi,byte 3
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .Next
%endif
	ret
.LE4:
	mov eax,[esi]				;1 2 3 4|5 6 7 8|
	shl eax,4					;- 1 2 3|4 5 6 7|
	shr ax,4					;1 2 3 -|4 5 6 7|
	shl eax,8					;- - 1 2|3 - 4 5|
	shr ax,4					;- 1 2 -|3 - 4 5|
	shr al,4					;1 - 2 -|3 - 4 5|
	; alternate code
	;mov edx,eax				;1 2 3 4|5 6 7 8|
	;shl edx,4					;- 1 2 3|4 5 6 7|
	;mov dh,ah					;- 1 3 4|4 5 6 7|
	;shl edx,4					;- - 1 3|4 4 5 6|
	;mov dl,al					;1 2 1 3|4 4 5 6|
	;shl edx,4					;- 1 2 1|3 4 4 5|
	;mov dl,al					;1 2 2 1|3 4 4 5|
	and eax,0F0F0F0Fh
	add esi,byte 2
	mov [edi],eax
	add edi,byte 4
	sub ecx,byte 4
	jg .LE4
	ret
.BE4:		; 16 color
	mov eax,[esi]				;2 1 4 3|6 5 8 7|
	rol al,4					;1 2 4 3|6 5 8 7|
	rol ah,4					;1 2 3 4|6 5 8 7|
	shl eax,4					;- 1 2 3|4 5 6 7|
	shr ax,4					;1 2 3 -|4 5 6 7|
	shl eax,8					;- - 1 2|3 - 4 5|
	shr ax,4					;- 1 2 -|3 - 4 5|
	shr al,4					;1 - 2 -|3 - 4 5|
	and eax,0F0F0F0Fh
	add esi,byte 2
	mov [edi],eax
	add edi,byte 4
	sub ecx,byte 4
	jg .BE4
	ret
.LE8:
.BE8:		; 256 color
	; no additional processing
	; just copy directly
	mov edx,ecx
	shr ecx,2
	rep movsd
	mov ecx,edx
	and ecx,3
	rep movsb
	ret
.LE16:
	mov eax,[esi]
	add esi,byte 2
	and eax,0000FFFFh
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .LE16
	ret
.BE16:		; raw 16bit
	; swap high/low byte
	mov eax,[esi]
	add esi,byte 2
	xchg al,ah
	and eax,0000FFFFh
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .BE16
	ret
.LE32:
	; no additional processing
	; just copy directly
	rep movsd
	ret
.BE32:		; raw 32bit
	; correct byte order 4321 -> 1234
	mov eax,[esi]
	xchg al,ah
	rol eax,16
	xchg al,ah
	add esi,byte 4
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .BE32
	ret
.BGRA5551:
	mov eax,[esi]
	cwde
	shl eax,5
	shr ax,3
	shr al,3
	shl eax,3
	and eax,0xF8F8F8F8
	add esi,byte 2
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .BGRA5551
	ret
.RGBA5551:	; 15bit with 1bit alpha
%if 0
	mov eax,[esi]
	mov edx,eax
	rol eax,16
	mov ah,dh
	and eax,0xFFFFFF
	add esi,byte 3
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .Next
%endif
	ret
.BGR565:
	shl ebx,24
.BGR565Next:
%if 0
	mov eax,[esi]
	mov ebx,eax
	rol eax,16
	mov ah,dh
	and eax,0xFFFFFF
	add esi,byte 2
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg BGR565Next
%endif
	ret
.RGB565:	; 16bit
%if 0
	mov eax,[esi]
	mov edx,eax
	rol eax,16
	mov ah,dh
	and eax,0xFFFFFF
	add esi,byte 2
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .Next
%endif
	ret
.BGR888:
	shl ebx,24
.BGR888Next:
	mov eax,[esi]
	add esi,byte 3
	and eax,0xFFFFFF
	or eax,ebx
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .BGR888Next
	ret
.RGB888:	; 24bit
	shl ebx,24
.RGB888Next:
	mov eax,[esi]
	mov edx,eax
	rol eax,16
	mov ah,dh
	and eax,0xFFFFFF
	or eax,ebx
	add esi,byte 3
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .RGB888Next
	ret
.BGRA8888:
	; no additional processing
	; just copy directly
	rep movsd
	ret
.RGBA8888:	; 32bit with alpha
	mov eax,[esi]
	xchg al,ah
	rol eax,16
	xchg al,ah
	add esi,byte 4
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .BE32
	ret



gsym ConvertFormatTo
.dest	equ 4
.src	equ 8
.count	equ 12
.format	equ 16
.alpha	equ 20
%define espb esp+12
	push ebx
	push esi
	push edi
	mov esi,[espb+.src]
	mov edi,[espb+.dest]
	mov ecx,[espb+.count]
	mov edx,[espb+.format]
	mov ebx,[espb+.alpha]	; only some function use this
	;call dword [.Jtbl+edx*4]
	pop edi
	pop esi
	pop ebx
	ret

align 4
.Jtbl:
%if 0
	dd .LE1
	dd .BE1			; black and white
	dd .LE2
	dd .BE2			; 4 color
	dd .LE4
	dd .BE4			; 16 color
	dd .LE8
	dd .BE8			; 256 color
	dd .LE16
	dd .BE16		; raw 16bit
	dd .LE32
	dd .BE32		; raw 32bit
	dd .BGRA5551
	dd .RGBA5551	; 15bit with 1bit alpha
	dd .BGR565
	dd .RGB565		; 16bit
	dd .BGR888
	dd .RGB888		; 24bit
	dd .BGRA8888
	dd .RGBA8888	; 32bit with alpha
%endif


gsym ConvertRgbToBgr
.dest	equ 4
.src	equ 8
.count	equ 12
%define espb esp+8

	push esi
	push edi
	mov esi,[espb+.src]
	mov edi,[espb+.dest]
	mov ecx,[espb+.count]
.Next:
	mov eax,[esi]
	mov edx,eax				; copy pixel
	rol eax,16				; RGB0 -> B0RG
	mov ah,dh				; B0RG -> BGRG
	and eax,0xFFFFFF		; BGRG -> BGR0
	add esi,byte 3
	mov [edi],eax
	add edi,byte 4
	dec ecx
	jg .Next
	pop edi
	pop esi
	ret


gsym ConvertIndexedToRgb
.dest	equ 4
.src	equ 8
.count	equ 12
.pal	equ 16
%define espb esp+12
	push ebx
	push esi
	push edi
	mov esi,[espb+.src]
	mov edi,[espb+.dest]
	xor eax,eax
	mov ecx,[espb+.count]
	mov ebx,[espb+.pal]
.Next:
	mov al,[esi]
	mov edx,[ebx+eax*4]
	inc esi
	mov [edi],edx
	add edi,byte 4
	dec ecx
	jg .Next

	pop edi
	pop esi
	pop ebx
	ret


; does not do expected color quantization!
; too much work for now.
gsym ConvertRgbToIndexed
.dest	equ 4
.src	equ 8
.count	equ 12
.pal	equ 16
%define espb esp+12
	push ebx
	push esi
	push edi
	mov esi,[espb+.src]
	mov edi,[espb+.dest]
	;xor eax,eax
	mov ecx,[espb+.count]
	;mov ebx,[espb+.pal]
.Next:
	mov eax,[esi]
	;add edx,al
	add esi,byte 4
	mov [edi],al
	inc edi
	dec ecx
	jg .Next

	pop edi
	pop esi
	pop ebx
	ret
