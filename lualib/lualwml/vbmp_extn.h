#ifndef _VBMP_EXTN_
#define _VBMP_EXTN_

#include "luaextn.h"

using namespace lwml;

LUA_DEF_CTOR(vbmp, L);
LUA_DEF_DTOR(vbmp, L);
LUA_DEF_DUMP(vbmp, L);

LUA_DEF_METHOD(vbmp, load, L);
LUA_DEF_METHOD(vbmp, getsize, L);
LUA_DEF_METHOD(vbmp, save, L);
LUA_DEF_METHOD(vbmp, load_matrix, L);
LUA_DEF_METHOD(vbmp, save_matrix, L);
LUA_DEF_METHOD(vbmp, get, L);
LUA_DEF_METHOD(vbmp, set, L);
LUA_DEF_METHOD(vbmp, matrix, L);
LUA_DEF_METHOD(vbmp, equalize, L);
LUA_DEF_METHOD(vbmp, requantify, L);
LUA_DEF_METHOD(vbmp, decimate, L);
LUA_DEF_METHOD(vbmp, thresholding, L);
LUA_DEF_METHOD(vbmp, sobel, L);
LUA_DEF_METHOD(vbmp, filter, L);
LUA_DEF_METHOD(vbmp, stat, L);
LUA_DEF_METHOD(vbmp, hist, L);
LUA_DEF_METHOD(vbmp, mkdiff, L);
LUA_DEF_METHOD(vbmp, diff, L);
LUA_DEF_METHOD(vbmp, crop, L);
LUA_DEF_METHOD(vbmp, hsect, L);
LUA_DEF_METHOD(vbmp, vsect, L);
LUA_DEF_METHOD(vbmp, gaussblur, L);
LUA_DEF_METHOD(vbmp, sqgaussblur, L);
LUA_DEF_METHOD(vbmp, resample, L);
LUA_DEF_METHOD(vbmp, resize, L);
LUA_DEF_METHOD(vbmp, median, L);
LUA_DEF_METHOD(vbmp, rot, L);

#endif // _VBMP_EXTN_
