UNAME=`uname`

if [[ $UNAME =~ "MINGW32_NT.*" ]]
then
  SLUAINT=./temp/standalone-lua.exe
else
  SLUAINT=./temp/standalone-lua
fi

if [ -n "$*" ]
then
  $SLUAINT tools/install_lwdg.lua $*
else
  $SLUAINT tools/install_lwdg.lua setenv testprg createtree reglua lutils extutl localutl
fi
