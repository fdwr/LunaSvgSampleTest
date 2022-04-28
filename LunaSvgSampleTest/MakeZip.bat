@echo off
setlocal
set oldFileNames=build\x86-release\LunaSvgTest.pikensoft.*.zip
set  newFileName=build\x86-release\LunaSvgTest.pikensoft.%date%.zip

echo Deleting any old files: %oldFileNames%
del %oldFileNames% 2> nul
echo Compressing new file: %newFileName%
set command=\programs\file\7-Zip\7zG.exe a -tzip -mcu=on -mx=9 %newFileName% ./Readme.md ./License.txt .\build\x86-release\LunaSvgTest.exe "svgs\iconpacks.net maneki-neko-9048 by Yusuf Onaldi.*" "svgs\reshot.com thedighital icon-scottish-female-ENH4GZFT72.*" "svgs\icons8.com fluency home.svg" "svgs\icons8.com fluency picture.svg" "svgs\icons8.com fluency scroll.svg" "svgs\icons8.com fluency popular set.url" "svgs\*license.txt"
echo %command%
%command%
