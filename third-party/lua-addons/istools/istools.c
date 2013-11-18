#include "lua.h"
#include "lauxlib.h"

#include <io.h>
#include <unistd.h>
#include <windows.h>

static int lua_chdir( lua_State *L )
{
  const char *path = luaL_checkstring(L, 1);
  bool res = (chdir(path) == 0);
  lua_pushboolean(L, res);
  return 1;
}

#define PATH_LEN 2048

static int lua_cwd( lua_State *L )
{
  char path[PATH_LEN];
  if( getcwd(path, PATH_LEN) == 0 )
    lua_pushnil(L);
  else
    lua_pushstring(L, path);
  return 1;
}

static int lua_win32_update_config( lua_State *L )
{
  bool is_ok = true;
  is_ok = is_ok && (RegFlushKey(HKEY_CURRENT_USER) == ERROR_SUCCESS);
  is_ok = is_ok && (RegFlushKey(HKEY_LOCAL_MACHINE) == ERROR_SUCCESS);
  DWORD recip = BSM_ALLCOMPONENTS;
  is_ok = is_ok && (BroadcastSystemMessage(BSF_FORCEIFHUNG, &recip, WM_SETTINGCHANGE, 0, (LPARAM)"Environment") > 0);
  lua_pushboolean(L, is_ok);
  return 1;
}

static int lua_win32_set_process_env( lua_State *L )
{
  const char *var = luaL_checkstring(L, 1);
  const char *val = luaL_checkstring(L, 2);
  BOOL res = SetEnvironmentVariable(var, val);
  lua_pushboolean(L, res);
  return 1;
}

static int lua_win32_get_user_path( lua_State *L )
{
  HKEY key;
  if( RegOpenKey(HKEY_CURRENT_USER, "Environment", &key) != ERROR_SUCCESS ){
    lua_pushnil(L);
    return 1;
  }

  DWORD type;
  char path[PATH_LEN];
  DWORD len = PATH_LEN;
  if( RegQueryValueEx(key, "PATH", 0, &type, (BYTE*)path, &len) != ERROR_SUCCESS ){
    lua_pushnil(L);
    return 1;
  }
  
  lua_pushstring(L, path);
  return 1;
}

static const struct luaL_reg istools_lib[] = {
  {"chdir", lua_chdir},
  {"cwd", lua_cwd},
  {"win32_update_config", lua_win32_update_config},
  {"win32_set_process_env", lua_win32_set_process_env},
  {"win32_get_user_path", lua_win32_get_user_path},
  {NULL, NULL},
};

int luaopen_istools( lua_State *L )
{
  luaL_openlib(L, "istools", istools_lib, 0);
  return 1;
}
