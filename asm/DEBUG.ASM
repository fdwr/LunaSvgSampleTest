; Generic Debugging routines

%macro DisplayString 1
section .data
    db %1,"$"
section .text
    pusha
    mov edx,[esp+32]
    mov ah,9
    int 21h
    popa
    ret 4
%endm

%macro DbgDisplayNum 2
    push dword %1
  %if %2=10
    call DgbDisplayDecNum
  %else ;16 hex
    call DgbDisplayHexNum
  %endif
%endm

_DbgDisplayDecNum:
    pusha
    mov eax,[esp+32]
    sub esp,byte NumStringDecLen+1
    mov edi,esp
    call NumToString
.Print:
    mov [esp+NumStringDecLen],byte '$'
    mov edx,esp
    mov ah,9
    int 21h
    popa
    ret 4

_DbgDisplayHexNum:
    pusha
    mov eax,[esp+32]
    sub esp,byte NumStringHexLen+1
    mov ebx,16
    mov ecx,NumStringHexLen
    mov edi,esp
    call NumToString.GiveRadix
    mov [esp+NumStringHexLen],byte '$'
    jmp short _DbgDisplayDecNum.Print
