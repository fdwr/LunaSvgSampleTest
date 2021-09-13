bits 16
org 100h

BytesPerTransfer        equ 16384   ;divide by BytesPerSector to get sectors
BytesPerSector          equ 512
%define OutputFilenameS "bootdata.dat"

    push ds
    pop es
    
;the following really should be called to get the actual bytes per sector
;mov ah,8
;int 13

ReadSectors:
    mov ax,0200h | (BytesPerTransfer / BytesPerSector)
    mov bx,DiskBuffer
    mov cx,1                        ;start from track 0, sector 1
    mov dx,0080h                    ;head 0, hard drive
    int 13h
    mov dx,Messages.ErrorReadingSector
    jc ErrorMessageQuit

OpenFile:
    mov ah,3Ch                      ;DOS function: create file
    xor cx,cx
    mov dx,OutputFilename
    int 21h
    mov dx,Messages.ErrorOpeningFile
    jc ErrorMessageQuit
    mov bx,ax                       ;copy returned file handle to bx

    mov ah,40h                      ;DOS function: write to file
    mov cx,BytesPerTransfer
    mov dx,DiskBuffer
    int 21h

    mov ah,3Eh                      ;DOS function: close file
    ;bx still contains file handle
    int 21h
    mov ah,9                        ;DOS function: display string
    mov dx,Messages.SectorsTransferred
    int 21h
    mov ax,4C00h                    ;DOS function: terminate, no errors
    int 21h

ErrorMessageQuit:
    mov ah,9                        ;DOS function: display string
    int 21h
    mov ax,4C01h                    ;DOS function: terminate, with error
    int 21h

SECTION .data
OutputFilename:         db OutputFilenameS,0

Messages:
.ErrorOpeningFile:      db "Could not open output file: ",OutputFilenameS,"$"
.ErrorReadingSector:    db "Error reading sectors.$"
.SectorsTransferred:    db "Sectors transferred to: ",OutputFilenameS,"$"

section .bss
align 2
DiskBuffer:             resb BytesPerTransfer
