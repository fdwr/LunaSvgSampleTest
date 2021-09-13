section code

;------------------------------
; (edi=destination, ecx=byte count) (trashes eax, ecx, edx)
;
ZeroFill:
    push edi
    cld
    xor eax,eax
    mov edx,ecx
    shr ecx,2
    rep stosd                           ;32-bits at a time
    mov ecx,edx
    and ecx,3
    rep stosb                           ;8-bits residual
    pop edi
    ret

%macro MovDwordViaEax 2
    mov eax,%2
    mov %1,eax
%endmacro
