@echo off
setlocal
set FPC=fpc\bin\i386-win32\fpc.exe
set TARGET=-Px86_64 -Twin64
set UNITS=-Fucompiler

echo == Building tests ==
%FPC% %TARGET% %UNITS% -FEtests -otests\avocado_tests tests\avocado_tests.lpr || goto :fail
copy /Y tests\avocado_tests tests\avocado_tests.exe >nul

echo == Building CLI ==
%FPC% %TARGET% %UNITS% -FEtools -otools\avocado_cli tools\avocado_cli.lpr || goto :fail
copy /Y tools\avocado_cli tools\avocado_cli.exe >nul

echo == Building example scanner ==
%FPC% %TARGET% %UNITS% -FEtests -otests\examplescan tests\examplescan.lpr || goto :fail
copy /Y tests\examplescan tests\examplescan.exe >nul

echo == Running tests ==
tests\avocado_tests.exe || goto :fail

echo == Scanning examples ==
tests\examplescan.exe

echo.
echo Build OK
exit /b 0

:fail
echo Build FAILED
exit /b 1
