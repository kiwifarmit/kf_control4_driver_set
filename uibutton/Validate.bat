@echo off
for /f "tokens=3*" %%p in ('REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Personal') do (
    set DocumentsFolder=%%p
)
set "DriverEditorPath=C:\Program Files (x86)\Control4\DriverEditor301"
set "DriverValidator=%DriverEditorPath%\DriverValidator.exe"
set "src=%cd%"
set "dest=%DocumentsFolder%\Control4\Drivers"

echo %cd%
echo %dest%
echo %DriverValidator%



set "val="%DriverValidator%" -d %dest%\Kiwi-button.c4z"
echo %val%
@echo on 

%val%






