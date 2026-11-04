@echo off
SET THEFILE=tests\test_all_en.exe
echo Linking %THEFILE%
D:\Lazarus4.6\fpc\3.2.2\bin\x86_64-win64\ld.exe -b pei-x86-64  --gc-sections  -s --subsystem windows --entry=_WinMainCRTStartup    -o tests\test_all_en.exe link11240.res
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
