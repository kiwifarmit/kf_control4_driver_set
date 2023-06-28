@echo off
for /f "tokens=3*" %%p in ('REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Personal') do (
    set DocumentsFolder=%%p
)

set "DriverEditorPath=C:\Program Files (x86)\Control4\DriverEditor301\"
set "DriverEditor=%DriverEditorPath%DriverPackager.exe"
set "src=%cd%"
set "dest=%DocumentsFolder%\Control4\Drivers"
set "manifest=%src%\KMTronic_1_temperature_sensor.c4zproj"
echo %DriverEditor%
echo %cd%
echo %dest%


set "cmd="%DriverEditor%" -v %src%\ %dest%\ %manifest%"
echo %cmd%
echo %DATE%
echo %TIME%

%cmd%


