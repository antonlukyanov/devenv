#!/bin/sh

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
    SLUA=lua
    devenv=~/.devenv
    if [ -n "$*" ]; then
      $SLUA $install_lwdg $*
    else
      $SLUA $install_lwdg setenv
      
      if [ -f $devenv ]; then
        source $devenv
      else
        error "could not find ~/.devenv"
      fi
      
      $SLUA $install_lwdg testprg createtree reglua lutils extutl localutl
    fi
  ;;
esac

