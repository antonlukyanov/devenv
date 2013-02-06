UNAME=`uname`

if [[ $UNAME =~ "MINGW32_NT.*" ]]
then
  ./temp/standalone-lua.exe tools/install_wx.lua
else
  echo
  echo '*** error: this script is intended for Windows environment only'
  exit 1
fi
