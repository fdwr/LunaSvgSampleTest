:: This batch file only works for me, given my unique folder structure.
:: Refresh any tooling dependencies with a local copy for sharing the whole directory.
@set COMPILER_BIN_PATH=..\bin
xcopy /d %COMPILER_BIN_PATH%\nasmw.exe tools\
xcopy /d %COMPILER_BIN_PATH%\rc.exe tools\
xcopy /d %COMPILER_BIN_PATH%\rcdll.dll tools\
xcopy /d %COMPILER_BIN_PATH%\alink.exe tools\
xcopy /d %COMPILER_BIN_PATH%\yasm-1.3.0-win32.exe tools\
xcopy /d %COMPILER_BIN_PATH%\STUBIT.EXE tools\
xcopy /d %COMPILER_BIN_PATH%\msvcr100.dll tools\

xcopy /d /s ..\WinDOS\* src\WinDOS\
xcopy /d /s ..\WinNASM\* src\WinNASM\
