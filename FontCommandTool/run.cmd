@echo off
setlocal

set exesrc=%0\..
set exepath=%OBJECT_ROOT%\windows\core\text\devtest\FontCommandTool\%_BuildAlt%
set exename=%exepath%\FontCommandTool.exe

if not exist %exename% (
    pushd %exesrc%
    build
    popd
)

if __%1__==__explorer__ (
    start %exepath%
) else if __%1__==__cd__ (
    endlocal
    cd /D %exepath%
) else (
    echo %exename%
    %exename% %*
)
:End
