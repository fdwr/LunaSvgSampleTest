bits 32

[section .text code use32]
[section .data data use32]
[section .string data use32]
[section .bss bss use32]

%define UseWindowStyles
%include "\src\common\macros32.inc"
%include "\src\common\winnasm.inc"


section .text

csym SomeFunc
	push ebx
	push esi
	push edi

	api MessageBox, NULL, "This is assembly code", "Title", MB_OK
	extern _PrintDMessage
	call _PrintDMessage

	pop edi
	pop esi
	pop ebx
	ret
