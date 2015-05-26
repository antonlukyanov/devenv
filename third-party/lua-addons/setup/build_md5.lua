require "libsys"

__ = sys.exec

var = {
  SPATH = "../../md5/",
  LUA_PATH = '../../lua52/src',
  HOME = os.getenv('LWDG_HOME'),
}

__(var, "g++ -static -shared -omd5.dll -DLUA_COMPAT_MODULE -DLUA_BUILD_AS_DLL -I${LUA_PATH} -L${HOME}/lib ${SPATH}/md5.c ${SPATH}/md5lib.c -llua52")
__("strip md5.dll")
__("mv md5.dll " .. var.HOME..'/share')
