bits 32

section text

global Main

Main:
    mov edx,HelloWorld
    mov eax,0900h
    int 21h
    mov eax,4C00h
    int 21h

section data
HelloWorld: db "Hello World$"



