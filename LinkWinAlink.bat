:: Link object files/resources into PE using Alink
:: Resources stated on command line and in RSPFILE
@echo off
setlocal
set RSPFILE=
if exist %1.ARF set RSPFILE=@%1.ARF
@echo on

\src\alink.exe \src\win\winimp.lib -oPE -o %1.exe -subsys gui -entry Main %RSPFILE% %2 %3 %4 %5 %6 %7 %8 %9
