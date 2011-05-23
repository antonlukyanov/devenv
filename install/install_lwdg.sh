if [ -n "$*" ]
then
  ./temp/standalone-lua.exe tools/install_lwdg.lua $*
else
  ./temp/standalone-lua.exe tools/install_lwdg.lua setenv testprg createtree reglua lutils extutl localutlsh
fi

