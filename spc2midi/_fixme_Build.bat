::Program versions zipper batch
@echo off
if not '%1'=='' goto ZipIt

echo This batch file will not work for you because all the paths on your
echo system are undoubtedly different, but you can use it as a compilation
echo example.
echo ÿ
echo Usage:   pz #
echo Example: pz 183
echo ÿ
pause

goto End

:ZipIt

::Compile Windows console version
::\src\gorc\gorc.exe /d ConVer /r SPC2MIDI.RC
\src\rc.exe /d ConVer /d PROGVER=%1 /d PROGVERSTR=\".%1\" /r SPC2MIDI.RC
\SRC\NASMP.EXE -fwin32 SPC2MIDI.ASM -o \TEMP\TEMP.COF -dWinVer -dConVer -w+orphan-labels
IF ERRORLEVEL 1 GOTO End
\SRC\ALINK.EXE -oPE -subsys con -o spc2midi_wc.exe \TEMP\TEMP.COF \SRC\WIN\WINIMP.LIB SPC2MIDI.RES -entry Main
IF ERRORLEVEL 1 GOTO End

::Compile Windows GUI version
\src\rc.exe /d PROGVER=%1 /d PROGVERSTR=\".%1\" /r SPC2MIDI.RC
\SRC\NASMP.EXE -fwin32 SPC2MIDI.ASM -o \TEMP\TEMP.COF -dWinVer -dGuiVer -w+orphan-labels
IF ERRORLEVEL 1 GOTO End
\SRC\ALINK.EXE -oPE -subsys gui -o spc2midi_wg.exe \TEMP\TEMP.COF \SRC\WIN\WINIMP.LIB SPC2MIDI.RES -entry Main
IF ERRORLEVEL 1 GOTO End

::Compile DOS console version
\SRC\NASMP.EXE -f win32 SPC2MIDI.ASM -o \TEMP\TEMP.COF -dDosVer -dConVer -w+orphan-labels
IF ERRORLEVEL 1 GOTO End
\SRC\ALINK.EXE -oPE -subsys con -o spc2midi_dc.exe \TEMP\TEMP.COF -entry Main
IF ERRORLEVEL 1 GOTO End
\SRC\STUBIT.EXE -nowfse SPC2MIDC.EXE
IF ERRORLEVEL 1 GOTO End
IF EXIST SPC2MIDC.BAK DEL SPC2MIDC.BAK

::Compile DOS GUI version
\SRC\NASMP.EXE -f win32 SPC2MIDI.ASM -o \TEMP\TEMP.COF -dDosVer -dGuiVer -w+orphan-labels
IF ERRORLEVEL 1 GOTO End
\SRC\ALINK.EXE -oPE -subsys con -o spc2midi_dg.exe \TEMP\TEMP.COF -entry Main
IF ERRORLEVEL 1 GOTO End
\SRC\STUBIT.EXE -nowfse SPC2MIDD.EXE
IF ERRORLEVEL 1 GOTO End
IF EXIST SPC2MIDD.BAK DEL SPC2MIDD.BAK

rem \src\wraptext.exe spc2midi
rem pkzip.exe -3 -exx -f spc2midi.zip
rem copy /y spc2midi.zip spc2midi_%1_pikensoft.zip

:End
