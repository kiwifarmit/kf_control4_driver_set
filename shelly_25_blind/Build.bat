@echo off 

set "DriverEditorPath=C:\Program Files (x86)\Control4\DriverEditor301\"
set "DriverEditor=%DriverEditorPath%DriverPackager.exe"
set "src=%cd%"
set "dest=C:\Users\giaco\OneDrive\Documents\Control4\Drivers"
set "manifest=%src%\DMBM-Blind.c4zproj"
echo %DriverEditor%
echo %cd%
echo %dest%


set "cmd="%DriverEditor%" -v %src%\ %dest%\ %manifest%"
echo %cmd%

%cmd%


