:: Compile Windows PE using GoLink
:: Source into Win32
:: Link object file into PE
@ECHO OFF

::ECHO Compiling into Win32 COFF with Nasm...
ECHO \SRC\NASMW.EXE -fwin32 %1.ASM -o \TEMP\TEMP.OBJ -w+orphan-labels -dWinVer %2 %3 %4 %5 %6 %7 %8 %9
\SRC\NASMW.EXE -fwin32 %1.ASM -o \TEMP\TEMP.OBJ -w+orphan-labels -dWinVer %2 %3 %4 %5 %6 %7 %8 %9
IF ERRORLEVEL 1 GOTO End

SET GRFFILE=
IF EXIST %1.GRF SET GRFFILE=@%1.GRF

IF x%2x==x-dConVerx GOTO ConVer
\SRC\GOLINK\GOLINK.EXE \TEMP\TEMP.OBJ \SRC\WIN\WINIMP.LIB /entry Main %GRFFILE%
GOTO End
:ConVer
\SRC\GOLINK\GOLINK.EXE /console \TEMP\TEMP.OBJ \SRC\WIN\WINIMP.LIB /entry Main %GRFFILE%
:End
