#!/usr/bin/env bash

uname=`uname`
install_lwdg="tools/install.lua"

if [[ $uname == Linux* || $uname == Darwin* ]]; then
  luai="./temp/standalone-lua"
else
  luai="./temp/standalone-lua.exe"
fi

if [[ ! -f "$luai" ]]; then
  bash build_lua.sh
else
  echo 'WARNING! Standalone lua interpreter won''t be rebuilt since it already exists: ./temp/standalone-lua'
fi

case $uname in
  MINGW*)
    if [ -n "$*" ]; then
      $luai $install_lwdg $*
    else
      $luai $install_lwdg setenv testprg createtree reglua lutils lua extutl localutl
    fi
    ;;
  Linux|Darwin*)
    devenv=~/.devenv
    if [ -n "$*" ]; then
      $luai $install_lwdg $*
    else
      $luai $install_lwdg 'setenv'
      source ~/.devenv
      $luai $install_lwdg 'testprg' 'createtree' 'lutils' 'lua' 'extutl' 'localutl'
    fi
    ;;
esac
