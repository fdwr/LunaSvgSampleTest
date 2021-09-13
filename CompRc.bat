:: Compile Resource file
@ECHO OFF
ECHO Compiling RC into resource file...

::\SRCEX\GORC\GORC.EXE /r %2 %3 %4 %5 %6 %7 %8 %9 %1.RC
@echo on
\SRC\BIN\GORC.EXE /r %2 %3 %4 %5 %6 %7 %8 %9 %1.RC
@echo off

::\SRC\RC.EXE %2 %3 %4 %5 %6 %7 %8 %9 %1.RC
