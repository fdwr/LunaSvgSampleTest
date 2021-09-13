@echo off
setlocal

set exepath=%OBJECT_ROOT%\testsrc\windowstest\DGT\Text\Samples\DPad\App\obj%BUILD_ALT_DIR%

if "%build.arch%" == "x86" (
    set exepath=%exepath%\i386
) else if "%build.arch%" == "amd64" (
    set exepath=%exepath%\amd64
) else (
    echo Run supports only x86 and amd64 architectures at the moment.
    echo If you know how to obtain objchk\i386|amd64 string using Razzle environment variables,
    echo please feel free to add this support.
)

set exename=%exepath%\DPad.exe
if not exist %exename% (
    build
)

if __%1__==__explorer__ (
    start %exepath%
) else if __%1__==__cd__ (
    endlocal
    cd /D %exepath%
) else (
    start %exename% %1 %2 %3 %4 %5 %6 %7 %8 %9
)
:End