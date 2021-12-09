@ECHO OFF
ECHO Compiling BgMapper with Nasm, ALink, and WDOSX Stubit...

set COMPILER_BIN_PATH=\src\bin

%COMPILER_BIN_PATH%\nasmw.exe -f win32 bgmapper.asm -o bgmapper.cof -dDosVer
%COMPILER_BIN_PATH%\alink.exe -oPE bgmapper.cof -entry Main -subsys con
%COMPILER_BIN_PATH%\stubit.exe -nowfse bgmapper.exe

goto End

:End
