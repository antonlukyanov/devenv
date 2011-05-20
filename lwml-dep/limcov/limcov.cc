#include "vbmp.h"
#include "apphome.h"
#include "debug.h"

#include "limcov_dll.h"

using namespace lwml;

const int ERR_BUFLEN = 1024;

static char err_buf[ERR_BUFLEN] = "";

#define TRY try{ \
  { fpreset(); }

#define CATCH \
}catch( ex_base& ex ){ \
  prot_strcpy(err_buf, ex.msg(), ERR_BUFLEN);   \
  return LIMCOV_FAIL; \
}

LWML_EXPORT const char* limcov_errmsg()
{
  return err_buf;
}

LWML_EXPORT int limcov_size( const char* fn, int* lx, int* ly )
{
TRY
  zzz_ex("limcov", "size(%s)", fn);
  vbmp buf(fn);
  *lx = buf.lx();
  *ly = buf.ly();
  return LIMCOV_OK;
CATCH
}

LWML_EXPORT int limcov_load( const char* fn, unsigned char* data )
{
TRY
  zzz_ex("limcov", "load(%s)", fn);
  vbmp buf(fn);
  for( int j = 0; j < buf.len(); j++ )
    data[j] = buf[j];
  return LIMCOV_OK;
CATCH
}

LWML_EXPORT int limcov_save( const char* fn, int lx, int ly, const unsigned char* data )
{
TRY
  zzz_ex("limcov", "save(%s)", fn);
  vbmp buf(ly, lx);
  for( int j = 0; j < buf.len(); j++ )
    buf[j] = data[j];
  buf.save(fn);
  return LIMCOV_OK;
CATCH
}

// version

#include "revision.hg"

namespace {
  const char ver[] = "2.01." HG_VER;
  int ver_major = 2;
};

LWML_EXPORT const char* zzz_ver()
{
  return ver;
}

LWML_EXPORT int limcov_ver()
{
  return ver_major;
}
