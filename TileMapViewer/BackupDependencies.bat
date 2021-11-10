@set COMPILER_BIN_PATH=\src\bin
xcopy /d %COMPILER_BIN_PATH%\nasmw.exe backup\tools\
xcopy /d %COMPILER_BIN_PATH%\rc.exe backup\tools\
xcopy /d %COMPILER_BIN_PATH%\rcdll.dll backup\tools\
xcopy /d %COMPILER_BIN_PATH%\alink.exe backup\tools\
xcopy /d %COMPILER_BIN_PATH%\yasm-1.3.0-win32.exe backup\tools\
xcopy /d %COMPILER_BIN_PATH%\STUBIT.EXE backup\tools\
xcopy /d %COMPILER_BIN_PATH%\msvcr100.dll backup\tools\

xcopy /d /s ..\WinDOS\* backup\WinDOS\
xcopy /d /s ..\WinNASM\* backup\WinNASM\
