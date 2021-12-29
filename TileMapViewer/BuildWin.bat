@setlocal

@set SOURCE_PATH=.\src
@set INCLUDE_PATH=.
@set TOOLS_PATH=..\tools
@set OUTPUT_PATH=..

@echo SOURCE_PATH=%SOURCE_PATH%
@echo INCLUDE_PATH=%INCLUDE_PATH%
@echo TOOLS_PATH=%TOOLS_PATH%
@echo OUTPUT_PATH=%OUTPUT_PATH%

@pushd %SOURCE_PATH%
@if errorlevel 1 goto End

::%TOOLS_PATH%\nasmw.exe -f win32 -w+orphan-labels -d WinVer -d ALINK -I%INCLUDE_PATH%\WinDOS\ -I%INCLUDE_PATH%\WinNasm\ tmv.asm -o %temp%\TmvWin.cof
%TOOLS_PATH%\yasm-1.3.0-win32.exe -f win32 -g cv8 -w+orphan-labels -d WinVer -d ALINK -I %INCLUDE_PATH%\WinDOS\ -I %INCLUDE_PATH%\WinNasm\ tmv.asm -o %temp%\TmvWin.cof
@if errorlevel 1 goto End

%TOOLS_PATH%\rc.exe /r Tmv.rc
@if errorlevel 1 goto End

%TOOLS_PATH%\alink.exe -oPE -o %OUTPUT_PATH%\TmvWin.exe %temp%\TmvWin.cof %INCLUDE_PATH%\WinNasm\WinImp.lib Tmv.res -entry Main -subsys win
@if errorlevel 1 goto End

@echo Build completed fine

@:End
@popd
