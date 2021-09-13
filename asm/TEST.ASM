BITS 32				;flat addressing is great!
GLOBAL _WDOSXStart		;great (free!) extender
GLOBAL _Main
GLOBAL Main
GLOBAL _WinMain
GLOBAL WinMain

	mov eax,.hwnd@
	mov eax,.msg@
	mov eax,.wparam@
	mov eax,.top@
	mov eax,.left@
	mov eax,.height@


%include "macros32.inc"

SECTION .text
_WDOSXStart:
_WinMain:
WinMain:
_Main:
Main:

%if 1
%error _hwnd = .hwnd
%error _msg = .msg
%error _wparam = .wparam
%error _top = .top
%error _left = .left
%error _height = .height
%error ---------------
%error

params ebp+20
param hwnd,4
param msg,4
param wparam,4

locals ebp
;locals esp+locals_size
local top,4
local left,4
local height,4

%error _hwnd = .hwnd
%error _msg = .msg
%error _wparam = .wparam
%error _top = .top
%error _left = .left
%error _height = .height
%error ---------------
%error _hwnd@ = .hwnd@
%error _msg@ = .msg@
%error _wparam@ = .wparam@
%error _top@ = .top@
%error _left@ = .left@
%error _height@ = .height@
%error ---------------
%error

localssundef

%error _hwnd = .hwnd
%error _msg = .msg
%error _wparam = .wparam
%error _top = .top
%error _left = .left
%error _height = .height

%elif 0

%error params_size

	.alabel:
	.blabel:
	..@clabel:
	major2..dlabel:
	major2.elabel.flabel:
%endif

	mov eax,.hwnd@
	mov eax,.msg@
	mov eax,.wparam@
	mov eax,.top@
	mov eax,.left@
	mov eax,.height@

	ret
	
;%error "not compiled"
