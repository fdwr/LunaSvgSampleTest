::  Assumes the following for %USERPROFILE%\.gitconfig
::
::  [diff]
::  	tool = winmerge
::  [difftool "winmerge"]
::  	cmd = \"d:\\programs\\file\\WinMerge\\WinMergeU.exe\" -u -r -wl \"$LOCAL\" \"$REMOTE\"
::  [merge]
::  	tool = winmerge
::  [mergetool]
::  	keepBackup = false
::  [mergetool "winmerge"]
::  	cmd = \"d:\\programs\\file\\WinMerge\\WinMergeU.exe\" -u -r -wl -dl Local -dr Remote \"$LOCAL\" \"$REMOTE\" \"$MERGED\"

@echo off
setlocal
echo git difftool --dir-diff %*
git difftool --dir-diff %*
