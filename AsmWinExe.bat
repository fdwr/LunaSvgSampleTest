:: Compile Windows PE
:: Source into Win32 COFF
:: Link object file into PE with resources if exist
@echo off
setlocal
set RSPFILE=
if exist %1.ARF set RSPFILE=@%1.ARF
set RESFILE=
if exist %1.RES set RESFILE=%1.RES
@echo on

::echo Compiling into Win32 COFF with Nasm...
\src\bin\nasmw.exe -fwin32 %1.asm -o %TEMP%\TEMP.OBJ -w+orphan-labels -dWinVer -d_NOMSLINK %2 %3 %4 %5 %6 %7 %8 %9 -i\src\win\ -i\src\WinNasm\
@if errorlevel 1 goto End
@echo.

\src\bin\alink.exe -oPE %TEMP%\TEMP.OBJ \SRC\WINNASM\WINIMP.LIB %RESFILE% -o %1.exe -subsys gui %RSPFILE% -entry Main
::ALINK.EXE -oPE %TEMP%\TEMP.OBJ \SRC\WINNASM\WINIMP.LIB %RESFILE% -o %1.exe -subsys con %RSPFILE% -entry Main
@if errorlevel 1 goto End

:End
