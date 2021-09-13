:: Compile Windows DLL
@echo off

::ECHO Compiling program to Win32 COFF with Nasm...
echo \src\nasmw.exe -fwin32 %1.asm -o \temp\temp.cof -w+orphan-labels -dWinVer %2 %3 %4 %5 %6 %7 %8 %9
\src\nasmw.exe -fwin32 %1.asm -o \temp\temp.cof -w+orphan-labels -dWinVer %2 %3 %4 %5 %6 %7 %8 %9
if errorlevel 1 goto End
echo.

set RspFile=
if exist %1.arf set RspFile=@%1.arf
set ResFile=
if exist %1.res set ResFile=%1.res

echo \src\alink.exe -oPE \temp\temp.cof %1.lib \src\winnasm\winimp.lib %ResFile% -o %1.dll -dll -subsys gui -entry DllMain %RspFile%
\src\alink.exe -oPE \temp\temp.cof %1.lib \src\winnasm\winimp.lib %ResFile% -o %1.dll -dll -entry DllMain %RspFile%
::\src\win\tacknull.com %1.dll
if errorlevel 1 goto End

echo.
\src\md5 -n %1.dll
:End
