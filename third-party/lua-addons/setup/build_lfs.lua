require "libsys"

__ = sys.exec

var = {
  SPATH = "../../lfs/src",
  LUA_PATH = '../../lua51/src',
  HOME = os.getenv('LWDG_HOME')
}

__(var, "g++ -shared -olfs.dll -DLUA_BUILD_AS_DLL -I${LUA_PATH} -L${HOME}/lib ${SPATH}/lfs.c -llua51")
__("strip lfs.dll")
__("mv lfs.dll " .. var.HOME..'/share')
