; CombOrder DLL Test
; 2002-03-17
; Dwayne Robinson
;
; Simply calls CombOrder from DLL

[section code code]
[section data data]
[section text data]
[section bss bss]

%define debug
%define UseWindowMsgs
%define UseWindowStyles         ;for message boxes
%include "mywininc.asm"

%define MultiSort

CmpVoid     equ 0  ;<- does nothing (for completeness ;)
CmpReserved equ 1  ;<- might use for variants, might not
CmpLongSA   equ 2  ;<- 32bit signed integers
CmpLongSD   equ 3
CmpLongUA   equ 4  ;<- 32bit unsigned integers
CmpLongUD   equ 5
CmpSngA     equ 6  ;<- floating point singles
CmpSngD     equ 7
CmpStrAA    equ 8  ;<- ASCII null terminated C strings
CmpStrAD    equ 9
CmpStrWA    equ 10 ;<- Widebyte Unicode C strings
CmpStrWD    equ 11
CmpStrBA    equ 12 ;<- BSTR Visual Basic 4+ strings
CmpStrBD    equ 13

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

%macro BSTR 3
    dd %2
%1: db %3
%endmacro

%macro ASTR 2
%1: db %2,0
%endmacro

%ifndef MultiSort
section bss
IntArraySize equ 1000000
IntArray:    resd IntArraySize

section data
StrArray:
StrArraySize equ 20
dd .0,.1,.2,.3,.4,.5,.6,.7,.8,.9,.10,.11,.12,.13,.14,.15,.16,.17,.18,.19

ASTR .0,"Acoustic Grand"
ASTR .1,"Bright Acoustic"
ASTR .2,"Electric Grand"
ASTR .3,"Honky-Tonk"
ASTR .4,"Electric Piano 1"
ASTR .5,"Electric Piano 2"
ASTR .6,"Harpsichord"
ASTR .7,"Clavinet"
ASTR .8,"Celesta"
ASTR .9,"Glockenspiel"
ASTR .10,"Music Box"
ASTR .11,"Vibraphone"
ASTR .12,"Marimba"
ASTR .13,"Xylophone"
ASTR .14,"Tubular Bells"
ASTR .15,"Dulcimer"
ASTR .16,"Drawbar Organ"
ASTR .17,"Percussive Organ"
ASTR .18,"Rock Organ"
ASTR .19,"Church Organ"

align 4,db 0
FloatArray:
FloatArraySize equ 20
dd 5.3, 1.2, 8.7, 2, -9.34, 2.77, 2.78, 2.76, -11.3, 17.1
dd 4.9, 9.99, 13.7, 2002, 1980, 1883, -4000, 1, 7, -3.3333

%else

section data
ArraySize equ 20
IntArraySize equ ArraySize

IntArray:
dd 3,2,4
dd 5,1,9
dd 5,20,3,4
dd 5,8,7,1,11
dd 10,6,21
dd 19,17

FloatArray:
dd 5.3, 1.2, 8.7, 2, -9.34, 2.77, 2.78, 2.76, -11.3, 17.1
dd 4.9, 9.99, 13.7, 2002, 1980, 1883, -4000, 1, 7, -3.3333

StrArray:
dd .0,.1,.2,.3,.4,.5,.6,.7,.8,.9,.10,.11,.12,.13,.14,.15,.16,.17,.18,.19

ASTR .0,"Ranma"
ASTR .1,"Ranma"
ASTR .2,"Ranma"
ASTR .3,"Cowboy Bebop"
ASTR .4,"Cowboy Bebop"
ASTR .5,"Cowboy Bebop"
ASTR .6,"Inuyasha"
ASTR .7,"Inuyasha"
ASTR .8,"Inuyasha"
ASTR .9,"Inuyasha"
ASTR .10,"Slayers"
ASTR .11,"Slayers"
ASTR .12,"Slayers"
ASTR .13,"Ranma"
ASTR .14,"Slayers"
ASTR .15,"Evangelion"
ASTR .16,"Evangelion"
ASTR .17,"Evangelion"
ASTR .18,"FLCL"
ASTR .19,"FLCL"

%endif

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section text
ProgTitle:  db "TestSort",0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
section code
global Main
Main:
    debugmsg "program stack=%x",esp

%ifndef MultiSort
    debugmsg "random strings = %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s",[StrArray+0],[StrArray+4],[StrArray+8],[StrArray+12],[StrArray+16],[StrArray+20],[StrArray+24],[StrArray+28],[StrArray+32],[StrArray+36],[StrArray+40],[StrArray+44],[StrArray+48],[StrArray+52],[StrArray+56],[StrArray+60],[StrArray+64],[StrArray+68],[StrArray+72],[StrArray+76]
    call ShowArray
    api CombOrder, StrArray,StrArraySize,CmpStrAA,0 ;EscCb
    debugmsg "sorted strings = %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s",[StrArray+0],[StrArray+4],[StrArray+8],[StrArray+12],[StrArray+16],[StrArray+20],[StrArray+24],[StrArray+28],[StrArray+32],[StrArray+36],[StrArray+40],[StrArray+44],[StrArray+48],[StrArray+52],[StrArray+56],[StrArray+60],[StrArray+64],[StrArray+68],[StrArray+72],[StrArray+76]
    call ShowArray

    call FillRandom
    debugmsg "1 million random integers = %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d ...",[IntArray+0],[IntArray+4],[IntArray+8],[IntArray+12],[IntArray+16],[IntArray+20],[IntArray+24],[IntArray+28],[IntArray+32],[IntArray+36],[IntArray+40],[IntArray+44],[IntArray+48],[IntArray+52],[IntArray+56],[IntArray+60],[IntArray+64],[IntArray+68],[IntArray+72],[IntArray+76]
    call ShowArray
    api CombOrder, IntArray,IntArraySize,CmpLongSD,0 ;EscCb
    debugmsg "1 million sorted integers = %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d ...",[IntArray+0],[IntArray+4],[IntArray+8],[IntArray+12],[IntArray+16],[IntArray+20],[IntArray+24],[IntArray+28],[IntArray+32],[IntArray+36],[IntArray+40],[IntArray+44],[IntArray+48],[IntArray+52],[IntArray+56],[IntArray+60],[IntArray+64],[IntArray+68],[IntArray+72],[IntArray+76]
    call ShowArray

    debugmsg "random floats = %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f",[FloatArray+0],[FloatArray+4],[FloatArray+8],[FloatArray+12],[FloatArray+16],[FloatArray+20],[FloatArray+24],[FloatArray+28],[FloatArray+32],[FloatArray+36],[FloatArray+40],[FloatArray+44],[FloatArray+48],[FloatArray+52],[FloatArray+56],[FloatArray+60],[FloatArray+64],[FloatArray+68],[FloatArray+72],[FloatArray+76]
    call ShowArray
    api CombOrder, FloatArray,FloatArraySize,CmpSngA,0 ;EscCb
    debugmsg "sorted floats = %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f",[FloatArray+0],[FloatArray+4],[FloatArray+8],[FloatArray+12],[FloatArray+16],[FloatArray+20],[FloatArray+24],[FloatArray+28],[FloatArray+32],[FloatArray+36],[FloatArray+40],[FloatArray+44],[FloatArray+48],[FloatArray+52],[FloatArray+56],[FloatArray+60],[FloatArray+64],[FloatArray+68],[FloatArray+72],[FloatArray+76]
    call ShowArray
%else

    debugmsg ValueFormatStr,[StrArray+0],[IntArray+0],[StrArray+4],[IntArray+4],[StrArray+8],[IntArray+8],[StrArray+12],[IntArray+12],[StrArray+16],[IntArray+16],[StrArray+20],[IntArray+20],[StrArray+24],[IntArray+24],[StrArray+28],[IntArray+28],[StrArray+32],[IntArray+32],[StrArray+36],[IntArray+36]
    call ShowArray
    api CombOrderX, 3,2,ArraySize,EscCb, StrArray,CmpStrAA, IntArray,CmpLongSA, FloatArray, CmpSngA
    ;api CombOrderX, 3,2,ArraySize,EscCb, IntArray,CmpLongSA, StrArray,CmpStrAA, FloatArray, CmpSngA
    debugmsg ValueFormatStr,[StrArray+0],[IntArray+0],[StrArray+4],[IntArray+4],[StrArray+8],[IntArray+8],[StrArray+12],[IntArray+12],[StrArray+16],[IntArray+16],[StrArray+20],[IntArray+20],[StrArray+24],[IntArray+24],[StrArray+28],[IntArray+28],[StrArray+32],[IntArray+32],[StrArray+36],[IntArray+36]
    call ShowArray

[section text]
ValueFormatStr: db "values:",13,"%s",9,"%d",13,"%s",9,"%d",13,"%s",9,"%d",13,"%s",9,"%d",13,"%s",9,"%d",13,"%s",9,"%d",13,"%s",9,"%d",13,"%s",9,"%d",13,"%s",9,"%d",13,"%s",9,"%d",13,0
[section code]
%endif

    debugmsg "program stack=%x",esp
    api ExitProcess, 0


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FillRandom:
;   R1, R2, R3, and R4 are 32-bit unsigned integers
;   R1 is the current random number, R2-R4 are the 2nd through 4th oldest
;   BYTE Random(DWORD seed=0){
;     static BYTE R1,R2,R3,R4;
;     if(seed != 0){
;       R1=seed>>24; R2=seed>>16; R3=seed>>8; R4=seed;
;     }
;     R4=R3; R3=R2; R2=R1;
;     if(R2>R3)
;       R1=R3+R4;
;     else
;       R1=R2+R4;
;     return R1;
;   }


%if 0 ;for bytes
    mov ecx,0D9C3h              ; set initial seed values
    mov al,52h

.Next:
    mov dl,ch                   ; R4=R3
    mov ch,cl                   ; R3=R2
    mov cl,al                   ; R2=R1

    mov al,dl                   ; R1 = R4 + (R3<=R2 ? R3 : R2)
    cmp ch,cl
    jbe .Less
    add al,cl                   ; +R2
    jmp short .EndRng
.Less:
    add al,ch                   ; +R3
.EndRng:

    mov [edi],eax
    add edi,byte 4
    dec esi
    jg .Next
    ret
%endif

%if 0
; As stand alone function...
; Call this somewhere before calling function:
    mov dword [.R1],082775212h          ; set initial seed values
    mov dword [.R2],03914AC5Fh
    mov dword [.R3],0B460D9C3h

RandomNum:
    mov ebx,[.R1]              ; R4=R3
    mov ecx,[.R2]              ; R3=R2
    mov edx,[.R3]              ; R2=R1

    mov eax,edx                 ; R1 = R4 + (R3<=R2 ? R3 : R2)
    cmp ecx,ebx
    jbe .Less
    add eax,ebx                 ; +R2
    jmp short .EndRng
.Less:
    add eax,ecx                 ; +R3
.EndRng:

    mov [.R1],eax              ; store R1 for next call
    mov [.R2],ebx              ; ...
    mov [.R3],edx              ; ...
    ret
%endif
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ShowArray:
    api MessageBox, 0, SendDebugMsg.FormatBuffer, ProgTitle, MB_ICONINFORMATION|MB_SETFOREGROUND|MB_TOPMOST
    ret


;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
EscCb:
%ifdef MultiSort
    debugmsg ValueFormatStr,[StrArray+0],[IntArray+0],[StrArray+4],[IntArray+4],[StrArray+8],[IntArray+8],[StrArray+12],[IntArray+12],[StrArray+16],[IntArray+16],[StrArray+20],[IntArray+20],[StrArray+24],[IntArray+24],[StrArray+28],[IntArray+28],[StrArray+32],[IntArray+32],[StrArray+36],[IntArray+36]
%endif
    api MessageBox, HWND_DESKTOP,SendDebugMsg.FormatBuffer,ProgTitle, MB_OKCANCEL|MB_SETFOREGROUND|MB_TOPMOST
    dec eax
    ; return zero (no abort) if ok, true if cancel
    ret

section text
InsideEscape: db "Inside escape procedure",0
