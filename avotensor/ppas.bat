@echo off
SET THEFILE=D:\Programowanie na Delphi\Lazarus projekty\2025\Luty-2025\moj-jezyk-programowania\Avotensor\AvoTensor\project1.exe
echo Linking %THEFILE%
D:\Lazarus3.6\fpc\3.2.2\bin\x86_64-win64\ld.exe -b pei-x86-64  --gc-sections  -s  --entry=_mainCRTStartup    -o "D:\Programowanie na Delphi\Lazarus projekty\2025\Luty-2025\moj-jezyk-programowania\Avotensor\AvoTensor\project1.exe" "D:\Programowanie na Delphi\Lazarus projekty\2025\Luty-2025\moj-jezyk-programowania\Avotensor\AvoTensor\link9380.res"
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
