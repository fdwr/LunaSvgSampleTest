@echo off
rem Used to compile an ASM into an ASC for Qbasic programs, 4-98, FDR

if "%1"=="" goto WrongParameters

echo Starting Netwide Assembler
echo ÿ
echo Input file: %1.asm
echo Output file: %1.asc
echo ÿ
echo Parameter line is: -f bin %1.asm -o %1.com
c:\dw\nasm\nasm.exe -f bin .\%1.asm -o .\%1.com
echo ÿ
goto CompileEnd

:WrongParameters
echo This batch program needs a filename parameter to work
echo ÿ
echo Syntax: COMPILE (input\output name)
echo ÿ
echo name is the name of an 'ASM' text file to be read by the assembler (NASM)
echo   do not include the directory before the filename or 'ASM' extension after it
echo name is also used for the output 'ASC' file (ASsembly Code)
echo   again, do not include the extension since it is automatically added
echo ÿ
echo Examples: COMPILE scrntest         looks for scrntest.asm, writes scrntest.asc
echo           COMPILE readmem          looks for readmem.asm, writes readmem.asc
echo ÿ

:CompileEnd
