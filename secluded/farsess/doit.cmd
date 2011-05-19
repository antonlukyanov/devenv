@echo off
g++ -shared -oesession.dll -Wl,--add-stdcall-alias esession.cpp
strip esession.dll
rem