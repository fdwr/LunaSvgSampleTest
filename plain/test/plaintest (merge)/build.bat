@echo off
:: Compiled with:
:: nasm-0.98.38 (Netwide Assembler 2004-07-14)
:: dmd0137 (Digital Mars D 2005)
:: OPTLINK for Win32  Release 8.00.1 (Digital Mars 2004)
:: or ALINK

call :CompileAsm plain\PlainStyleData
if errorlevel 1 exit /b

call :CompileAsm pgfx\PgfxLL
if errorlevel 1 exit /b

call :CompileAsm pgfx\PgfxHL
if errorlevel 1 exit /b

call :CompileAsm pgfx\PgfxHL
if errorlevel 1 exit /b

call :CompileAsm pgfx\PgfxLayr
if errorlevel 1 exit /b

call :CompileD
if errorlevel 1 exit /b

call :LinkCode
if errorlevel 1 exit /b

goto:EOF

:CompileD
echo Compiling D code
p:\programs\code\dmd0137\bin\dmd.exe -c @BuildListD.rsp
goto:EOF

:CompileAsm
echo Compiling assembly
p:\programs\code\nasm\nasmw.exe %1.asm -o obj\%1.obj -fobj -D_WINDOWS -D_MSLINK -Iplain\ -Ipgfx\ -Icommon\
if errorlevel 1 exit /b
goto:EOF

:LinkCode
echo Linking code
::\srcex\golink\golink.exe -fo PlainTest.exe -entry Main obj\PlainTest.obj
::\srcex\alink\alink.exe -oPE -o PlainTest.exe -entry Main obj\*.obj obj\plain\*.obj obj\pgfx\*.obj
::p:\programs\code\dm\bin\link.exe -o PlainTest.exe -entry Main @BuildListLink.rsp
p:\programs\code\dm\bin\link.exe obj\*.obj obj\common\*.obj obj\plain\*.obj obj\pgfx\*.obj, PlainTest.exe, ,gdi32.lib "P:\programs\code\dmd\lib\phobos.lib", PlainTest.def, PlainTest.res
if errorlevel 1 exit /b
goto:EOF
