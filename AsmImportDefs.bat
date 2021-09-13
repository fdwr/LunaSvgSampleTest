::Compile import definitions
@echo off
@echo Compiling import references into library with Nasm...
::\src\bin\nasmw.exe -f obj %1.def -o %1.lib
\src\bin\nasmw.exe -f win32 %1.def -o %1.lib
