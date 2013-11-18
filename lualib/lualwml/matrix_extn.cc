#include "matrix_extn.h"

#include "vbmp.h"
#include "stdmem.h"

LUA_DEF_CTOR(matrix, L)
{
  luaextn ex(L);
LUA_TRY
  int str = 0;
  int col = 0;
  double val = 0.0;

  int argc = ex.arg_num();
  if( argc >= 2 ){
    str = ex.get_int(1);
    col = ex.get_int(2);
  }
  if( argc >= 3 )
    val = ex.get_real(3);

  ex.CREATE_OBJECT(matrix, new(lwml_alloc) matrix(str, col, val));
  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_DTOR(matrix, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p = ex.GET_OBJECT(matrix);
  delete p;
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_DUMP(matrix, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p = ex.GET_OBJECT(matrix);
  ex.put_fmt("(matrix, str=%d col=%d)", p->str(), p->col());
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(matrix, load, L)
{
  luaextn ex(L);
LUA_TRY
  const char* nm = ex.get_str(1);
  ex.CREATE_OBJECT(matrix, new(lwml_alloc) matrix(nm));
  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_METHOD(matrix, save, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p = ex.GET_OBJECT_IDX(matrix, 1);
  p->save(ex.get_str(2));

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(matrix, setval, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p = ex.GET_OBJECT_IDX(matrix, 1);
  p->set_val(ex.get_real(2));
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(matrix, size, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p = ex.GET_OBJECT_IDX(matrix, 1);

  ex.put_int(p->str());
  ex.put_int(p->col());

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(matrix, stat, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p = ex.GET_OBJECT_IDX(matrix, 1);

  ex.put_real(p->min());
  ex.put_real(p->max());
  ex.put_real(p->mid());

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(matrix, get, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p = ex.GET_OBJECT_IDX(matrix, 1);

  int s = ex.get_int(2);
  int c = ex.get_int(3);

  ex.put_real(p->operator()(s, c));

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(matrix, set, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p = ex.GET_OBJECT_IDX(matrix, 1);

  int s = ex.get_int(2);
  int c = ex.get_int(3);
  real v = ex.get_real(4);

  p->operator()(s, c) = v;

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(matrix, diff, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p1 = ex.GET_OBJECT_IDX(matrix, 1);
  matrix* p2 = ex.GET_OBJECT_IDX(matrix, 2);

  int str = p1->str();
  int col = p1->col();
  if( p2->str() != str || p2->col() != col )
    ex.error("incorrect sizes");

  real max = 0.0;
  real mid = 0.0;
  for( int s = 0; s < str; s++ ){
    for( int c = 0; c < col; c++ ){
      real dev = fabs((*p1)(s,c) - (*p2)(s,c));
      if( dev > max )
        max = dev;
      mid += dev;
    }
  }
  mid /= (str * col);

  ex.put_real(max);
  ex.put_real(mid);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(matrix, vbmp, L)
{
  luaextn ex(L);
LUA_TRY
  matrix* p = ex.GET_OBJECT(matrix);
  vbmp* rp = new(lwml_alloc) vbmp(p->str(), p->col());
  rp->put(*p);
  ex.CREATE_OBJECT(vbmp, rp);

  return ex.ret_num();
LUA_CATCH_RET(ex)
}
