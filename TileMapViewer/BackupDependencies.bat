@set COMPILER_BIN_PATH=\src\bin
xcopy /d %COMPILER_BIN_PATH%\nasmw.exe backup\tools\
xcopy /d %COMPILER_BIN_PATH%\rc.exe backup\tools\
xcopy /d %COMPILER_BIN_PATH%\alink.exe backup\tools\

xcopy /d /s ..\WinDOS\* backup\WinDOS\
xcopy /d /s ..\WinNASM\* backup\WinNASM\
