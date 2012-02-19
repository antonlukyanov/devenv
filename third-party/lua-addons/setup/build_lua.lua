-- дл€ компил€ции используетс€ g++ с включенным мэнглингом имен,
-- поэтому заголовочные файлы включаютс€ без extern "C"

require "libsys"

__ = sys.exec

src_path = "../../lua51/src/"

lua_modules = dofile('lua_modules.lua')

mlist = ''
for _, fn in ipairs(lua_modules) do
  mlist = mlist .. src_path .. fn .. '.c '
end

__("patch ../../lua51/src/luaconf.h patch/lua-5_1.diff")
__("g++ -shared -Wl,--out-implib,liblua51.a -o lua51.dll -O2 -Wall -DLUA_BUILD_AS_DLL " .. mlist .. " 2>nul")
__("g++ -o lua.exe -DLUA_BUILD_AS_DLL " .. src_path.."lua.c liblua51.a")
__("g++ -o luac.exe -O2 -Wall " .. src_path.."luac.c " .. src_path.."print.c " .. mlist)
__("strip --strip-unneeded lua51.dll lua.exe luac.exe")
__("patch -R ../../lua51/src/luaconf.h patch/lua-5_1.diff")

-- setup

home = os.getenv('LWDG_HOME')

share = home .. "/share"
utils = home .. "/utils"
lib = home .. "/lib"

__("mv lua51.dll " .. share)
__("mv lua.exe " .. utils)
__("mv luac.exe " .. utils)
__("mv liblua51.a " .. lib)

var = {
  INCLUDE = home .. "/include",
  LUA = src_path,
}

__(var, "cp ${LUA}/lauxlib.h ${INCLUDE}")
__(var, "cp ${LUA}/lua.h ${INCLUDE}")
__(var, "cp ${LUA}/luaconf.h ${INCLUDE}")
__(var, "cp ${LUA}/lualib.h ${INCLUDE}")
