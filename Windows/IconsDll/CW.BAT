@ECHO OFF
:: Compile source into Win32
:: Link object file into PE with resources if exist

ECHO Compiling into Win32 COFF with Nasm...
\SRC\NASMP.EXE -fwin32 %1.ASM -o \TEMP\TEMP.COF -w+orphan-labels -dWinVer %2 %3 %4 %5 %6 %7 %8 %9
IF ERRORLEVEL 1 GOTO End

SET RSPFILE=
IF EXIST %1.RSP SET RSPFILE=@%1.RSP
SET RESFILE=
IF EXIST %1.RES SET RESFILE=%1.RES

ECHO \SRC\ALINK.EXE -oPE \TEMP\TEMP.COF \SRC\WIN\WINIMP.LIB %RESFILE% -o %1.EXE %RSPFILE% -entry Main
::\SRC\ALINK.EXE -oPE \TEMP\TEMP.COF \SRC\WIN\WINIMP.LIB %RESFILE% -o %1.EXE %RSPFILE% -entry Main
\SRC\ALINK.EXE -dll -oPE \TEMP\TEMP.COF \SRC\WIN\WINIMP.LIB %RESFILE% -o %1.DLL %RSPFILE%
IF ERRORLEVEL 1 GOTO End

\SRC\MD5 -n %1.DLL
:End
