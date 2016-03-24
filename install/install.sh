#!/usr/bin/env bash

uname=`uname`
install_lwdg="tools/install.lua"

if [[ $uname == Linux* || $uname == Darwin* ]]; then
  slua="./temp/standalone-lua"
else
  slua="./temp/standalone-lua.exe"
fi

if [ ! -f "$slua" ]; then
  bash build_lua.sh
fi

case $uname in
  MINGW*)
    if [ -n "$*" ]; then
      $slua $install_lwdg $*
    else
      $slua $install_lwdg setenv testprg createtree reglua lutils extutl localutl
    fi
    ;;
  Linux|Darwin*)
    devenv=~/.devenv
    if [ -n "$*" ]; then
      $slua $install_lwdg $*
    else
      $slua $install_lwdg setenv
      source ~/.devenv
      $slua $install_lwdg testprg createtree lutils extutl localutl
    fi
    ;;
esac
