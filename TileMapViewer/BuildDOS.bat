@setlocal

@set TOOLS_PATH=\src\bin
@set INCLUDE_PATH=..
::@set TOOLS_PATH=backup\tools
::@set INCLUDE_PATH=backup

@echo TOOLS_PATH=%TOOLS_PATH%
@echo INCLUDE_PATH=%INCLUDE_PATH%

:: Link and prepend WDosX DPMI extender.
%TOOLS_PATH%\nasmw.exe -f win32 -w+orphan-labels tmv.asm -o %TEMP%\TmvDos.cof -dDosVer -I%INCLUDE_PATH%\windos\
%TOOLS_PATH%\alink.exe -oPE -o TmvDos.exe %TEMP%\TmvDos.cof -entry Main -subsys con
%TOOLS_PATH%\stubit.exe -nowfse TmvDos.exe

:: Stubit always make a backup file. So delete the clutter.
@if not exist TmvDos.bak goto NoBackupFile
@del TmvDos.bak
:NoBackupFile
