;transfer 64000 bytes from desired source to screen (mode 13/320x200/256color)
;uses 32bit memory movement to double speed

;parameters passed to it:
; source&       a long intger by value, far pointer to the memory to be read
;               only the first twenty bytes are considered (first megabyte)

        bits 16
        org 100h

        push ds ;save registers and set up base pointer for stack references
        push es
        push bp
        mov bp, sp

        mov eax,[bp+10] ;load source& into eax
        mov si,ax       ;make a copy
        shr eax,4       ;reduce by 16
        mov ds,ax       ;set data segment to source, upper bits are ignored
        and si,15       ;mask out all but lower four bits for source index

        mov ax,0A000h   ;destination, VGA screen
        mov es,ax       ;set extra segment to destination
        xor di,di       ;set destination base to zero

        mov cx,15360    ;set counter to 61440 for long words
        rep movsd       ;repeat until all words have been transferred
                        ;move string from ds:si to es:di
        pop bp
        pop es
        pop ds

        retf 4          ;return to caller, reducing stack by 4
                        ;that's all folks, nothing much to it

