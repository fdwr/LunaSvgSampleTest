::setlocal

::@set TOOLS_PATH=backup\tools
::@set INCLUDE_PATH=backup
@set TOOLS_PATH=\src\bin
@set INCLUDE_PATH=..

@echo TOOLS_PATH=%TOOLS_PATH%
@echo INCLUDE_PATH=%INCLUDE_PATH%

%TOOLS_PATH%\nasmw.exe -f win32 -w+orphan-labels -d WinVer -d ALINK -I%INCLUDE_PATH%\WinDOS\ -I%INCLUDE_PATH%\WinNasm\ tmv.asm -o %temp%\TmvWin.cof
::%TOOLS_PATH%\yasm-1.3.0-win32.exe -f win32 -g cv8 -w+orphan-labels -d WinVer -d ALINK -I%INCLUDE_PATH%\WinDOS\ -I%INCLUDE_PATH%\WinNasm\ tmv.asm -o %temp%\TmvWin.cof

@if errorlevel 1 goto End
%TOOLS_PATH%\rc.exe /r TMV.RC
@if errorlevel 1 goto End
%TOOLS_PATH%\alink.exe -oPE -o TmvWin.exe %temp%\TmvWin.cof %INCLUDE_PATH%\WinNasm\WinImp.lib Tmv.res -entry Main -subsys win
@:End