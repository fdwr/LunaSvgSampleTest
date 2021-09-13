:: Compile DOS Protected Mode PE
:: Source into Win32 COFF
:: Link object file into PE
:: Add WDOSX PMODE extender
:: Delete unnecessary files
@echo off
echo Compiling into Win32 COFF with Nasm...

\src\bin\nasmw.exe -f win32 %1.asm -o %TEMP%\temp.cof -w+orphan-labels -dDosVer %2 %3 %4 %5 %6 %7 %8 %9
if errorlevel 1 goto End

set RspFile=
if exist %1.arf set RspFile=@%1.arf
\src\bin\alink.exe %TEMP%\temp.cof -oPE -o %1.exe %RspFile% -entry Main -subsys con
if errorlevel 1 goto End

\src\bin\stubit.exe -nowfse %1.exe

:: Delete the BAK file Stubit created.
if exist %1.bak del %1.bak
:End
