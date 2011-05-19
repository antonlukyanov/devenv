#ifndef _ARRAY_EXTN_
#define _ARRAY_EXTN_

#include "luaextn.h"

#include "vector.h"

using namespace lwml;

typedef lwml::vector array;

void stackDump(lua_State *L);

LUA_DEF_CTOR(array, L);
LUA_DEF_DTOR(array, L);
LUA_DEF_DUMP(array, L);
LUA_DEF_LEN(array, L);
LUA_DEF_GETIDX(array, L);
LUA_DEF_SETIDX(array, L);

LUA_DEF_METHOD(array, load, L);
LUA_DEF_METHOD(array, setval, L);
LUA_DEF_METHOD(array, resize, L);
LUA_DEF_METHOD(array, save, L);
LUA_DEF_METHOD(array, stat, L);
LUA_DEF_METHOD(array, diff, L);

#endif // _ARRAY_EXTN_
