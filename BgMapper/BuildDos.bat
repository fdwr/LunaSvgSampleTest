@echo off
echo Compiling BgMapper with Nasm, ALink, and WDOSX Stubit...

cd src
..\tools\nasmw.exe -f win32 bgmapper.asm -o ..\bgmapper.cof -dDosVer
cd ..
tools\alink.exe -oPE bgmapper.cof -entry Main -subsys con
tools\stubit.exe -nowfse bgmapper.exe

del bgmapper.bak 2> nul
del bgmapper.cof 2> nul
