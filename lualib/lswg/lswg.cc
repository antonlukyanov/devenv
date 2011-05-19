#include "luaextn.h"
#include "timer.h"

#include "lswg_win.h"

#include "lswg.eh"

#include "revision.svn"

/*#lake:stop*/

using namespace lwml;
using namespace lswg;

LUA_DEF_FUNCTION( test, L )
{
  luaextn ex(L);
LUA_TRY
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( open_window, L )
{
  luaextn ex(L);
LUA_TRY
  int lx = 640;
  int ly = 480;
  bool cr = false;
  if( ex.arg_num() >= 2 ){
    lx = ex.get_int(1);
    ly = ex.get_int(2);
    if( ex.arg_num() >= 3 )
      cr = ex.get_bool(3);
  }
  wnd_open(lx, ly, cr);
  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_FUNCTION( setauto, L )
{
  luaextn ex(L);
LUA_TRY
  bool is_auto = ex.get_bool(1);
  wnd_setauto(is_auto);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( update, L )
{
  luaextn ex(L);
LUA_TRY
  wnd_update();
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( clear, L )
{
  luaextn ex(L);
LUA_TRY
  int col = ex.get_int(1);
  wnd_clear(col);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( line, L )
{
  luaextn ex(L);
LUA_TRY
  int x1 = ex.get_int(1);
  int y1 = ex.get_int(2);
  int x2 = ex.get_int(3);
  int y2 = ex.get_int(4);
  int col = ex.get_int(5);
  wnd_line(x1, y1, x2, y2, col);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( ellipse, L )
{
  luaextn ex(L);
LUA_TRY
  int x = ex.get_int(1);
  int y = ex.get_int(2);
  int rx = ex.get_int(3);
  int ry = ex.get_int(4);
  int extcol = ex.get_int(5);
  int intcol = (ex.arg_num() == 6) ? ex.get_int(6) : -1;
  wnd_ellipse(x, y, rx, ry, extcol, intcol);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( rectangle, L )
{
  luaextn ex(L);
LUA_TRY
  int x1 = ex.get_int(1);
  int y1 = ex.get_int(2);
  int x2 = ex.get_int(3);
  int y2 = ex.get_int(4);
  int extcol = ex.get_int(5);
  int intcol = (ex.arg_num() == 6) ? ex.get_int(6) : -1;
  wnd_rectangle(x1, y1, x2, y2, extcol, intcol);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( putpixel, L )
{
  luaextn ex(L);
LUA_TRY
  int x = ex.get_int(1);
  int y = ex.get_int(2);
  int col = ex.get_int(3);
  wnd_putpixel(x, y, col);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( setfont, L )
{
  luaextn ex(L);
LUA_TRY
  const char* face = ex.get_str(1);
  int sz = ex.get_int(2);
  bool bf = false;
  if( ex.arg_num() > 2 )
    bf = ex.get_bool(3);
  bool it = false;
  if( ex.arg_num() > 3 )
    it = ex.get_bool(4);
  wnd_setfont(face, sz, bf, it);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( settextalign, L )
{
  luaextn ex(L);
LUA_TRY
  const char* align = ex.get_str(1);
  wnd_settextalign(align);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( puttext, L )
{
  luaextn ex(L);
LUA_TRY
  int x = ex.get_int(1);
  int y = ex.get_int(2);
  const char* text = ex.get_str(3);
  int col = ex.get_int(4);
  int bgcol = (ex.arg_num() == 5) ? ex.get_int(5) : -1;
  wnd_puttext(x, y, text, col, bgcol);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( setxor, L )
{
  luaextn ex(L);
LUA_TRY
  bool is_xor = ex.get_bool(1);
  wnd_setxor(is_xor);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( sleep, L )
{
  luaextn ex(L);
LUA_TRY
  int tm = (ex.arg_num() == 1) ? ex.get_int(1) : 0;
  wnd_sleep(tm);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( time, L )
{
  luaextn ex(L);
LUA_TRY
  ex.put_real(timer::time());
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( getsize, L )
{
  luaextn ex(L);
LUA_TRY
  int lx, ly;
  wnd_getsize(lx, ly);
  ex.put_int(lx);
  ex.put_int(ly);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( getkey, L )
{
  luaextn ex(L);
LUA_TRY
  if( wnd_iskey() ){
    uint ch;
    ex.put_int(wnd_getkey(&ch));
    ex.put_int(ch);
  } else
    ex.put_nil();
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( getmouse, L )
{
  luaextn ex(L);
LUA_TRY
  int x, y;
  bool is_ms = wnd_getmouse(x, y);
  if( is_ms ){
    ex.put_int(x);
    ex.put_int(y);
  }else
    ex.put_nil();
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( load, L )
{
  luaextn ex(L);
LUA_TRY
  const char* fn = ex.get_str(1);
  int idx = wnd_load(fn);
  ex.put_int(idx);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( free, L )
{
  luaextn ex(L);
LUA_TRY
  int idx = ex.get_int(1);
  wnd_free(idx);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( imgsize, L )
{
  luaextn ex(L);
LUA_TRY
  int idx = ex.get_int(1);
  int lx, ly;
  wnd_imgsize(idx, lx, ly);
  ex.put_int(lx);
  ex.put_int(ly);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( put, L )
{
  luaextn ex(L);
LUA_TRY
  int idx = ex.get_int(1);
  int x = ex.get_int(2);
  int y = ex.get_int(3);
  bool use_mask = (ex.arg_num() == 4) ? ex.get_bool(4) : false;

  wnd_put(idx, x, y, use_mask);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( fill, L )
{
  luaextn ex(L);
LUA_TRY
  int idx = ex.get_int(1);
  wnd_fill(idx);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_BEGIN_LIBRARY(lswg)
  //LUA_FUNCTION(test)
  LUA_FUNCTION(open_window)
  LUA_FUNCTION(setauto)
  LUA_FUNCTION(update)
  LUA_FUNCTION(clear)
  LUA_FUNCTION(line)
  LUA_FUNCTION(ellipse)
  LUA_FUNCTION(rectangle)
  LUA_FUNCTION(putpixel)
  LUA_FUNCTION(setfont)
  LUA_FUNCTION(settextalign)
  LUA_FUNCTION(puttext)
  LUA_FUNCTION(setxor)
  LUA_FUNCTION(sleep)
  LUA_FUNCTION(time)
  LUA_FUNCTION(getsize)
  LUA_FUNCTION(getkey)
  LUA_FUNCTION(getmouse)
  LUA_FUNCTION(load)
  LUA_FUNCTION(free)
  LUA_FUNCTION(imgsize)
  LUA_FUNCTION(put)
  LUA_FUNCTION(fill)
LUA_END_LIBRARY

LUA_BEGIN_EXPORT(lswg)
  LUA_EXPORT_LIBRARY(lswg)
LUA_END_EXPORT

// C interface

const int ERR_BUFLEN = 1024;
static char err_buf[ERR_BUFLEN] = "";

const char* lswg_errmsg()
{
  return err_buf;
}

#define TRY try{ \
  { fpreset(); }

#define CATCH_EX( ex_type, ret_code )             \
  catch( ex_type& ex ){                           \
    prot_strcpy(err_buf, ex.msg(), ERR_BUFLEN);   \
    return ret_code;                              \
  }                                               //

#define CATCH                                     \
}                                                 \
  CATCH_EX(ex_lswg, FAIL_LSWG)                    \
  CATCH_EX(ex_base, FAIL_INTERNAL)                //

const char ver[] = "lswg, ver. 1.10, " SVN_VER;

const char* lswg_ver()
{
  return ver;
}

LWML_EXPORT const char* zzz_ver()
{
  return ver;
}

int lswg_open( int lx, int ly, BOOL cr )
{
TRY
  wnd_open(lx, ly, cr);
  return OK;
CATCH
}

int lswg_setauto( BOOL is_auto )
{
TRY
  wnd_setauto(is_auto);
  return OK;
CATCH
}

int lswg_update()
{
TRY
  wnd_update();
  return OK;
CATCH
}

int lswg_clear( int col )
{
TRY
  wnd_clear(col);
  return OK;
CATCH
}

int lswg_line( int x1, int y1, int x2, int y2, int col )
{
TRY
  wnd_line(x1, y1, x2, y2, col);
  return OK;
CATCH
}

int lswg_ellipse( int x, int y, int rx, int ry, int extcol, int intcol )
{
TRY
  wnd_ellipse(x, y, rx, ry, extcol, intcol);
  return OK;
CATCH
}

int lswg_rectangle( int x1, int y1, int x2, int y2, int extcol, int intcol )
{
TRY
  wnd_rectangle(x1, y1, x2, y2, extcol, intcol);
  return OK;
CATCH
}

int lswg_putpixel( int x, int y, int col )
{
TRY
  wnd_putpixel(x, y, col);
  return OK;
CATCH
}

int lswg_setfont( const char* face, int size, bool bf, bool it )
{
TRY
  wnd_setfont(face, size, bf, it);
  return OK;
CATCH
}

int lswg_settextalign( const char* align )
{
TRY
  wnd_settextalign(align);
  return OK;
CATCH
}

int lswg_puttext( int x, int y, const char* text, int col, int bgcol )
{
TRY
  wnd_puttext(x, y, text, col, bgcol);
  return OK;
CATCH
}

int lswg_setxor( BOOL is_xor )
{
TRY
  wnd_setxor(is_xor);
  return OK;
CATCH
}

int lswg_sleep( int tm )
{
TRY
  wnd_sleep(tm);
  return OK;
CATCH
}

int lswg_time( REAL* tm )
{
TRY
  *tm = timer::time();
  return OK;
CATCH
}

int lswg_getsize( int* lx, int* ly )
{
TRY
  wnd_getsize(*lx, *ly);
  return OK;
CATCH
}

int lswg_iskey( BOOL* is_key )
{
TRY
  *is_key = wnd_iskey();
  return OK;
CATCH
}

int lswg_getkey( UINT* key, UINT* ch )
{
TRY
  *key = wnd_getkey(ch);
  return OK;
CATCH
}

int lswg_getmouse( BOOL* is_mouse, int* x, int* y )
{
TRY
  *is_mouse = wnd_getmouse(*x, *y);
  return OK;
CATCH
}

int lswg_load( UINT* idx, const char* fn )
{
TRY
  *idx = wnd_load(fn);
  return OK;
CATCH
}

int lswg_free( UINT idx )
{
TRY
  wnd_free(idx);
  return OK;
CATCH
}

int lswg_imgsize( UINT idx, int* lx, int* ly )
{
TRY
  wnd_imgsize(idx, *lx, *ly);
  return OK;
CATCH
}

int lswg_put( UINT idx, int x, int y, BOOL use_mask )
{
TRY
  wnd_put(idx, x, y, use_mask);
  return OK;
CATCH
}

int lswg_fill( UINT idx )
{
TRY
  wnd_fill(idx);
  return OK;
CATCH
}
