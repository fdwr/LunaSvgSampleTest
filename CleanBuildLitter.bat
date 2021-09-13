:: Clean leftover temp files (OBJ,PCH,NCB)
@ECHO OFF

::ECHO Deleting temporary OBJ, PCH, NCB files
DEL /S *.PCH *.OBJ *.NCB *.PDB *.SBR *.BSC *.APS
::DEL /S *.PCH *.OBJ *.NCB *.PDB *.SBR *.BSC *.APS *.RES
