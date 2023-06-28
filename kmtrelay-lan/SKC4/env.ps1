$env:Path +="C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\systree\bin"
$env:LUA_PATH +="C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\systree\share\lua\5.1\?.lua;C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\systree\share\lua\5.1\?\init.lua"

$env:Path +="%APPDATA%\LuaRocks\bin"
$env:LUA_PATH +="%APPDATA%\LuaRocks\share\lua\5.1\?.lua;%APPDATA%\LuaRocks\share\lua\5.1\?\init.lua"
$env:LUA_CPATH +="%APPDATA%\LuaRocks\lib\lua\5.1\?.dll"

$env:Path +="C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32"
$env:LUA_PATH +="C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\lua\?.lua;C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\lua\?\init.lua"

$env:Path +="C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32"
$env:PATHEXT +=".LUA"
