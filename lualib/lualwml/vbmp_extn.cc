#include "vbmp_extn.h"
#include "array_extn.h"

#include "vbmp.h"
#include "bmputl.h"
#include "conv_blur.h"
#include "resample.h"
#include "medianfilt.h"

LUA_DEF_CTOR(vbmp, L)
{
  luaextn ex(L);
LUA_TRY
  if( ex.arg_num()  == 0 )
    ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp());
  else {
    int lx = ex.get_int(1);
    int ly = ex.get_int(2);
    vbmp* p = new(lwml_alloc) vbmp(ly, lx);
    for( int j = 0; j < p->len(); j++ )
      (*p)[j] = 0;
    ex.CREATE_OBJECT(vbmp, p);
  }
  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_DTOR(vbmp, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  delete p;
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_DUMP(vbmp, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  ex.put_fmt("(image, lx=%d, ly=%d)", p->lx(), p->ly());
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, load, L)
{
  luaextn ex(L);
LUA_TRY
  const char* fnm = ex.get_str(1);
  ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(fnm));
  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_METHOD(vbmp, getsize, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  ex.put_int(p->ly());
  ex.put_int(p->lx());
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, save, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  p->save(ex.get_str(2));
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, get, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int x = ex.get_int(2);
  int y = ex.get_int(3);
  uchar col = (*p)(y, x);
  ex.put_int(col);
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, set, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int x = ex.get_int(2);
  int y = ex.get_int(3);
  int col = ex.get_int(4);
  (*p)(y, x) = col;
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, matrix, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  matrix* rp = new(lwml_alloc) matrix(p->ly(), p->lx());
  p->get(*rp);
  ex.CREATE_OBJECT(matrix, rp);

  return ex.ret_num();
LUA_CATCH_RET(ex)
}

// additional vbmp methods

LUA_DEF_METHOD(vbmp, load_matrix, L)
{
  luaextn ex(L);
LUA_TRY
  matrix m(ex.get_str(1));
  vbmp* p = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m.str(), m.col()));
  p->put(m);
  return ex.ret_num();
LUA_CATCH_RET(ex)
}

LUA_DEF_METHOD(vbmp, save_matrix, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  matrix m(p->ly(), p->lx());
  p->get(m);
  m.save(ex.get_str(2));
  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, equalize, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int hst_len = 256;

  if( ex.arg_num() == 2 )
    hst_len = ex.get_int(2);

  matrix m(p->ly(), p->lx());
  p->get(m);
  bmputil::equalization(m, hst_len);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m.str(), m.col()));
  p2->put(m);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, requantify, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int lev = ex.get_int(2);

  matrix m(p->ly(), p->lx());
  p->get(m);
  int_matrix m2(p->ly(), p->lx());
  bmputil::leveling(m2, m, lev);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m2.str(), m2.col()));
  p2->put(m2);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, decimate, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int dec = ex.get_int(2);
  if( p->lx() % dec != 0 || p->ly() % dec != 0 )
    ex.arg_error(2, "incorrect decimation factor");

  matrix m(p->ly(), p->lx());
  p->get(m);
  matrix m2(p->ly()/dec, p->lx()/dec);
  bmputil::decimation(m2, m);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m2.str(), m2.col()));
  p2->put(m2);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, thresholding, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  real thr = ex.get_real(2);

  matrix m(p->ly(), p->lx());
  p->get(m);
  int_matrix m2(p->ly(), p->lx());
  bmputil::thresholding(m2, m, thr);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m2.str(), m2.col()));
  p2->put(m2);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, sobel, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);

  matrix m(p->ly(), p->lx());
  p->get(m);
  matrix m2(p->ly(), p->lx());
  bmputil::sobel(m2, m);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m2.str(), m2.col()));
  p2->put(m2);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, filter, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  real cnt = ex.get_real(2);
  real cross = ex.get_real(3);
  real diag = ex.get_real(4);

  matrix m(p->ly(), p->lx());
  p->get(m);
  matrix m2(p->ly(), p->lx());
  bmputil::filter(m2, m, cnt, cross, diag);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m2.str(), m2.col()));
  p2->put(m2);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, stat, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);

  matrix m(p->ly(), p->lx());
  p->get(m);

  ex.put_real(m.min());
  ex.put_real(m.max());
  ex.put_real(m.mid());
  m.center();
  int num = m.str()*m.col();
  ex.put_real(sqrt(m.mag()/num));

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, hist, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int len = 256;

  if( ex.arg_num() == 2 )
    len = ex.get_int(2);

  matrix m(p->ly(), p->lx());
  p->get(m);

  array* r = ex.CREATE_OBJECT(array, new(lwml_alloc) array());
  bmputil::hist(*r, m, len);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, mkdiff, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p1 = ex.GET_OBJECT_IDX(vbmp, 1);
  vbmp* p2 = ex.GET_OBJECT_IDX(vbmp, 2);

  matrix m1(p1->ly(), p1->lx());
  matrix m2(p2->ly(), p2->lx());
  p1->get(m1);
  p2->get(m2);
  matrix mr(p1->ly(), p1->lx());
  bmputil::diff(mr, m1, m2);

  vbmp* pr = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(mr.str(), mr.col()));
  pr->put(mr);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, diff, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p1 = ex.GET_OBJECT_IDX(vbmp, 1);
  vbmp* p2 = ex.GET_OBJECT_IDX(vbmp, 2);

  int len = p1->len();
  if( p2->len() != len )
    ex.error("incorrect sizes");

  real max = 0.0;
  real mid = 0.0;
  for( int j = 0; j < len; j++ ){
    real dev = labs((*p1)[j] - (*p2)[j]);
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

LUA_DEF_METHOD(vbmp, crop, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int x0 = ex.get_int(2);
  if( x0 < 0 || x0 > p->lx()-1 )
    ex.arg_error(2, "incorrect x0");
  int y0 = ex.get_int(3);
  if( y0 < 0 || y0 > p->ly()-1 )
    ex.arg_error(3, "incorrect y0");
  int lx = ex.get_int(4);
  if( lx < 0 || x0+lx > p->lx() )
    ex.arg_error(4, "incorrect lx");
  int ly = ex.get_int(5);
  if( ly < 0 || y0+ly > p->ly() )
    ex.arg_error(5, "incorrect ly");

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(ly, lx));
  for( int y = 0; y < ly; y++ )
    for( int x = 0; x < lx; x++ )
      (*p2)(y, x) = (*p)(y0+y, x0+x);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, hsect, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int y0 = ex.get_int(2);
  if( y0 < 0 || y0 > p->ly()-1 )
    ex.arg_error(2, "incorrect y0");
  int ly = (ex.arg_num() > 2) ? ex.get_int(3) : 1;
  if( ly < 0 || y0+ly > p->ly() )
    ex.arg_error(3, "incorrect ly");

  array* r = ex.CREATE_OBJECT(array, new(lwml_alloc) array(p->lx()));
  r->set_zero();
  for( int y = 0; y < ly; y++ )
    for( int x = 0; x < p->lx(); x++ )
      (*r)[x] += (*p)(y0+y, x);
  (*r) /= ly;

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, vsect, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int x0 = ex.get_int(2);
  if( x0 < 0 || x0 > p->lx()-1 )
    ex.arg_error(2, "incorrect x0");
  int lx = (ex.arg_num() > 2) ? ex.get_int(3) : 1;
  if( lx < 0 || x0+lx > p->lx()-1 )
    ex.arg_error(3, "incorrect lx");

  array* r = ex.CREATE_OBJECT(array, new(lwml_alloc) array(p->ly()));
  r->set_zero();
  for( int x = 0; x < lx; x++ )
    for( int y = 0; y < p->ly(); y++ )
      (*r)[y] += (*p)(y, x0+x);
  (*r) /= lx;

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, gaussblur, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  real sx = ex.get_real(2);
  real sy = ex.get_real(3);
  real phi = (ex.arg_num() >= 4) ? ex.get_real(4) : 0.0;
  int hlx = 0;
  int hly = 0;

  matrix m(p->ly(), p->lx());
  p->revers();
  p->get(m);
  p->revers();
  conv_blur cb(p->ly(), p->lx(), hly, hlx);
  cb.proc(m, gauss2d_func(sx, sy, phi));
  cb.get(m);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m.str(), m.col()));
  p2->put(m);
  p2->revers();

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, sqgaussblur, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  real half_sq = ex.get_real(2);
  real sigma = ex.get_real(3);
  int hlx = 0;
  int hly = 0;

  matrix m(p->ly(), p->lx());
  matrix m2(p->ly(), p->lx());
  p->revers();
  p->get(m);
  p->revers();
  conv_blur cb(p->ly(), p->lx(), hly, hlx);
  cb.proc(m, square_gauss_func(half_sq, sigma));
  cb.get(m2);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m2.str(), m2.col()));
  p2->put(m2);
  p2->revers();

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, resample, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int new_lx = ex.get_int(2);
  if( new_lx <= 0 )
    ex.arg_error(2, "incorrect new_lx");
  int new_ly = ex.get_int(3);
  if( new_ly <= 0 )
    ex.arg_error(3, "incorrect new_ly");
  real r = (ex.arg_num() >= 4) ? ex.get_real(4) : 2.0;
  if( r < 1.0 )
    ex.arg_error(4, "incorrect radius");

  matrix dst(new_ly, new_lx);
  {
    matrix src(p->ly(), p->lx());
    p->get(src);
    lanczos::warp(dst, src, r);
  }

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(new_ly, new_lx));
  // Сохраняем изображение с обрезанием по уровням 0 и 255 без масштабирования.
  // Возможно, эту операцию надо обобщить.
  for( int y = 0; y < new_ly; ++y ){
    for( int x = 0; x < new_lx; ++x ){
      uchar v = fpr::lround(t_max<real>(t_min<real>(dst(y, x), 255.0), 0.0));
      (*p2)(y, x) = v;
    }
  }

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, resize, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int fact = ex.get_int(2);
  if( fact <= 0 )
    ex.arg_error(2, "incorrect fact");

  int nlx = p->lx() * fact;
  int nly = p->ly() * fact;
  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(nly, nlx));
  for( int y = 0; y < nly; ++y ){
    for( int x = 0; x < nlx; ++x )
      (*p2)(y, x) = (*p)(y/fact, x/fact);
  }

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, median, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  int apt = ex.get_int(2);

  int_matrix m(p->ly(), p->lx());
  p->get(m);
  int_matrix m2(p->ly(), p->lx());
  medianfilt::calc(m2, m, apt);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m2.str(), m2.col()));
  p2->put(m2);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_METHOD(vbmp, rot, L)
{
  luaextn ex(L);
LUA_TRY
  vbmp* p = ex.GET_OBJECT(vbmp);
  real angle = ex.get_real(2);

  int_matrix m(p->ly(), p->lx());
  p->get(m);
  int_matrix m2(p->ly(), p->lx());
  bmputil::rot(m2, m, angle);

  vbmp* p2 = ex.CREATE_OBJECT(vbmp, new(lwml_alloc) vbmp(m2.str(), m2.col()));
  p2->put_noscale(m2);

  return ex.ret_num();
LUA_CATCH(ex)
}
