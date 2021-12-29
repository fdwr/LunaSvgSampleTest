; Memory management subsystem
; by Gaz Jones
; https://web.archive.org/web/20030211000714/http://www.phoenix.gb.net:80/x86/
;
%ifndef _MYHEAP
%define _MYHEAP

[BITS 32]
[section .bss]
_myheap_spare1		resd 1
_myheap_spare2		resd 1
_myheap_spare3		resd 1

%ifdef _MYHEAP_INIT_MACRO
_myheap_start		resd 1			; address of start of heap
%endif

[section .data]
%ifdef _MYHEAP_INIT_MACRO
_myheap_handlesi	dw 0			; memory handle for deallocation
_myheap_handledi	dw 0
%endif

[section .text]
;
;------------------------------------------------------------------------------------
;
; Heap block formats:
;
; Header:           Total heap size (ie allocated memory block size)
;                   Free space left on the heap
;                   End heap address
;                   Address of first free block
;                   4 dwords reserved
;
; Allocated block:  Block size
;                   Address of previous block
;
; Free block:       Block size
;                   Free block marker string - 'FREE'
;                   Address of next free block
;                   Address of previous block
;
; Don't write code that assumes/takes advantage of the internal heap format! It's
; designed so you don't have to worry about the internal workings and it might
; change. Just use the routines provided.
;
;------------------------------------------------------------------------------------
;
; Call to initialise the routines. Carry is set on error, clear otherwise.
;
%ifdef _MYHEAP_INIT_MACRO
_myheap_init_2:
	push	eax				; save registers
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi
	cmp	[_myheap_handlesi],word 0	; sanity check to see if a heap's
	jne	near _myheap_init_error		; already been allocated
	cmp	[_myheap_handledi],word 0
	jne	near _myheap_init_error
	mov	edx,[esp + 28]			; get amount to allocate
	cmp	edx,0				; is it zero?
	jz	_myheap_init_allocate_all	; yes, go allocate all available free memory
	cmp	edx,256				; sanity check for tiny heap allocation
	jbe	near _myheap_init_error
	mov	ecx,edx				; no, bx:cx holds amount to allocate
	shld	ebx,edx,16			; get high word of edx into bx
	mov	ax,$501				; allocate memory
	int	$31
	jc	near _myheap_init_error		; couldn't allocate memory!
	jmp	_myheap_init_ok			; memory allocated, continue
_myheap_init_allocate_all:
	sub	esp,54				; space for the 48 byte buffer
	mov	edi,esp				; edi->buffer to hold information
	mov	ax,$0500			; get free memory information
	int	$31
	pop	edx				; edx holds largest free memory block
	lea	esp,[esp + 50]			; correct stack
_myheap_init_loop:
	cmp	edx,$01000			; less than 4K to try to allocate?
	jb	near _myheap_init_error		; yes, error
	mov	ecx,edx				; no, bx:cx holds amount to allocate
	shld	ebx,edx,16			; get high word of edx into bx
	mov	ax,$0501			; try and allocate memory
	int	$31
	jnc	_myheap_init_ok			; allocated?
	sub	edx,$01000			; no, one page less (4K)
	jmp	_myheap_init_loop		; keep trying
_myheap_init_ok:
	mov	[_myheap_handlesi],si		; save memory handle for de-allocation later
	mov	[_myheap_handledi],di
	shl	ebx,16
	mov	bx,cx
	add	ebx,7				; align up to nearest 8-byte boundary (sanity check on the
	and	ebx,$0fffffff8			; allocated block start really)
	mov	[_myheap_start],ebx		; save start of heap
	mov	[ebx],edx			; save size of heap
	and	edx,$0fffffff8			; we allocate in 8-byte chunks so align to that
	sub	edx,48				; size of allocated block header + 16 byte padding at the end + heap header + 8 bytes sanity
	mov	[ebx + 4],edx			; save amount of space on the heap
	mov	eax,ebx
	add	eax,16				; eax holds address of first block on the heap
	mov	ecx,[_myheap_start]		; ecx holds address of the start of the heap
	add	ecx,[ebx + 4]			; add the size of the heap
	mov	[ebx + 8],ecx			; save the address of the end of the heap
	mov	[ecx - 16],dword 0		; 16 bytes of padding at the end of the heap for safety
	mov	[ecx - 12],dword 0
	mov	[ecx - 8],dword 0
	mov	[ecx - 4],dword 0
	mov	[ebx + 12],eax			; save address of first free block
	mov	[eax],edx			; setup first free block with size of free heap space
	mov	[eax + 4],dword 'FREE'		; free block marker string
	mov	[eax + 8],dword 0		; no previous block
	mov	[eax + 12],dword 0		; no next block
%define _MYHEAP_EXIT_MACRO
	AtExit	_myheap_exit_2
	pop	edi				; restore registers
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
_myheap_init_error:
	pop	edi				; restore registers
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	stc					; flag error
	ret
%endif
;
;------------------------------------------------------------------------------------
;
; Resets the heap to its initial state (ie all free).
;
%ifdef _MYHEAP_RESET_MACRO
_myheap_reset_2:
	push	eax				; save registers
	push	ebx
	push	edx
	mov	eax,[_myheap_start]		; get the heap start
	mov	edx,[eax]			; get the heap size
	and	edx,$0fffffff8
	sub	edx,40
	mov	[eax + 4],edx			; save amount of free space on the heap
	mov	ebx,eax
	add	ebx,16
	mov	[eax + 12],ebx			; save address of first free block
	mov	[eax],edx			; setup first free block with size of free heap space
	mov	[eax + 4],dword 'FREE'		; free block marker string
	mov	[eax + 8],dword 0		; no previous block
	mov	[eax + 12],dword 0		; no next block
	pop	edx				; restore registers
	pop	ebx
	pop	eax
	clc					; flag success
	ret
%endif
;
;------------------------------------------------------------------------------------
;
; Re-sizes a previously allocated block
;
%ifdef _MYHEAP_REALLOC_MACRO
_myheap_realloc_2:
	push	eax				; save registers
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi
	mov	esi,[esp + 32]
	mov	ecx,[esp + 28]
	cld					; clear direction flag
	add	ecx,7				; align size up to nearest
	and	ecx,$0fffffff8			; 8-byte boundary
	mov	[_myheap_spare1],esi		; assume it'll go wrong
	HeapBlockCheck esi,eax			; is it a valid block?
	jc	near _myheap_realloc_error	; no
	cmp	[esi - 4],dword 'FREE'		; is it a free block?
	je	near _myheap_realloc_error	; yes!
	cmp	ecx,eax				; is the new size the same?
	je	near _myheap_realloc_end	; it's the same, don't do anything
	HeapBlockSpace ecx			; is there space for a new block of the new size?
	jc	_myheap_realloc_nospace		; no, try it the hard way
	Malloc	ecx,edi				; yes, allocate new block
	jc	near _myheap_realloc_error	; heap integrity probably lost, just exit with error
	mov	[_myheap_spare1],edi		; save block's new address
	push	esi
	cmp	[esi - 8],ecx			; is the old block smaller than the new one?
	jae	_myheap_realloc_sizeok		; no
	mov	ecx,[esi - 8]			; yes, use the old block's size
_myheap_realloc_sizeok:
	shr	ecx,2				; divide by 4 because we'll copy dwords
	rep	movsd				; copy old block's contents to new
	pop	esi
	Free	esi				; and free up the old block
	jc	near _myheap_realloc_error	; memory leak...
_myheap_realloc_end:
	pop	edi				; restore registers
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
_myheap_realloc_nospace:
	sub	esi,8				; get to start of block's header
	cmp	ecx,[esi]			; is the new size less than the old?
	jl	_myheap_realloc_shrink		; yes, so shrink the block down
	mov	eax,[esi]			; no, set free size to check to be the same as this block's size
	mov	edi,esi				; get to block after this block
	add	edi,[edi]
	cmp	[edi + 4],dword 'FREE'		; is it a free block?
	jne	_myheap_realloc_nextnotfree	; no
	add	eax,[edi]			; yes, add this free block's size to the count
_myheap_realloc_nextnotfree:
	mov	edi,[esi + 4]			; get to previous block
	cmp	[edi + 4],dword 'FREE'		; is this a free block?
	jne	_myheap_realloc_prevnotfree	; no
	add	eax,[edi]			; yes, add this free block's size to the count
_myheap_realloc_prevnotfree:
	cmp	ecx,eax				; is the new block's size more than the space around this block?
	ja	near _myheap_realloc_error	; no else free up this block and allocate a new one (like when we shrink it)
_myheap_realloc_shrink:
	mov	eax,[esi + 8]			; save first two dwords of block
	mov	ebx,[esi + 12]			; (they'll be trashed by the free block header)
	mov	[_myheap_spare2],eax
	mov	[_myheap_spare3],ebx
	Free	esi				; free up the block
	jc	near _myheap_realloc_error	; oh dear
	mov	ebx,esi				; save old block's start address
	mov	esi,[_myheap_start]		; esi->heap header
	mov	esi,[esi + 12]			; get address of first free block
_myheap_realloc_loop:
	cmp	ecx,[esi]			; this block big enough?
	jbe	_myheap_realloc_found		; yes, go allocate it
	mov	esi,[esi + 8]			; no, get address of next block
	jmp	_myheap_realloc_loop		; _must_ be in a later block
_myheap_realloc_found:
	mov	edx,[esi]			; edx holds size of this free block
	sub	edx,16				; minus size of a free block
	cmp	ecx,edx				; still enough space for our new block?
	ja	_myheap_realloc_nosplit		; no, just convert free block to allocated block
	push	esi				; save address of this free block
	push	ecx				; save size of new block
	shr	ecx,2				; divide by 4 because we're copying dwords
	sub	ecx,2				; two dwords already done
	lea	edi,[esi + 16]			; edi -> start of new block's data (after first two dwords and header)
	lea	esi,[ebx + 8]			; esi -> start of old block (after first two dwords)
	rep	movsd				; and copy old block to new
	pop	ecx				; restore registers
	pop	esi
	mov	eax,esi				; eax holds address of free block
	add	eax,ecx				; get to first byte after the new block
	add	eax,8				; don't forget the header size
	mov	edx,[esi]			; edx holds size of this free block
	mov	[eax],edx			; save size of the new free block
	sub	[eax],ecx			; not forgetting to subtract the size of this block
	sub	[eax],dword 8			; and the header size
	mov	edx,[esi + 8]			; get address of next free block
	mov	[eax + 4],dword 'FREE'		; free block marker
	mov	[eax + 8],edx			; save address of next free block
	mov	[eax + 12],esi			; save address of previous block
	mov	edx,[_myheap_start]		; edx points to the heap header
	cmp	[edx + 12],esi			; was this the first free block?
	jne	_myheap_realloc_end2		; no, don't worry
	mov	[edx + 12],eax			; yes, update first free block pointer
_myheap_realloc_end2:
	mov	[esi],ecx			; put in size of block
	sub	[edx + 4],ecx			; update heap free space
	sub	[edx + 4],dword 8
	mov	edx,[esi + 12]			; get address of previous block
	mov	[esi + 4],edx			; put into newly allocated block
	add	esi,8				; get past block header
	mov	[_myheap_spare1],esi		; save block's new address
	mov	eax,[_myheap_spare2]		; put in old block's first two dwords
	mov	ebx,[_myheap_spare3]
	mov	[esi],eax
	mov	[esi + 4],ebx
	pop	edi				; restore registers
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
_myheap_realloc_nosplit:
	mov	[esi],ecx			; put in size of block
	mov	edx,[esi + 12]			; get address of previous block
	mov	[esi + 4],edx			; put into newly allocated block
	mov	eax,[esi + 8]			; get address of next free block
	mov	edx,[_myheap_start]		; edx points to the heap header
	cmp	[edx + 12],esi			; was this the first free block?
	jne	_myheap_realloc_nosplit_end	; no, don't worry
	mov	[edx + 12],eax			; yes, update the first free block pointer
_myheap_realloc_nosplit_end:
	sub	[edx + 4],ecx			; update heap free space
	sub	[edx + 4],dword 8
	add	esi,8				; get past block header
	mov	[_myheap_spare1],esi		; save new block's address
	mov	eax,[_myheap_spare2]		; put first two dwords of old block back
	mov	[esi],eax
	mov	eax,[_myheap_spare3]
	mov	[esi + 4],eax
	lea	edi,[esi + 8]			; edi -> start of new block (after first two dwords)
	lea	esi,[ebx + 8]			; esi -> start of old block (after first two dwords)
	shr	ecx,2				; divide by 4 because we're copying dwords
	sub	ecx,2				; two dwords already done
	rep	movsd				; and copy old block to new block
	pop	edi				; restore registers
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
_myheap_realloc_error:
	pop	edi				; restore registers
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	stc					; flag error
	ret
%endif
;
;------------------------------------------------------------------------------------
;
; Call to allocate a block on the heap. Carry is set on error, clear otherwise.
;
%ifdef _MYHEAP_ALLOC_MACRO
_myheap_alloc_2:
	push	eax				; save registers
	push	ecx
	push	edx
	push	esi
	mov	ecx,[esp + 20]
	add	ecx,7				; align size up to nearest
	and	ecx,$0fffffff8			; 8-byte boundary
	mov	esi,[_myheap_start]		; esi->heap header
	mov	esi,[esi + 12]			; get address of first free block
	or	esi,esi				; no free blocks?
	jz	_myheap_alloc_error		; no!
	xor	eax,eax
_myheap_alloc_loop:
	cmp	ecx,[esi]			; this block big enough?
	jbe	_myheap_alloc_found		; yes, go allocate it
	mov	eax,esi				; no, save address of this block
	mov	esi,[esi + 8]			; and get address of next block
	or	esi,esi				; no more blocks to check?
	jnz	_myheap_alloc_loop		; no, keep looking
_myheap_alloc_error:
	mov	[_myheap_spare1],dword 0
	pop	esi				; yes, restore registers
	pop	edx
	pop	ecx
	pop	eax
	stc					; flag error
	ret
_myheap_alloc_found:
	mov	edx,[esi]			; edx holds size of this free block
	sub	edx,16				; minus size of a free block
	cmp	ecx,edx				; still enough space for our new block?
	ja	_myheap_alloc_nosplit		; no, just convert free block to allocated block
	push	eax				; save address of last free block checked
	mov	eax,esi				; eax holds address of free block
	add	eax,ecx				; get to first byte after the new block
	add	eax,8				; don't forget the header size
	mov	edx,[esi]			; edx holds size of this free block
	mov	[eax],edx			; save size of the new free block
	sub	[eax],ecx			; not forgetting to subtract the size of this block
	sub	[eax],dword 8			; and the header size
	mov	edx,[esi + 8]			; get address of next free block
	mov	[eax + 4],dword 'FREE'		; free block marker
	mov	[eax + 8],edx			; save address of next free block
	mov	[eax + 12],esi			; save address of previous block
	mov	edx,[_myheap_start]		; edx points to the heap header
	cmp	[edx + 12],esi			; was this the first free block?
	jne	_myheap_alloc_end		; no, don't worry
	mov	[edx + 12],eax			; yes, update first free block pointer
_myheap_alloc_end:
	mov	[esi],ecx			; put in size of block
	sub	[edx + 4],ecx			; update heap free space
	sub	[edx + 4],dword 8
	mov	edx,[esi + 12]			; get address of previous block
	mov	[esi + 4],edx			; put into newly allocated block
	add	esi,8				; get past block header
	mov	[_myheap_spare1],esi
	pop	ecx				; restore address of last block checked
	or	ecx,ecx				; null pointer?
	jz	_myheap_alloc_end2		; yes, ignore
	mov	[ecx + 8],eax			; no, save address of new free block into previous free block
_myheap_alloc_end2:
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	eax
	clc					; flag success
	ret
_myheap_alloc_nosplit:
	push	eax				; save address of previous free block
	push	dword [esi + 8]			; and address of next free block
	mov	[esi],ecx			; put in size of block
	mov	edx,[esi + 12]			; get address of previous block
	mov	[esi + 4],edx			; put into newly allocated block
	mov	eax,[esi + 8]			; get address of next free block
	mov	edx,[_myheap_start]		; edx points to the heap header
	cmp	[edx + 12],esi			; was this the first free block?
	jne	_myheap_alloc_nosplit_end	; no, don't worry
	mov	[edx + 12],eax			; yes, update the first free block pointer
_myheap_alloc_nosplit_end:
	sub	[edx + 4],ecx			; update heap free space
	sub	[edx + 4],dword 8
	add	esi,8				; get past block header
	mov	[_myheap_spare1],esi
	pop	esi				; restore address of next free block
	pop	eax				; and address of previous free block
	mov	[eax + 8],esi			; and update "next free block" pointer
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	eax
	clc					; flag success
	ret
%endif
;
;------------------------------------------------------------------------------------
;
; Call to deallocate a previously allocated block
;
%ifdef _MYHEAP_FREE_MACRO
_myheap_free_2:
	push	eax				; save registers
	push	ebx
	push	ecx
	push	edx
	push	esi
	mov	esi,[esp + 24]
	mov	ebx,[_myheap_start]
	lea	ecx,[ebx + 16]			; start of heap blocks
	mov	edx,esi				; used for a check in a moment
	sub	esi,8				; get to start of header
	mov	eax,[esi + 4]			; get address of previous block
	cmp	eax,dword 'FREE'		; is it already a free block?
	je	near _myheap_free_error		; yes, error
	or	eax,eax				; no, is it a zero pointer?
	jnz	_myheap_free_prevcheck		; no, so check the previous block
	cmp	esi,ecx				; yes, this must be the first block
	jne	near _myheap_free_error		; no, invalid block
	jmp	_myheap_free_noprevcheck	; yes, skip the previous block checks
_myheap_free_prevcheck:
	cmp	eax,ecx 			; is this address before the heap?
	jb	near _myheap_free_error		; yes, error
	cmp	eax,[ebx + 8]			; is this address after the heap?
	jae	near _myheap_free_error		; yes, error
	and	edx,7				; is the address not on an 8-byte boundary?
	jnz	near _myheap_free_error		; it's not, error
	add	eax,[eax]			; yes, assume it's valid now, so use the previous block's size
	add	eax,8				; to get back to the block to deallocate
	cmp	eax,esi				; are the addresses the same?
	jne	near _myheap_free_error		; no, invalid block address
	mov	eax,[esi + 4]			; get address of previous block
	cmp	[eax + 4],dword 'FREE'		; is it a free block?
	je	near _myheap_free_joinprevblock	; yes, join this and the previous together
_myheap_free_noprevcheck:
	lea	eax,[esi + 8]			; get address of this block plus header size
	add	eax,[esi]			; add size of this block to get to next block
	cmp	eax,[ebx + 8]			; is this still in the heap?
	jae	near _myheap_free_nojoin2	; no, special case of deallocating the final heap block
	cmp	[eax + 4],dword 'FREE'		; yes, is this a free block?
	jne	_myheap_free_nojoin		; no, just deallocate this block

;
; Here we've got a free block straight after the block we're deallocating, so
; we join them both into one free block.
;
	mov	ecx,[esi]			; update total heap free space
	add	ecx,8				; don't forget the header of the free block after this block
	add	[ebx + 4],ecx
	mov	ecx,[eax]			; update size of this block
	add	ecx,8				; don't forget the header of the free block after this block
	add	[esi],ecx
	mov	ecx,[eax + 8]			; put in address of next free block
	mov	[esi + 8],ecx
	mov	ecx,[esi + 4]			; put in address of previous block
	mov	[esi + 12],ecx
	mov	[esi + 4],dword 'FREE'		; put in free block marker
	add	eax,[eax]			; now update the block after the free block after this block
	add	eax,8
	cmp	eax,[ebx + 8]			; is this block still in the heap?
	jae	_myheap_free_join_check		; no
	mov	[eax + 4],esi			; yes, update previous block pointer
_myheap_free_join_check:
	cmp	esi,[ebx + 12]			; is this free block before the current first free block pointer?
	jae	_myheap_free_join_end		; no
	mov	[ebx + 12],esi			; yes, update the first free block pointer
_myheap_free_join_end:
	mov	eax,esi				; save address of this block so we can update the previous free block's
	lea	esi,[esi + 8]			; "next free block" pointer.
_myheap_free_join_loop:
	mov	esi,[esi + 4]			; get address of previous block
	or	esi,esi				; all block's checked?
	jz	_myheap_free_join_loop_end	; yes, finish
	cmp	[esi + 4],dword 'FREE'		; no, is it a free block?
	jne	_myheap_free_join_loop		; no, keep looking
	mov	[esi + 8],eax			; yes, update "next free block" pointer
_myheap_free_join_loop_end:
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
;
; The block we're deallocating doesn't have a free block either just before or straight
; after it so we just mark it as free.
;
_myheap_free_nojoin:
	mov	eax,[esi + 4]			; get the previous block's address
	mov	[esi + 4],dword 'FREE'		; put in free block marker string
	mov	[esi + 12],eax			; put in address of previous block
	mov	eax,esi				; save address of this block so we can update the previous free block's
	lea	esi,[esi + 8]			; "next free block" pointer.
_myheap_free_nojoin_loop0:
	mov	esi,[esi + 4]			; get address of previous block
	or	esi,esi				; all block's checked?
	jz	_myheap_free_nojoin_loop0_end	; yes, finish
	cmp	[esi + 4],dword 'FREE'		; no, is it a free block?
	jne	_myheap_free_nojoin_loop0	; no, keep looking
	mov	[esi + 8],eax			; yes, update "next free block" pointer
_myheap_free_nojoin_loop0_end:
	mov	esi,eax
	cmp	esi,[ebx + 12]			; is this free block before the current first free block pointer?
	jae	_myheap_free_nojoin_loop	; no
	mov	[ebx + 12],esi			; yes, update the first free block pointer
_myheap_free_nojoin_loop:
	add	eax,[eax]			; get to next block
	add	eax,8				; don't forget the header size
	cmp	eax,[ebx + 8]			; gone past the heap end?
	jae	_myheap_free_nojoin_loop_end	; yes, mustn't be any free blocks after this one
	cmp	[eax + 4],dword 'FREE'		; no, is it a free block?
	jne	_myheap_free_nojoin_loop	; no, keep looking
	mov	[esi + 8],eax			; yes, save address
	mov	ecx,[esi]			; update total heap free space
	add	[ebx + 4],ecx
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
;
; Special case of there being no free blocks after this block
;
_myheap_free_nojoin_loop_end:
	mov	[esi + 8],dword 0		; no free blocks after this one
	mov	ecx,[esi]			; update total heap free space
	add	[ebx + 4],ecx
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
;
; Special case of the block to deallocate being the last block
;
_myheap_free_nojoin2:
	mov	eax,[esi + 4]			; mark this block as free
	mov	[esi + 4],dword 'FREE'		; put in free block marker string
	mov	[esi + 8],dword 0		; no next block
	mov	[esi + 12],eax			; put in address of previous block
	mov	ecx,[esi]			; update total heap free space
	add	[ebx + 4],ecx
	mov	eax,esi				; save address of this block so we can update the previous free block's
	lea	esi,[esi + 8]			; "next free block" pointer.
_myheap_free_nojoin2_loop:
	mov	esi,[esi + 4]			; get address of previous block
	or	esi,esi				; all block's checked?
	jz	_myheap_free_nojoin2_loop_end	; yes, finish
	cmp	[esi + 4],dword 'FREE'		; no, is it a free block?
	jne	_myheap_free_nojoin2_loop	; no, keep looking
	mov	[esi + 8],eax			; yes, update "next free block" pointer
_myheap_free_nojoin2_loop_end:
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
;
; Here we've got a free block just before the block we're deallocating, so we
; join them both into one free block. We might have another free block after
; these two and in that case we'll join all three into one block
;
_myheap_free_joinprevblock:
	lea	ecx,[esi + 8]			; get address of this block plus header size
	add	ecx,[esi]			; add size of this block to get to next block
	cmp	ecx,[ebx + 8]			; is this block still in the heap?
	jae	_myheap_free_joinprevblock2	; no, just join this and the previous block
	cmp	[ecx + 4],dword 'FREE'		; yes, is it a free block?
	je	_myheap_free_jointhreeblocks	; yes, join all three blocks together
;
; Here we know we've got a free block before this block so join the two together
;
_myheap_free_joinprevblock2:
	mov	ecx,[eax]			; update the total heap free space, not forgetting
	add	ecx,8				; the header of the free block before this (the two
	sub	[ebx + 4],ecx			; blocks combined size will be added later)
	mov	ecx,[esi]			; update block's size
	add	ecx,8				; don't forget the header of the free block before this block
	add	[eax],ecx
	mov	ecx,esi				; now update the block after this block
	add	ecx,[ecx]
	add	ecx,8
	cmp	ecx,[ebx + 8]			; is this block still in the heap?
	jae	_myheap_free_joinprevblock_done	; no
	mov	[ecx + 4],eax			; yes, update the previous block address of the next block
_myheap_free_joinprevblock_done:
	mov	esi,[esi + 8]			; get the address of the next free block
	mov	[eax + 8],esi			; and store in the enlarged block
	cmp	eax,[ebx + 12]			; is this free block before the current first free block pointer?
	jae	_myheap_free_joinprevblock_end	; no
	mov	[ebx + 12],eax			; yes, update the first free block pointer
_myheap_free_joinprevblock_end:
	mov	ecx,[esi]			; update total heap free space
	add	[ebx + 4],ecx
	mov	esi,eax				; save address of this block so we can update the previous free block's
	lea	esi,[esi + 8]			; "next free block" pointer.
_myheap_free_joinprevblock_loop:
	mov	esi,[esi + 4]			; get address of previous block
	or	esi,esi				; all block's checked?
	jz	_myheap_free_joinprevblock_loop_end	; yes, finish
	cmp	[esi + 4],dword 'FREE'		; no, is it a free block?
	jne	_myheap_free_joinprevblock_loop		; no, keep looking
	mov	[esi + 8],eax			; yes, update "next free block" pointer
_myheap_free_joinprevblock_loop_end:
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
;
; Here we know we've got a free block just before and straight after the block
; to deallocate so we join them all into one block
;
_myheap_free_jointhreeblocks:
	mov	edx,[ecx]			; add the last block's size
	add	[eax],edx
	mov	edx,[esi]			; add the middle block's size
	add	edx,16				; don't forget the headers of the two free blocks
	add	[eax],edx
	mov	edx,[ecx + 8]			; update the next free block address
	mov	[eax + 8],edx
	mov	edx,ecx				; now update the block after the third block
	add	edx,[edx]
	add	edx,8
	cmp	edx,[ebx + 8]			; is this block still in the heap?
	jae	_myheap_free_jointhreeblocks_check	; no
	mov	[edx + 4],eax			; yes, update the previous block address
_myheap_free_jointhreeblocks_check:
	mov	ecx,[esi]			; update the total heap free space
	add	ecx,16				; don't forget the two headers
	add	[ebx + 4],ecx
	cmp	eax,[ebx + 12]			; is this free block before the current first free block pointer?
	jae	_myheap_free_jointhreeblocks_end	; no
	mov	[ebx + 12],eax			; yes, update the first free block pointer
_myheap_free_jointhreeblocks_end:
	mov	esi,eax				; save address of this block so we can update the previous free block's
	lea	esi,[esi + 8]			; "next free block" pointer.
_myheap_free_jointhreeblocks_loop:
	mov	esi,[esi + 4]			; get address of previous block
	or	esi,esi				; all block's checked?
	jz	_myheap_free_jointhreeblocks_loop_end	; yes, finish
	cmp	[esi + 4],dword 'FREE'		; no, is it a free block?
	jne	_myheap_free_jointhreeblocks_loop		; no, keep looking
	mov	[esi + 8],eax			; yes, update "next free block" pointer
_myheap_free_jointhreeblocks_loop_end:
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
_myheap_free_error:
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	stc					; flag error
	ret
%endif
;
;------------------------------------------------------------------------------------
;
; Returns the heap size (bytes).
;
%ifdef _MYHEAP_SIZE_MACRO
_myheap_size_2:
	push	eax
	mov	eax,[_myheap_start]
	mov	eax,[eax]
	mov	[_myheap_spare1],eax
	pop	eax
	clc					; flag success
	ret
%endif
;
;------------------------------------------------------------------------------------
;
; Returns the amount of free space on the heap (bytes).
;
%ifdef _MYHEAP_SPACE_MACRO
_myheap_space_2:
	push	eax
	mov	eax,[_myheap_start]
	mov	eax,[eax + 4]
	mov	[_myheap_spare1],eax
	pop	eax
	clc					; flag success
	ret
%endif
;
;------------------------------------------------------------------------------------
;
; Checks whether a block is a valid allocated heap block
;
%ifdef _MYHEAP_BLOCKCHECK_MACRO
_myheap_blockcheck_2:
	push	eax				; save registers
	push	ebx
	push	ecx
	push	edx
	push	esi
	mov	esi,[esp + 24]
	mov	ebx,[_myheap_start]
	lea	ecx,[ebx + 16]			; start of heap blocks
	mov	edx,esi				; used for a check in a moment
	sub	esi,8				; get to start of header
	mov	eax,[esi + 4]			; get address of previous block
	or	eax,eax				; is it a zero pointer?
	jnz	_myheap_blockcheck_prevcheck	; no, so check the previous block
	cmp	esi,ecx				; yes, this must be the first block
	jne	near _myheap_blockcheck_error	; no, invalid block
	jmp	_myheap_blockcheck_noprevcheck	; yes, skip the previous block checks
_myheap_blockcheck_prevcheck:
	cmp	eax,ecx 			; is this address before the heap?
	jb	near _myheap_blockcheck_error	; yes, error
	cmp	eax,[ebx + 8]			; is this address after the heap?
	jae	near _myheap_blockcheck_error	; yes, error
	and	edx,7				; is the address not on an 8-byte boundary?
	jnz	near _myheap_blockcheck_error	; it's not, error
	add	eax,[eax]			; assume it's valid now, so use the previous block's size
	add	eax,8				; to get back to the block to check
	cmp	eax,esi				; are the addresses the same?
	jne	near _myheap_blockcheck_error	; no, invalid block address
_myheap_blockcheck_noprevcheck:
	mov	eax,[esi]
	mov	[_myheap_spare1],eax
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	clc					; flag success
	ret
_myheap_blockcheck_error:
	mov	[_myheap_spare1],dword 0
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax
	stc					; flag error
	ret
%endif
;
;------------------------------------------------------------------------------------
;
; Checks whether a block of the specified size exists.
;
%ifdef _MYHEAP_BLOCKSPACE_MACRO
_myheap_blockspace_2:
	push	eax				; save registers
	push	ecx
	push	edx
	push	esi
	mov	ecx,[esp + 20]
	add	ecx,7				; align size up to nearest
	and	ecx,$0fffffff8			; 8-byte boundary
	mov	esi,[_myheap_start]		; esi->heap header
	mov	esi,[esi + 12]			; get address of first free block
	or	esi,esi				; no free blocks?
	jz	_myheap_blockspace_error	; no!
_myheap_blockspace_loop:
	cmp	ecx,[esi]			; this block big enough?
	jbe	_myheap_blockspace_found	; yes
	mov	esi,[esi + 8]			; no, get address of next block
	or	esi,esi				; no more blocks to check?
	jnz	_myheap_blockspace_loop		; no, keep looking
_myheap_blockspace_error:
	pop	esi				; yes, restore registers
	pop	edx
	pop	ecx
	pop	eax
	stc					; flag error
	ret
_myheap_blockspace_found:
	pop	esi				; restore registers
	pop	edx
	pop	ecx
	pop	eax
	clc					; flag success
	ret
%endif
;
;------------------------------------------------------------------------------------
;
; Call to de-initialise the routines and de-allocate resources.
;
%ifdef _MYHEAP_EXIT_MACRO
_myheap_exit_2:
	push	eax				; save registers
	push	esi
	push	edi
	mov	si,[_myheap_handlesi]		; de-allocate heap
	mov	di,[_myheap_handledi]
	mov	ax,$0502
	int	$31
	mov	[_myheap_handlesi],word 0	; set handle as being de-allocated
	mov	[_myheap_handledi],word 0
	pop	edi				; restore registers
	pop	esi
	pop	eax
	clc					; flag success
	ret
%endif

%ifdef _MYHEAP_ALLOC_MACRO
%ifndef _MYHEAP_INIT_MACRO
%error "Must call HeapInit to use Malloc/Calloc!"
%endif
%endif

%ifdef _MYHEAP_REALLOC_MACRO
%ifndef _MYHEAP_INIT_MACRO
%error "Must call HeapInit to use Realloc!"
%endif
%endif

%ifdef _MYHEAP_FREE_MACRO
%ifndef _MYHEAP_INIT_MACRO
%error "Must call HeapInit to use Free!"
%endif
%endif

%endif
