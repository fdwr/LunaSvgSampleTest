setlocal
set filename=\web\programs\tilemapview-%1.%date%@pikensoft.zip
del %filename% 2> nul
\programs\file\7-Zip\7zG.exe a -tzip -mcu=on -mx=9 %filename% ./doc/TilemapViewer.txt TmvWin.exe TmvDos.exe