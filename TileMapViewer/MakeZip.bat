setlocal
set filename=tilemapview-%1.%date%@pikensoft.zip
del %filename% > nul
\programs\file\7-Zip\7zG.exe a -tzip -mcu=on -mx=9 %filename% ./doc/TilemapViewer.txt TmvWin.exe TmvDos.exe
