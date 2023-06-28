@echo off 

set "DriverEditorPath=C:\Program Files (x86)\Control4\DriverEditor301\"
set "DriverValidator=%DriverEditorPath%DriverValidator.exe"
set "src=%cd%"
set "dest=C:\Users\giaco\OneDrive\Documents\Control4\Drivers"

echo %cd%
echo %dest%
echo %DriverValidator%



set "val="%DriverValidator%" -d %dest%\KMTTronic_IPRelays.c4z"
echo %val%
@echo on 

%val%






