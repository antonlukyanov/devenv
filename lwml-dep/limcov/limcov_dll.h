#ifndef _LIMCOV_
#define _LIMCOV_

#include "platforms.h"

#define LIMCOV_OK    0 // код нормального выполнения
#define LIMCOV_FAIL -1 // код ошибки

LWML_EXPORT const char* limcov_errmsg();
LWML_EXPORT const char* zzz_ver();
LWML_EXPORT int limcov_ver();

LWML_EXPORT int limcov_size( const char* fn, int* lx, int* ly );
LWML_EXPORT int limcov_load( const char* fn, unsigned char* data );
LWML_EXPORT int limcov_save( const char* fn, int lx, int ly, const unsigned char* data );

#endif // _LIMCOV_
