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
elseif os_type == 'osx' then
  local defs = '-DLUA_COMPAT_ALL -DLUA_USE_MACOSX'
  local libs = '-lm -lreadline'
  local fpic = ''
  local flags = '-dynamiclib -flat_namespace'

  for _, fn in ipairs(lua_modules) do
    mlist = mlist .. src_path .. fn .. '.c '
    olist = olist .. fn .. '.o '
    __("gcc " .. fpic .. " -O2 -Wall " .. defs .. " -c " .. src_path .. fn .. ".c -o " .. fn .. ".o")
  end
  
  __("ar rcu liblua52.a " .. olist)
  __("ranlib liblua52.a")
  __("rm " .. olist)

  __("gcc -O2 -Wall " .. defs .. " -c " .. src_path .. "lua.c -o lua.o")
  __("gcc -O2 -Wall " .. defs .. " -c -o lua.o " .. src_path .. "lua.c");
  __("gcc -o lua lua.o liblua52.a " .. libs);
  
  __("gcc -O2 -Wall " .. defs .. " -c " .. src_path .. "luac.c -o luac.o")
  __("gcc -O2 -Wall " .. defs .. " -c -o luac.o " .. src_path .. "luac.c");
  __("gcc -o luac luac.o liblua52.a " .. libs);

  __("gcc " .. flags .. " -o liblua52.so -O2 -Wall " .. defs .. " " .. mlist .. "")
  
  __("mv liblua52.so " .. share)
  __("mv liblua52.a " .. lib)
  __("mv lua " .. utils)
  __("mv luac " .. utils)
else
  local defs = '-DLUA_COMPAT_ALL -DLUA_USE_LINUX'
  local libs = '-lm -ldl -lreadline'
  local fpic = '-fpic'
  local flags = '-shared -fpic -Wl,-E'

  for _, fn in ipairs(lua_modules) do
    mlist = mlist .. src_path .. fn .. '.c '
    olist = olist .. fn .. '.o '
  end
  
  __("gcc -fPIC -O2 -Wall " .. defs .. " -c " .. mlist)
  __("ar rcu liblua52.a " .. olist)
  __("ranlib liblua52.a")
  
  __("gcc " .. flags .. " -o liblua52.so -O2 -Wall " .. defs .. " " .. olist .. "")
  __("rm " .. olist)

  __("gcc -O2 -Wall " .. defs .. " -c -o lua.o " .. src_path .. "lua.c");
  __("gcc -o lua lua.o liblua52.so " .. libs);
  
  __("gcc -O2 -Wall " .. defs .. " -c -o luac.o " .. src_path .. "luac.c");
  __("gcc -o luac luac.o liblua52.a " .. libs);
  
  __("mv liblua52.so " .. share)
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
