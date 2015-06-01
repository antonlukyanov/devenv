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

if os_type == 'windows' then
  for _, fn in ipairs(lua_modules) do
    mlist = mlist .. src_path .. fn .. '.c '
    olist = olist .. fn .. '.o '
  end

  __("g++ -static -shared -Wl,--out-implib,liblua52.a -o lua52.dll -O2 -Wall -DLUA_BUILD_AS_DLL " .. mlist .. " 2>nul")
  __("g++ -static -o lua.exe -O2 -Wall " .. src_path .. "lua.c liblua52.a")
  __("g++ -static -o luac.exe -O2 -Wall " .. src_path .. "luac.c " .. mlist)
  __("strip --strip-unneeded lua52.dll lua.exe luac.exe")
  
  __("mv lua52.dll " .. share)
  __("mv lua.exe " .. utils)
  __("mv luac.exe " .. utils)
  __("mv liblua52.a " .. lib)
else
  local defs
  local libs
  local flags
  if os_type == 'osx' then
    defs = '-DLUA_USE_MACOSX'
    libs = '-lm -lreadline'
    flags = '-dynamiclib -flat_namespace'
  else
    defs = '-DLUA_USE_LINUX'
    libs = '-lm -ldl -lreadline'
    flags = '-shared -fpic'
  end

  for _, fn in ipairs(lua_modules) do
    mlist = mlist .. src_path .. fn .. '.c '
    olist = olist .. fn .. '.o '
    __("gcc -O2 -Wall -DLUA_COMPAT_ALL " .. defs .. " -c " .. src_path .. fn .. ".c -o " .. fn .. ".o")
  end
  
  __("ar rcu liblua52.a " .. olist)
  __("ranlib liblua52.a")
  __("rm " .. olist)

  __("gcc -O2 -Wall -DLUA_COMPAT_ALL " .. defs .. " -c " .. src_path .. "lua.c -o lua.o")
  __("gcc -O2 -Wall -DLUA_COMPAT_ALL " .. defs .. " -c -o lua.o " .. src_path .. "lua.c");
  __("gcc -o lua lua.o liblua52.a " .. libs);
  
  __("gcc -O2 -Wall -DLUA_COMPAT_ALL -DLUA_USE_MACOSX -c " .. src_path .. "luac.c -o luac.o")
  __("gcc -O2 -Wall -DLUA_COMPAT_ALL -DLUA_USE_MACOSX -c -o luac.o " .. src_path .. "luac.c");
  __("gcc -o luac luac.o liblua52.a " .. libs);

  __("gcc " .. flags .. " -o liblua52 -O2 -Wall -DLUA_COMPAT_ALL " .. defs .. " " .. mlist .. "")
  
  __("mv liblua52 " .. share)
  __("mv liblua52.a " .. lib)
  __("mv lua " .. utils)
  __("mv luac " .. utils)
end

local var = {
  INCLUDE = home .. "/include",
  LUA = src_path,
}

__(var, "cp ${LUA}/lauxlib.h ${INCLUDE}")
__(var, "cp ${LUA}/lua.h ${INCLUDE}")
__(var, "cp ${LUA}/luaconf.h ${INCLUDE}")
__(var, "cp ${LUA}/lualib.h ${INCLUDE}")
