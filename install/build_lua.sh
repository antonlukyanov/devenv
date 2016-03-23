#!/usr/bin/env bash
# Automatically generated by tools/mk_build_lua.lua, no hands!

echo "Patching lua..."

cd ..
TPU='third-party'
patch --output=$TPU/lua52/src/linit_istools.c $TPU/lua52/src/linit.c \
  $TPU/lua-addons/istools/lua-istools.diff
cp $TPU/lua-addons/istools/istools.c $TPU/lua52/src
cd -

echo "Building temp/standalone-lua.exe..."

UNAME=$(uname)
TPU="../third-party"

SRC_LIST="\
  $TPU/lua52/src/lapi.c \
  $TPU/lua52/src/lauxlib.c \
  $TPU/lua52/src/lbaselib.c \
  $TPU/lua52/src/lbitlib.c \
  $TPU/lua52/src/lcode.c \
  $TPU/lua52/src/lcorolib.c \
  $TPU/lua52/src/lctype.c \
  $TPU/lua52/src/ldblib.c \
  $TPU/lua52/src/ldebug.c \
  $TPU/lua52/src/ldo.c \
  $TPU/lua52/src/ldump.c \
  $TPU/lua52/src/lfunc.c \
  $TPU/lua52/src/lgc.c \
  $TPU/lua52/src/liolib.c \
  $TPU/lua52/src/llex.c \
  $TPU/lua52/src/lmathlib.c \
  $TPU/lua52/src/lmem.c \
  $TPU/lua52/src/loadlib.c \
  $TPU/lua52/src/lobject.c \
  $TPU/lua52/src/lopcodes.c \
  $TPU/lua52/src/loslib.c \
  $TPU/lua52/src/lparser.c \
  $TPU/lua52/src/lstate.c \
  $TPU/lua52/src/lstring.c \
  $TPU/lua52/src/lstrlib.c \
  $TPU/lua52/src/ltable.c \
  $TPU/lua52/src/ltablib.c \
  $TPU/lua52/src/ltm.c \
  $TPU/lua52/src/lundump.c \
  $TPU/lua52/src/lvm.c \
  $TPU/lua52/src/lzio.c \
  $TPU/lua52/src/lua.c"

case $UNAME in
  MINGW*)
    g++ -O2 -Wall -DLUA_COMPAT_MODULE -otemp/standalone-lua.exe $SRC_LIST \
      $TPU/lua52/src/istools.c $TPU/lua52/src/linit_istools.c
    strip temp/standalone-lua.exe
  ;;
  Linux*)
    sudo apt-get install libreadline-dev
    g++ -O2 -Wall -DLUA_COMPAT_MODULE -DLUA_USE_LINUX -otemp/standalone-lua $SRC_LIST \
      $TPU/lua52/src/istools.c $TPU/lua52/src/linit_istools.c -ldl -lreadline
    strip temp/standalone-lua
  ;;
  Darwin*)
    brew install readline
    g++ -O2 -Wall -DLUA_COMPAT_MODULE -DLUA_USE_MACOSX -otemp/standalone-lua $SRC_LIST \
      $TPU/lua52/src/istools.c $TPU/lua52/src/linit_istools.c -lm -lreadline
  ;;
esac

rm $TPU/lua52/src/istools.c $TPU/lua52/src/linit_istools.c
