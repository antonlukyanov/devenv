#!/bin/sh

UNAME=`uname`

case $UNAME in
  MINGW32_NT*)
    ./temp/standalone-lua.exe tools/install_wx.lua
  ;;
  *)
    echo
    echo '*** error: this script is intended for Windows environment only'
    exit 1
  ;;
esac
