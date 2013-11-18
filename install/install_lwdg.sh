#!/bin/sh

UNAME=`uname`

case $UNAME in
  MINGW32_NT*)
    SLUAINT=./temp/standalone-lua.exe
  ;;
  *)
    SLUAINT=./temp/standalone-lua
  ;;
esac

if [ -n "$*" ]
then
  $SLUAINT tools/install_lwdg.lua $*
else
  $SLUAINT tools/install_lwdg.lua setenv testprg createtree reglua lutils extutl localutl
fi
