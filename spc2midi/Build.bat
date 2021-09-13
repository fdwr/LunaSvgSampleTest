@ECHO OFF
:: Compile source into Win32
:: Link object file and resources into PE

SETLOCAL
PATH %path%;\src\bin

ECHO Compiling into Win32 COFF with Nasm... (with resources)
NASMW.EXE -fwin32 SPC2MIDI.ASM -o %TEMP%\TEMP.OBJ -w+orphan-labels -dWinVer -d_NOMSLINK -dGuiVer -iWIN\ -iGUI\ %1 %2 %3 %4 %5 %6 %7 %8 %9
IF ERRORLEVEL 1 GOTO End

SET RSPFILE=
IF EXIST SPC2MIDI.RSP SET RSPFILE=@SPC2MIDI.RSP

ALINK.EXE -oPE %TEMP%\TEMP.OBJ WIN\WINIMP.LIB SPC2MIDI.RES -o SPC2MIDI.EXE %RSPFILE% -entry Main
:End
