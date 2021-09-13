ECHO Compiling BgMapper with Nasm...
@ECHO OFF

set COMPILER_BIN_PATH=\src\bin

%COMPILER_BIN_PATH%\nasmw.exe -f win32 bgmapper.asm -o bgmapper.cof -dDosVer
%COMPILER_BIN_PATH%\alink.exe -oPE bgmapper.cof -entry Main -subsys con
%COMPILER_BIN_PATH%\stubit.exe -nowfse bgmapper.exe

goto End

REM Old code...
p:\programs\code\nasm\nasmw.exe -f rdf bgmapper.asm -o bgmapper.exe
IF ERRORLEVEL 1 GOTO End
ECHO Adding WDOSX extender...
p:\programs\code\wdosx\bin\stubit.exe -nowfse bgmapper.exe
:End
