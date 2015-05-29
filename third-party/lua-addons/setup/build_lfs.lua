require "libsys"
require "libplatform"

os_type = platform.os_type

__ = sys.exec

var = {
  SPATH = "../../lfs/src",
  LUA_PATH = '../../lua52/src',
  HOME = os.getenv('LWDG_HOME')
}

if os_type == 'windows' then
  __(var, "g++ -static -shared -olfs.dll -DLUA_BUILD_AS_DLL -I${LUA_PATH} -L${HOME}/lib ${SPATH}/lfs.c -llua52")
  __("strip lfs.dll")
  __("mv lfs.dll " .. var.HOME..'/share')
elseif os_type == 'osx' then
  __(var, "gcc -dynamiclib -flat_namespace -olfs.so -DLUA_USE_LINUX -I${LUA_PATH} -L${HOME}/lib ${SPATH}/lfs.c -llua52")
  __("mv lfs.so " .. var.HOME..'/share')
end

