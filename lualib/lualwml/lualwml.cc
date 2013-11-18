#include "apphome.h"
#include "luaextn.h"
#include "platforms.h"

#include "vbmp_extn.h"
#include "array_extn.h"
#include "matrix_extn.h"
#include "fft_extn.h"

using namespace lwml;

// export

LWML_EXPORT const char* zzz_ver();

// version

#include "revision.hg"

static const char ver[] = "1.03." HG_VER;

const char* zzz_ver()
{
  return ver;
}

// vbmp

LUA_BEGIN_CLASS(vbmp)
  LUA_METHOD(vbmp, load)
  LUA_METHOD(vbmp, load_matrix)
  LUA_METHOD(vbmp, mkdiff)
  LUA_METHOD(vbmp, diff)
LUA_META(vbmp)
  LUA_METHOD(vbmp, getsize)
  LUA_METHOD(vbmp, save)
  LUA_METHOD(vbmp, save_matrix)
  LUA_METHOD(vbmp, get)
  LUA_METHOD(vbmp, set)
  LUA_METHOD(vbmp, matrix)
  LUA_METHOD(vbmp, equalize)
  LUA_METHOD(vbmp, requantify)
  LUA_METHOD(vbmp, decimate)
  LUA_METHOD(vbmp, thresholding)
  LUA_METHOD(vbmp, sobel)
  LUA_METHOD(vbmp, filter)
  LUA_METHOD(vbmp, stat)
  LUA_METHOD(vbmp, hist)
  LUA_METHOD(vbmp, crop)
  LUA_METHOD(vbmp, hsect)
  LUA_METHOD(vbmp, vsect)
  LUA_METHOD(vbmp, gaussblur)
  LUA_METHOD(vbmp, sqgaussblur)
  LUA_METHOD(vbmp, resample)
  LUA_METHOD(vbmp, resize)
  LUA_METHOD(vbmp, median)
  LUA_METHOD(vbmp, rot)
LUA_END_CLASS

// vector

LUA_BEGIN_CLASS(array)
  LUA_METHOD(array, load)
  LUA_METHOD(array, diff)
  LUA_METHOD(array, setval)
  LUA_METHOD(array, resize)
  LUA_METHOD(array, save)
  LUA_METHOD(array, stat)
LUA_META_IDX(array)
LUA_END_CLASS

// matrix

LUA_BEGIN_CLASS(matrix)
  LUA_METHOD(matrix, load)
  LUA_METHOD(matrix, diff)
LUA_META(matrix)
  LUA_METHOD(matrix, save)
  LUA_METHOD(matrix, setval)
  LUA_METHOD(matrix, size)
  LUA_METHOD(matrix, stat)
  LUA_METHOD(matrix, get)
  LUA_METHOD(matrix, set)
  LUA_METHOD(matrix, vbmp)
LUA_END_CLASS

// fft

LUA_BEGIN_LIBRARY(fft)
  LUA_FUNCTION(cfft)
  LUA_FUNCTION(cifft)
  LUA_FUNCTION(cfft2d)
  LUA_FUNCTION(cifft2d)
LUA_END_LIBRARY

// export

LUA_BEGIN_EXPORT(lualwml)
  LUA_EXPORT_CLASS(vbmp)
  LUA_EXPORT_CLASS(array)
  LUA_EXPORT_CLASS(matrix)
  LUA_EXPORT_LIBRARY(fft)
LUA_END_EXPORT
