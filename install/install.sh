#!/usr/bin/env bash

uname=`uname`
install_lwdg="tools/install.lua"
is_standalone_lua=false

for arg; do
  if [[ $arg == "lua" || $uname == MINGW* ]]; then
    is_standalone_lua=true
    break
  fi
done

if [[ $uname == Linux* || $uname == Darwin* ]]; then
  slua="./temp/standalone-lua"
  if [[ $is_standalone_lua == true ]]; then
    luai=$slua
  else
    luai="lua"
  fi
else
  slua="./temp/standalone-lua.exe"
  luai=$slua
fi

if [[ ! -f "$slua" && ($uname == MINGW* || $is_standalone_lua == true) ]]; then
  bash build_lua.sh
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
      $luai $install_lwdg setenv
      source ~/.devenv
      args=(testprg createtree lutils extutl localutl)
      if [[ $is_standalone_lua == true ]]; then
        args=(testprg createtree lutils lua extutl localutl)
      fi
      $luai $install_lwdg $args
    fi
    ;;
esac
