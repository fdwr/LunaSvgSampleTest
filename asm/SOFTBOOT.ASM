bits 16
org 100

    mov dl,80h                  ;default is first fixed disk drive
    int 19h                     ;execute bootstrap loader
    jmp 0FFFFh:0                ;if for some strange reason, it didn't work
