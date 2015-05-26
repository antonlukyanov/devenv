require "libsys"

__ = sys.exec

var = {
  SPATH = "../../lfs/src",
  LUA_PATH = '../../lua52/src',
  HOME = os.getenv('LWDG_HOME')
}

__(var, "g++ -static -shared -olfs.dll -DLUA_BUILD_AS_DLL -I${LUA_PATH} -L${HOME}/lib ${SPATH}/lfs.c -llua52")
__("strip lfs.dll")
__("mv lfs.dll " .. var.HOME..'/share')
