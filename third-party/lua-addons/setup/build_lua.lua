-- дл€ компил€ции используетс€ g++ с включенным мэнглингом имен,
-- поэтому заголовочные файлы включаютс€ без extern "C"

require "libsys"
require "libplatform"

__ = sys.exec

src_path = "../../lua52/src/"

lua_modules = dofile('lua_modules.lua')

mlist = ''
for _, fn in ipairs(lua_modules) do
  mlist = mlist .. src_path .. fn .. '.c '
end

if platform.os_type == 'windows' then
  tonull = "2>nul"
else
  tonull = "2>/dev/null"
end

__("g++ -static -shared -Wl,--out-implib,liblua52.a -o lua52.dll -O2 -Wall -DLUA_BUILD_AS_DLL " .. mlist .. " " .. tonull)
__("g++ -static -o lua.exe -DLUA_BUILD_AS_DLL " .. src_path .. "lua.c liblua52.a")
__("g++ -static -o luac.exe -O2 -Wall " .. src_path .. "luac.c " .. mlist)
__("strip --strip-unneeded lua52.dll lua.exe luac.exe")

-- setup

home = os.getenv('LWDG_HOME')

share = home .. "/share"
utils = home .. "/utils"
lib = home .. "/lib"

__("mv lua52.dll " .. share)
__("mv lua.exe " .. utils)
__("mv luac.exe " .. utils)
__("mv liblua52.a " .. lib)

var = {
  INCLUDE = home .. "/include",
  LUA = src_path,
}

__(var, "cp ${LUA}/lauxlib.h ${INCLUDE}")
__(var, "cp ${LUA}/lua.h ${INCLUDE}")
__(var, "cp ${LUA}/luaconf.h ${INCLUDE}")
__(var, "cp ${LUA}/lualib.h ${INCLUDE}")
