#include "fft_extn.h"
#include "array_extn.h"
#include "matrix_extn.h"

#include "fft.h"
#include "fft2d.h"
#include "stdmem.h"

LUA_DEF_FUNCTION( cfft, L )
{
  luaextn ex(L);
LUA_TRY
  array* xr = ex.GET_OBJECT_IDX(array, 1);
  array* xi = ex.GET_OBJECT_IDX(array, 2);

  if( xr->len() != xi->len() )
    ex.error("incorrect sizes");
  int len = xr->len();

  vector xxr(up2pow2(len));
  vector xxi(up2pow2(len));
  xxr.copy(*xr);
  xxi.copy(*xi);

  fft::cfft(xxr, xxi);

  ex.CREATE_OBJECT(array, new(lwml_alloc) array(xxr));
  ex.CREATE_OBJECT(array, new(lwml_alloc) array(xxi));
  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_FUNCTION( cifft, L )
{
  luaextn ex(L);
LUA_TRY
  array* xr = ex.GET_OBJECT_IDX(array, 1);
  array* xi = ex.GET_OBJECT_IDX(array, 2);

  if( xr->len() != xi->len() )
    ex.error("incorrect sizes");
  int len = xr->len();

  vector xxr(up2pow2(len));
  vector xxi(up2pow2(len));
  xxr.copy(*xr);
  xxi.copy(*xi);

  fft::cifft(xxr, xxi);

  ex.CREATE_OBJECT(array, new(lwml_alloc) array(xxr));
  ex.CREATE_OBJECT(array, new(lwml_alloc) array(xxi));

  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_FUNCTION( cfft2d, L )
{
  luaextn ex(L);
LUA_TRY
  matrix* xr = ex.GET_OBJECT_IDX(matrix, 1);
  matrix* xi = ex.GET_OBJECT_IDX(matrix, 2);

  if( xr->str() != xi->str() || xr->col() != xi->col() )
    ex.error("incorrect sizes");
  int str = xr->str();
  int col = xr->col();

  matrix xxr(up2pow2(str), up2pow2(col));
  matrix xxi(up2pow2(str), up2pow2(col));
  xxr.copy(*xr);
  xxi.copy(*xi);

  fft2d::disturb(xxr);
  fft2d::disturb(xxi);
  fft2d::cfft(xxr, xxi);

  ex.CREATE_OBJECT(matrix, new(lwml_alloc) matrix(xxr));
  ex.CREATE_OBJECT(matrix, new(lwml_alloc) matrix(xxi));

  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_FUNCTION( cifft2d, L )
{
  luaextn ex(L);
LUA_TRY
  matrix* xr = ex.GET_OBJECT_IDX(matrix, 1);
  matrix* xi = ex.GET_OBJECT_IDX(matrix, 2);

  if( xr->str() != xi->str() || xr->col() != xi->col() )
    ex.error("incorrect sizes");
  int str = xr->str();
  int col = xr->col();

  if( !ispow2(str) || !ispow2(col) )
    ex.error("incorrect sizes (pow2)");

  matrix xxr(str, col);
  matrix xxi(str, col);
  xxr.copy(*xr);
  xxi.copy(*xi);

  fft2d::cifft(xxr, xxi);
  fft2d::disturb(xxr);
  fft2d::disturb(xxi);

  ex.CREATE_OBJECT(matrix, new(lwml_alloc) matrix(xxr));
  ex.CREATE_OBJECT(matrix, new(lwml_alloc) matrix(xxi));

  return ex.ret_num();
LUA_CATCH_RET(ex)
}
