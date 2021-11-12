setlocal
set filename=TilemapViewer-###.%date%@pikensoft.zip
del %filename%
D:\programs\file\7-Zip\7zG.exe a -tzip -mcu=on -mx=9 %filename% Tmv.txt TmvWin.exe TmvDos.exe
