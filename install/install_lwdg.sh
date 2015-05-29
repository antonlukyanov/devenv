#!/usr/bin/env bash

function error() {
  msg="Error occurred during installation process"
  if [ -n "$1" ]; then
    $msg=": $1"
  fi
  echo $msg
  exit 1
}

UNAME=`uname`
install_lwdg="tools/install_lwdg.lua"

case $UNAME in
  MINGW*)
    SLUA=./temp/standalone-lua.exe
    if [ -n "$*" ]; then
      $SLUA tools/install_lwdg.lua $*
    else
      $SLUA tools/install_lwdg.lua setenv testprg createtree reglua lutils extutl localutl
    fi
  ;;
  Linux|Darwin*)
    SLUA=./temp/standalone-lua
    devenv=~/.devenv
    if [ -n "$*" ]; then
      $SLUA $install_lwdg $*
    else
      $SLUA $install_lwdg testprg createtree lutils extutl localutl
    fi
  ;;
esac

