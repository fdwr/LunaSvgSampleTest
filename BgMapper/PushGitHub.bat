@echo off
setlocal

:: Move up a directory. Otherwise git complains:
:: "You need to run this command from the toplevel of the working tree."
pushd %~dp0\..

set command=git subtree push --prefix BgMapper https://github.com/fdwr/BgMapper.git master
echo %command%
%command%

popd
