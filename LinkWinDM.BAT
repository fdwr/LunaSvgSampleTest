:: Link object files/resources into PE using Digital Mars C++
:: Resources stated on command line and in RSPFILE
@ECHO OFF

SET RSPFILE=
IF EXIST %1.MRF SET RSPFILE=@%1.DRF

::PUSHD \TEMP
ECHO \SRCEX\DM\BIN\DMC.EXE -o %1.EXE -l/SUBSYSTEM:WINDOWS:4.00 %RSPFILE% %2 %3 %4 %5 %6 %7 %8 %9
\SRCEX\DM\BIN\DMC.EXE -o %1.EXE -l/SUBSYSTEM:WINDOWS:4.00 %RSPFILE% %2 %3 %4 %5 %6 %7 %8 %9
::POPD
