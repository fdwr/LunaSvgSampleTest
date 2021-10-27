@echo off
setlocal

set exedir=%OBJECT_ROOT%\testsrc\windowstest\dgt\text\tools\fontstringperf\main\%_BuildAlt%
set exepath=%exedir%\FontStringPerf.exe

if not exist %exepath% (
    build
)

if __%1__==__explorer__ (
    start %exedir%
) else if __%1__==__cd__ (
    endlocal
    cd /D %exedir%
) else (
    echo Exe: %exepath%
    start %exepath% %1 %2 %3 %4 %5 %6 %7 %8 %9
)
:End
