@echo off
setlocal

:: Move up a directory. Otherwise git complains with:
:: "You need to run this command from the toplevel of the working tree."
pushd %~dp0\..

set command=git subtree pull --prefix LunaSvgSampleTest https://github.com/fdwr/LunaSvgSampleTest.git master
echo %command%
%command%

popd
