#include "array_extn.h"

#include "stdmem.h"

void stackDump(lua_State *L) {
  int i;
  int top = lua_gettop(L);
  for( i = 1; i <= top; i++ ){  /* repeat for each level */
    int t = lua_type(L, i);
    switch( t ){
      case LUA_TSTRING:  /* strings */
        printf("`%s'", lua_tostring(L, i));
        break;

      case LUA_TBOOLEAN:  /* booleans */
        printf(lua_toboolean(L, i) ? "true" : "false");
        break;

      case LUA_TNUMBER:  /* numbers */
        printf("%g", lua_tonumber(L, i));
        break;

      default:  /* other values */
        printf("%s", lua_typename(L, t));
        break;
    }
    printf("  ");  /* put a separator */
  }
  printf("\n");  /* end the listing */
}

LUA_DEF_CTOR(array, L)
{
  luaextn ex(L);
LUA_TRY
  int len = 0;
  double val = 0.0;

  int argc = ex.arg_num();
  if( argc == 1 )
    len = ex.get_int(1);
  if( argc == 2 ){
    len = ex.get_int(1);
    val = ex.get_real(2);
  }

  ex.CREATE_OBJECT(array, new(lwml_alloc) array(len, val));
  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_DTOR(array, L)
{
  luaextn ex(L);
LUA_TRY
  array* p = ex.GET_OBJECT(array);
  delete p;
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_DUMP(array, L)
{
  luaextn ex(L);
LUA_TRY
  array* p = ex.GET_OBJECT(array);
  ex.put_fmt("(array, len=%d)", p->len());
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_LEN(array, L)
{
  luaextn ex(L);
LUA_TRY
  array* p = ex.GET_OBJECT(array);
  ex.put_int(p->len());
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_GETIDX(array, L)
{
  luaextn ex(L);
LUA_TRY
  array* p = ex.GET_OBJECT(array);
  int idx = ex.get_int(2);
  real val = (*p)[idx];
  ex.put_real(val);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_SETIDX(array, L)
{
  luaextn ex(L);
LUA_TRY
  array* p = ex.GET_OBJECT(array);
  int idx = ex.get_int(2);
  real val = ex.get_real(3);
  (*p)[idx] = val;
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(array, load, L)
{
  luaextn ex(L);
LUA_TRY
  const char* nm = ex.get_str(1);
  ex.CREATE_OBJECT(array, new(lwml_alloc) array(nm));
  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_METHOD(array, setval, L)
{
  luaextn ex(L);
LUA_TRY
  array* p = ex.GET_OBJECT_IDX(array, 1);
  p->set_val(ex.get_real(2));
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(array, resize, L)
{
  luaextn ex(L);
LUA_TRY
  array* p = ex.GET_OBJECT_IDX(array, 1);
  p->resize(ex.get_int(2));
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(array, save, L)
{
  luaextn ex(L);
LUA_TRY
  array* p = ex.GET_OBJECT_IDX(array, 1);
  p->save(ex.get_str(2));

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(array, stat, L)
{
  luaextn ex(L);
LUA_TRY
  array* p = ex.GET_OBJECT_IDX(array, 1);

  ex.put_real(p->min());
  ex.put_real(p->max());
  ex.put_real(p->mid());
  ex.put_real(sqrt(p->disp()));

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(array, diff, L)
{
  luaextn ex(L);
LUA_TRY
  array* p1 = ex.GET_OBJECT_IDX(array, 1);
  array* p2 = ex.GET_OBJECT_IDX(array, 2);

  int len = p1->len();
  if( p2->len() != len )
    ex.error("incorrect sizes");

  real max = 0.0;
  real mid = 0.0;
  for( int j = 0; j < len; j++ ){
    real dev = fabs((*p1)[j] - (*p2)[j]);
    if( dev > max )
      max = dev;
    mid += dev;
  }
  mid /= len;

  ex.put_real(max);
  ex.put_real(mid);

  return ex.ret_num();
LUA_CATCH(ex)
}
