@echo off
setlocal

:: Move up a directory. Otherwise git complains with:
:: "You need to run this command from the toplevel of the working tree."
pushd %~dp0\..

set command=git subtree push --prefix LunaSvgTest https://github.com/fdwr/LunaSvgSampleTest.git master
echo %command%
%command%

popd
