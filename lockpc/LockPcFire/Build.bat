\src\bin\nasmw.exe -fwin32 FireDemo.asm -o FireDemo.cof -dWinVer
\src\bin\gorc.exe /r FireDemo.rc
\src\bin\alink.exe -oPE FireDemo.cof WinImp.lib FireDemo.res -o FireDemo.exe -entry Main
del FireDemo.cof
