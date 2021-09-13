#define UseTextConsole
%include "wininc.asm"

[section .text]
global Main
Main:
	api GetCommandLine
	mov esi,eax
	api GetStdHandle, STD_OUTPUT_HANDLE
	mov ebx,eax

	api lstrlen, esi
	api WriteFile, ebx,esi, eax,esp,0

	mov eax,ecx
	api GetStdHandle, STD_INPUT_HANDLE
	push eax // dummy for read length
	mov ecx,esp
	api ReadFile, eax, ecx, 1, ecx, 0
	pop eax

   	ret

	;WriteFile

	;HANDLE  hFile,	// handle of file to write to
	;LPCVOID  lpBuffer,	// address of data to write to file
	;DWORD  nNumberOfBytesToWrite,	// number of bytes to write
	;LPDWORD  lpNumberOfBytesWritten,	// address of number of bytes written
	;LPOVERLAPPED  lpOverlapped 	// addr. of structure needed for overlapped I/O

