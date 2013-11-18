#ifndef _FFT_EXTN_
#define _FFT_EXTN_

#include "luaextn.h"

using namespace lwml;

LUA_DEF_FUNCTION( cfft, L );
LUA_DEF_FUNCTION( cifft, L );

LUA_DEF_FUNCTION( cfft2d, L );
LUA_DEF_FUNCTION( cifft2d, L );

#endif // _FFT_EXTN_
