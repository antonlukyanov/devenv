#ifndef _MATRIX_EXTN_
#define _MATRIX_EXTN_

#include "luaextn.h"

#include "matrix.h"

using namespace lwml;

void stackDump(lua_State *L);

LUA_DEF_CTOR(matrix, L);
LUA_DEF_DTOR(matrix, L);
LUA_DEF_DUMP(matrix, L);

LUA_DEF_METHOD(matrix, load, L);
LUA_DEF_METHOD(matrix, save, L);
LUA_DEF_METHOD(matrix, setval, L);
LUA_DEF_METHOD(matrix, size, L);
LUA_DEF_METHOD(matrix, stat, L);
LUA_DEF_METHOD(matrix, get, L);
LUA_DEF_METHOD(matrix, set, L);
LUA_DEF_METHOD(matrix, diff, L);
LUA_DEF_METHOD(matrix, vbmp, L);

#endif // _MATRIX_EXTN_
