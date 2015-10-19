luacc_driver = [[
extern "C" {
  #include <lauxlib.h>
  #include <lua.h>
  #include <lualib.h>
}

#include <stdlib.h>
#include <string.h>

static void getargs( lua_State* L, int argc, char *argv[] )
{
  int i;
  lua_newtable(L);
  for( i=0; i < argc; i++ ){
    lua_pushnumber(L, i);
    lua_pushstring(L, argv[i]);
    lua_rawset(L, -3);
  }
}

void load_chunk( lua_State* L, struct require_tbl_type* chunk )
{
  if( luaL_loadbuffer(L, chunk->m_code, chunk->m_size, chunk->m_name) || lua_pcall(L, 0, 0, 0) ){
    printf("error: %s\n", lua_tostring(L, -1));
    lua_pop(L, 1);
    exit(1);
  }
}

void load_chunk_by_name( lua_State* L, struct require_tbl_type* chunk, const char* ch_nm )
{
  struct require_tbl_type* c_ch;
  for( c_ch = chunk; c_ch->m_name; c_ch++ ){
    if( strcmp(c_ch->m_name, ch_nm) == 0 )
      load_chunk(L, c_ch);
  }
}

int load_chunk_by_name_lua( lua_State* L )
{
  const char* m_nm = luaL_checkstring(L, -1);
  load_chunk_by_name(L, require_tbl, m_nm);
  return 0;
}

void register_loaders( lua_State* L, struct require_tbl_type* chunk )
{
  struct require_tbl_type* c_ch;

  lua_getglobal(L, "package");    // package
  lua_pushstring(L, "preload");   // package, preload
  lua_gettable(L, -2);            // package, package.preload
  
  for( c_ch = chunk; c_ch->m_name; c_ch++ ){
    const char* nm = c_ch->m_name;

    lua_pushstring(L, nm);                         // package, package.preload, nm
    lua_pushcfunction(L, load_chunk_by_name_lua);  // package, package.preload, nm, func
    lua_settable(L, -3);                           // package, package.preload
  }
  lua_pop(L, 2);
}

int main( int argc, char *argv[] ){
  lua_State* L;
  L = luaL_newstate();
  if( !L ){
    fprintf(stderr, "\nerror: can't create interpreter\n");
    return 1;
  }

  luaL_openlibs(L);

  getargs(L, argc, argv);  /* collect arguments */
  lua_setglobal(L, "arg");

  register_loaders(L, require_tbl);
  load_chunk(L, require_tbl);

  lua_close(L);
}
]]
