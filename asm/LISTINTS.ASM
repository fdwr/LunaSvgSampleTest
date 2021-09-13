; Interrupt lister
; Dwayne Robinson
; 2002-05-29
; Simply lists the 256 interrupt vectors
;
; Compiling:
;   nasm -f bin LISTINTS.ASM -o LISTINTS.COM

bits 16
org 100h

Main:
    xor bx,bx               ;zero for first interrupt entry
    mov si,IntNames
    mov [IntText+4],byte  ' ';put in space
    mov [IntText+9],byte  ':';put in segment:offset separator
    mov [IntText+14],byte ' ';put in space

.Next:
    ; form interrupt number
    mov dx,bx               ;pass current interrupt number
    mov di,IntText          ;set text ptr
    shr dx,2
    call WordToStr          ;convert offset word to string
    inc di                  ;skip space
    xor cx,cx               ;zero extend for counting
    mov ds,cx               ;access table at base of memory
    mov dx,[bx]             ;get interrupt offset
    call WordToStr          ;convert offset word to string
    inc di                  ;skip colon
    mov dx,[bx+2]           ;get segment
    call WordToStr          ;convert segment word to string
    push es
    pop ds
    inc di                  ;skip space

    ; form interrupt name
    mov cl,[si]             ;get length of interrupt name
    push cx                 ;save length
    inc si                  ;skip length byte
    rep movsb               ;transfer name
    mov ax,0A0Dh            ;append cr/lf
    stosw                   ;transfer name
    pop cx                  ;restore string length

    ; print interrupt string
    push bx
    add cx,byte 5+10+2      ;add length of segment:offset and cr/lf
    mov dx,IntText
    mov bx,1                ;console output handle
    mov ah,40h              ;DOS: Write to file
	int 21h
    pop bx

    ; next interrupt while <256
    add bx,byte 4
    cmp bx,256*4
    jb .Next

.End:
    mov ah,9                ;DOS: print string
    mov dx,InfoText
	int 21h

    mov ax,4C00h
    int 21h

; (dx=number, di=destination ptr)
WordToStr:
    mov cl,4
    cld
.Next:
    rol dx,4
    mov al,dl
    and al,15
    add al,'0'
    cmp al,'9'
    jbe .Numeric
    add al,'A'-'0'-10
.Numeric:
    stosb
    dec cl
    jg .Next
    ret


section .data

%assign IntNum 0
%macro AddIntName 2
    times %1-IntNum db 0
 %if %1 < 256
    db %%Eos-$-1
    db %2
%%Eos:
 %endif
    %assign IntNum %1+1
%endmacro

IntNames:
    AddIntName   0,"Division by zero"
    AddIntName   1,"Single step"
    AddIntName   2,"Non-maskable"
    AddIntName   3,"Breakpoint"
    AddIntName   4,"Overflow"
    AddIntName   5,"BIOS Print screen"
    AddIntName   6,"Invalid opcode"
    AddIntName   7,"Coprocessor unavailable"
    AddIntName   8,"Timer"
    AddIntName   9,"Keyboard"
    AddIntName 0Ah,"Slave PIC or VGA retrace"
    AddIntName 0Bh,"COM2"
    AddIntName 0Ch,"COM1"
    AddIntName 0Dh,"Fixed disk"
    AddIntName 0Eh,"Floppy disk"
    AddIntName 0Fh,"LPT1"
    AddIntName 10h,"Video BIOS functions"
    AddIntName 11h,"BIOS equipment determination"
    AddIntName 12h,"Memory size"
    AddIntName 13h,"BIOS diskette services"
    AddIntName 14h,"Serial communications"
    AddIntName 15h,"BIOS system services"
    AddIntName 16h,"BIOS keyboard services"
    AddIntName 17h,"Parallel printer"
    AddIntName 18h,"ROM BASIC loader"
    AddIntName 19h,"Bootstrap loader"
    AddIntName 1Ah,"BIOS real time clock services"
    AddIntName 1Bh,"Ctrl+Break handler"
    AddIntName 1Ch,"Clock tick handler"
    AddIntName 1Dh,"Video parameter pointter"
    AddIntName 1Eh,"Diskette parameter pointer"
    AddIntName 1Fh,"Graphics character table"
    AddIntName 20h,"DOS program termination"
    AddIntName 21h,"DOS services"
    AddIntName 22h,"Program termination address"
    AddIntName 23h,"Ctrl+Break termination address"
    AddIntName 24h,"DOS critical error handler"
    AddIntName 25h,"DOS absolute disk read"
    AddIntName 26h,"DOS absolute disk write"
    AddIntName 27h,"DOS terminate and stay resident"
    AddIntName 28h,"DOS idle loop"
    AddIntName 29h,"DOS fast character I/O"
    AddIntName 2Ah,"DOS network services"
    AddIntName 2Bh,"DOS internal"
    AddIntName 2Ch,"DOS internal"
    AddIntName 2Dh,"DOS internal"
    AddIntName 2Eh,"Execute command prompt"
    AddIntName 2Fh,"DOS multiplex"
    AddIntName 30h,"CPM far address"
    AddIntName 31h,"Protected mode interface (DPMI)"
    AddIntName 32h,"reserved"
    AddIntName 33h,"Mouse driver functions"
    AddIntName 256,""

InfoText:
    db 10
    db "List Interrupts - Dwayne Robinson 2002",13,10
    db "Use LISTINTS | MORE or LISTINTS > INTS.TXT$"

section .bss
IntText: resb 50
