set COMPILER_BIN_PATH=\src\bin

%COMPILER_BIN_PATH%\nasmw.exe -f win32 tmv.asm -o tmv.cof -dDosVer
%COMPILER_BIN_PATH%\alink.exe -oPE tmv.cof -entry Main -subsys con
%COMPILER_BIN_PATH%\stubit.exe -nowfse tmv.exe
