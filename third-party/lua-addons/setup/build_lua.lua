-- ƒл€ компил€ции используетс€ g++ с включенным мэнглингом имен,
-- поэтому заголовочные файлы включаютс€ без extern "C"

require "libsys"
require "libplatform"

local os_type = platform.os_type
local __ = sys.exec

local src_path = "../../lua52/src/"
local home = os.getenv('LWDG_HOME')
local share = home .. "/share"
local utils = home .. "/utils"
local lib = home .. "/lib"

local lua_modules = dofile('lua_modules.lua')
local mlist = ''
local olist = ''
for _, fn in ipairs(lua_modules) do
  mlist = mlist .. src_path .. fn .. '.c '
  olist = olist .. fn .. '.o '
end

if os_type == 'windows' then
  __("gcc -static -shared -Wl,--out-implib,liblua52.a -o lua52.dll -O2 -Wall -DLUA_COMPAT_ALL -DLUA_BUILD_AS_DLL " .. mlist .. " 2>nul")
  __("gcc -static -o lua.exe -O2 -Wall " .. src_path .. "lua.c liblua52.a")
  __("gcc -static -o luac.exe -O2 -Wall " .. src_path .. "luac.c " .. mlist)
  __("strip --strip-unneeded lua52.dll lua.exe luac.exe")
  
  __("mv lua52.dll " .. share)
  __("mv lua.exe " .. utils)
  __("mv luac.exe " .. utils)
  __("mv liblua52.a " .. lib)
elseif os_type == 'osx' then
  local defs = '-DLUA_COMPAT_ALL -DLUA_USE_MACOSX'
  local libs = '-lm -ldl -lreadline'
  
  __("gcc -O2 -Wall " .. defs .. " -c " .. mlist)
  
  __("ar rcu liblua52.a " .. olist)
  __("ranlib liblua52.a")
  
  __("gcc -O2 -Wall -dynamiclib -flat_namespace " .. defs .. " -o liblua52.so " .. olist .. "")
  __("rm " .. olist)

  __("gcc -O2 -Wall " .. defs .. " -c -o lua.o " .. src_path .. "lua.c");
  __("gcc -o lua lua.o liblua52.so " .. libs);
  
  __("gcc -O2 -Wall " .. defs .. " -c -o luac.o " .. src_path .. "luac.c");
  __("gcc -o luac luac.o liblua52.a " .. libs);
  
  __("rm lua.o luac.o")
  
  __("mv liblua52.so " .. share)
  __("mv liblua52.a " .. lib)
  __("mv lua " .. utils)
  __("mv luac " .. utils)
else
  local defs = '-DLUA_COMPAT_ALL -DLUA_USE_LINUX'
  local libs = '-lm -ldl -lreadline'
  
  __("gcc -fPIC -O2 -Wall " .. defs .. " -c " .. mlist)
  __("ar rcu liblua52.a " .. olist)
  __("ranlib liblua52.a")
  
  __("gcc -shared -fpic -Wl,-E -o liblua52.so -O2 -Wall " .. defs .. " " .. olist .. "")
  __("rm " .. olist)

  __("gcc -O2 -Wall " .. defs .. " -c -o lua.o " .. src_path .. "lua.c");
  __("gcc -o lua lua.o liblua52.so " .. libs);
  
  __("gcc -O2 -Wall " .. defs .. " -c -o luac.o " .. src_path .. "luac.c");
  __("gcc -o luac luac.o liblua52.a " .. libs);
  
  __("rm lua.o luac.o")
  
  __("mv liblua52.so " .. share)
  __("mv liblua52.a " .. lib)
  __("mv lua " .. utils)
  __("mv luac " .. utils)
end

local var = {
  INCLUDE = home .. "/include",
  LUA = src_path,
}

__(var, "cp ${LUA}lauxlib.h ${INCLUDE}")
__(var, "cp ${LUA}lua.h ${INCLUDE}")
__(var, "cp ${LUA}luaconf.h ${INCLUDE}")
__(var, "cp ${LUA}lualib.h ${INCLUDE}")
