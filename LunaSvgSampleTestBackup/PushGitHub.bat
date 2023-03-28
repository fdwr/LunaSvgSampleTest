@echo off
setlocal

:: Move up a directory. Otherwise git complains with:
:: "You need to run this command from the toplevel of the working tree."
pushd %~dp0\..

:: Normally we'd use subtree push, but that takes longer and longer the more commits there are in the repo,
:: as git rereads the whole history to split out any changes under that directory. By instead splitting the
:: repo and then pushing that branch (and keeping the branch around), it takes barely longer than a normal
:: push command.

set command=git subtree split --rejoin --prefix LunaSvgSampleTest -b LunaSvgSampleTest
echo %command%
%command%

::Avoid subtree push, instead pushing from the split branch.
:: set command=git subtree push --prefix LunaSvgSampleTest https://github.com/fdwr/LunaSvgSampleTest.git master
set command=git push https://github.com/fdwr/LunaSvgSampleTest.git LunaSvgSampleTest:master
echo %command%
%command%

popd
