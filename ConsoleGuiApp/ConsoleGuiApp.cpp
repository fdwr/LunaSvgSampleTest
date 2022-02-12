/*
https://www.tillett.info/2013/05/13/how-to-create-a-windows-program-that-works-as-both-as-a-gui-and-console-application/

Copyright (c) 2013, 2016 Daniel Tillett
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#define _CRT_SECURE_NO_WARNINGS
#define WINVER 0x0501 // Allow use of features specific to Windows XP or later.
#define _WIN32_WINNT 0x0501
#define WIN32_LEAN_AND_MEAN
#include "windows.h"
#include "io.h"
#include "fcntl.h"
#include "stdio.h"
#include "stdlib.h"
#pragma comment(lib, "User32.lib")

// Attach output of application to parent console
static BOOL attachOutputToConsole(void) {
HANDLE consoleHandleOut, consoleHandleError;

if (AttachConsole(ATTACH_PARENT_PROCESS)) {
// Redirect unbuffered STDOUT to the console
consoleHandleOut = GetStdHandle(STD_OUTPUT_HANDLE);
if (consoleHandleOut != INVALID_HANDLE_VALUE) {
freopen("CONOUT$", "w", stdout);
setvbuf(stdout, NULL, _IONBF, 0);
}
else {
return FALSE;
}
// Redirect unbuffered STDERR to the console
consoleHandleError = GetStdHandle(STD_ERROR_HANDLE);
if (consoleHandleError != INVALID_HANDLE_VALUE) {
freopen("CONOUT$", "w", stderr);
setvbuf(stderr, NULL, _IONBF, 0);
}
else {
return FALSE;
}
return TRUE;
}
//Not a console application
return FALSE;
}

// Send the "enter" to the console to release the command prompt
// on the parent console
static void sendEnterKey(void) {
INPUT ip;
// Set up a generic keyboard event.
ip.type = INPUT_KEYBOARD;
ip.ki.wScan = 0; // hardware scan code for key
ip.ki.time = 0;
ip.ki.dwExtraInfo = 0;

// Send the "Enter" key
ip.ki.wVk = 0x0D; // virtual-key code for the "Enter" key
ip.ki.dwFlags = 0; // 0 for key press
SendInput(1, &ip, sizeof(INPUT));

// Release the "Enter" key
ip.ki.dwFlags = KEYEVENTF_KEYUP; // KEYEVENTF_KEYUP for key release
SendInput(1, &ip, sizeof(INPUT));
}

int WINAPI WinMain(HINSTANCE hInstance,
HINSTANCE hPrevInstance,
PSTR lpCmdLine,
INT nCmdShow) {
int argc = __argc;
char **argv = __argv;
UNREFERENCED_PARAMETER(hInstance);
UNREFERENCED_PARAMETER(hPrevInstance);
UNREFERENCED_PARAMETER(lpCmdLine);
UNREFERENCED_PARAMETER(nCmdShow);
BOOL console;
int i;

//Is the program running as console or GUI application
console = attachOutputToConsole();

if (console) {
// Print to stdout
printf("\nProgram running as console application\n");
for (i = 0; i < argc; i++) {
printf("argv[%d] %s\n", i, argv[i]);
}

// Print to stderr
fprintf(stderr, "Output to stderr\n");
}
else {
    MessageBox(
        NULL,
        L"Program running as Windows GUI application",
        L"Windows GUI Application",
        MB_OK | MB_SETFOREGROUND
    );
}

// Send "enter" to release application from the console
// This is a hack, but if not used the console doesn't know the application has
// returned. The "enter" key only sent if the console window is in focus.
if (console && (GetConsoleWindow() == GetForegroundWindow())){
sendEnterKey();
}
return 0;
}