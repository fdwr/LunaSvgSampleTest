@setlocal

@set SOURCE_PATH=.\src
@set INCLUDE_PATH=.
@set TOOLS_PATH=..\tools
@set OUTPUT_PATH=..

@echo SOURCE_PATH=%SOURCE_PATH%
@echo INCLUDE_PATH=%INCLUDE_PATH%
@echo TOOLS_PATH=%TOOLS_PATH%
@echo OUTPUT_PATH=%OUTPUT_PATH%

if "%TEMP%"=="" (
  set TEMP=.
)

:: Link and prepend WDosX DPMI extender.
@cd %SOURCE_PATH%

%TOOLS_PATH%\nasmw.exe -f win32 -w+orphan-labels tmv.asm -o %TEMP%\TmvDos.cof -dDosVer -I%INCLUDE_PATH%\windos\
%TOOLS_PATH%\alink.exe -oPE -o TmvDos.exe %TEMP%\TmvDos.cof -entry Main -subsys con
%TOOLS_PATH%\stubit.exe -nowfse TmvDos.exe

@cd ..

@del TmvDos.cof 2> nul
:: Stubit always make a backup file. So delete the clutter.
@del TmvDos.bak 2> nul
:NoBackupFile
