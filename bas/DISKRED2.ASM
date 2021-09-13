;Called by Qbasic to read absolute disk sectors.

;Parameters are drive, starting sector, number of sectors, far destination

    bits 16
    org 0

    section .text
    push ds         ;save current data segment
    push bp         ;save base pointer
    mov bp,sp
    mov ax,[bp+8]   ;which drive to read
    mov dx,[bp+10]  ;starting sector
    mov cx,[bp+12]  ;number of sectors
    mov ds,[bp+14]  ;data segment to write to
    mov bx,[bp+16]  ;offset in segment

    int 25h         ;function to read disk sectors
    popf            ;remove the flags DOS left on the stack

    pop bp          ;restore saved base pointer
    pop ds          ;restore data saved segment
    retf 10         ;return to Qbasic
