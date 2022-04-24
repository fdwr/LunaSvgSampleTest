::setlocal
::set fileName=build\x86-release\LunaSvgTest.pikensoft.%date%.zip
del build\x86-release\LunaSvgTest.pikensoft.*.zip 2> nul
\programs\file\7-Zip\7zG.exe a -tzip -mcu=on -mx=9 %filename% ./Readme.md ./License.txt .\build\x86-release\LunaSvgTest.exe "svgs\iconpacks.net maneki-neko-9048 by Yusuf Onaldi.*" "svgs\reshot.com thedighital icon-scottish-female-ENH4GZFT72.*"
