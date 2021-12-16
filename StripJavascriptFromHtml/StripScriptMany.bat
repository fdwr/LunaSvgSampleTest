@echo off
if "%1"=="" echo Usage: StripScriptMany *.html & goto End
for %%i in (%1) do StripScript.exe "%%~fi" "%%~fi"
:End