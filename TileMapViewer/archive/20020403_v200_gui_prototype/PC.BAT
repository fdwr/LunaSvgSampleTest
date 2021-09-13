@echo off
echo Compiling Tilemap viewer into executable
echo Nasm...
c:\dw\src\nasmw.exe -f rdf tmv.asm -o tmv.exe -w+orphan-labels
if errorlevel 1 goto End
echo Wdosx...
c:\dw\src\wdosx\bin\stubit.exe -nowfse tmv.exe
echo Done!
:End
