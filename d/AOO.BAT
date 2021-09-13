:: Asm Source into OMF using NASM
@ECHO OFF

::ECHO Compiling into Win32 COFF with Nasm...
ECHO \SRC\NASMW.EXE %1.ASM -o %1.obj -fobj -w+orphan-labels %2 %3 %4 %5 %6 %7 %8 %9 -i\SRC\WIN\
\SRC\NASMW.EXE %1.ASM -o %1.obj -fobj -w+orphan-labels %2 %3 %4 %5 %6 %7 %8 %9 -i\SRC\WIN\