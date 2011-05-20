#include "limlib.eh"

#include <stdio.h>
#include <string.h>

#include "limlib_impl.h"

const char* limlib_errmsg()
{
  return last_err_msg;
}

int limlib_size( const char* fn, int* lx, int* ly )
{
   if( readjpeghdr(fn, lx, ly) )
     return LIMLIB_OK;
   if( readtiffhdr(fn, lx, ly) )
     return LIMLIB_OK;
   return LIMLIB_FAIL;
}

int limlib_load( const char* filename, uchar* data )
{
  if( !readjpeg(filename, data) ){
    if( !readtiff(filename, data) ){
      last_err_msg = "cannot open image";
      return LIMLIB_FAIL;
    }
  }
  return LIMLIB_OK;
}

int limlib_load_rgb( const char* filename, uchar* data )
{
  if( !readjpeg_rgb(filename, data) ){
    if( !readtiff_rgb(filename, data) ){
      last_err_msg = "cannot open image";
      return LIMLIB_FAIL;
    }
  }
  return LIMLIB_OK;
}

int limlib_save( const char* fn, int lx, int ly, const uchar* data )
{
  if( !writejpeg(fn, lx, ly, data) ){
    last_err_msg = "cannot write jpeg";
    return LIMLIB_FAIL;
  }
  else
    return LIMLIB_OK;
}

#include "revision.hg"

namespace {
  const char ver[] = "4.01." HG_VER;
  int ver_major = 4;
};

const char* zzz_ver()
{
  return ver;
}

int limlib_ver()
{
  return ver_major;
}
