@echo off
setlocal

:: Move up a directory. Otherwise git complains:
:: "You need to run this command from the toplevel of the working tree."
pushd %~dp0\..

set command=git subtree push --prefix SpriteView https://github.com/fdwr/SpriteView.git master
echo %command%
%command%

popd
