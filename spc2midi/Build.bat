@echo off
:: Compile source into Win32
:: Link object file and resources into PE

setlocal
path %path%;\src\bin

set ErrorBuilding=0
echo Compiling into Win32 COFF with Nasm... (with resources)
pushd src
nasmw.exe -fwin32 Spc2Midi.asm -o temp.obj -w+orphan-labels -dWinVer -d_NOMSLINK -dGuiVer -iWIN\ -iGUI\ %1 %2 %3 %4 %5 %6 %7 %8 %9
IF ERRORLEVEL 1 set ErrorBuilding=1
popd

if ErrorBuilding goto End

set RSPFILE=
if exist SPC2MIDI.RSP set RSPFILE=@SPC2MIDI.RSP

ALink.exe -oPE src\temp.obj win\WinImp.lib Spc2Midi.res -o Spc2Midi.exe %RSPFILE% -entry Main
del temp.obj 2> nul
:End
