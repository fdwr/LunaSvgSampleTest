:: Link object files/resources into PE using GoLink
:: Resources stated on command line and in RSPFILE
@echo off
setlocal
set RSPFILE=
if exist %1.GRF set RSPFILE=@%1.GRF
@echo on
\SRCEX\GOLINK\GOLINK.EXE /entry Main /fo %1.EXE %RSPFILE% %2 %3 %4 %5 %6 %7 %8 %9
