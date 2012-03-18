require "libsys"

__ = sys.exec

var = {
  SPATH = "../../md5/",
  LUA_PATH = '../../lua51/src',
  HOME = os.getenv('LWDG_HOME'),
}

__(var, "g++ -static -shared -omd5.dll -DLUA_BUILD_AS_DLL -I${LUA_PATH} -L${HOME}/lib ${SPATH}/md5.c ${SPATH}/md5lib.c -llua51")
__("strip md5.dll")
__("mv md5.dll " .. var.HOME..'/share')
