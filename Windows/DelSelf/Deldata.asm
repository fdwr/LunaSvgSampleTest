; This file simply includes the assembly code and exports a few variables
; for the sake of object linking.
;
; The actual asm is in Uninstal.asm

global _UnsCodeStart
global _UnsCodeSize
global _UnsCodePtr
global _UnsErrorCode
global _UnsErrorString
global _UnsKernelModule
global _UnsGetProcAddress

section .data
_UnsCodeStart:
incbin "UNINSTAL.BIN"
_UnsKernelModule equ $-8
_UnsGetProcAddress equ $-4
_UnsCodeSize: dd $-_UnsCodeStart

_UnsCodePtr:  dd 0