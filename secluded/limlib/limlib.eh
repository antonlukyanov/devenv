#ifndef _LIMLIB_
#define _LIMLIB_

/*#lake:stop*/

#define EXPORT extern "C" __attribute__((dllexport))

#define LIMLIB_OK    0 // код нормального выполнения
#define LIMLIB_FAIL -1 // код ошибки

typedef unsigned char uchar;

EXPORT const char* limlib_errmsg();
EXPORT const char* zzz_ver();
EXPORT int limlib_ver();

EXPORT int limlib_size( const char* fn, int* lx, int* ly );
EXPORT int limlib_load( const char* fn, uchar* data );
EXPORT int limlib_load_rgb( const char* fn, uchar* data );
EXPORT int limlib_save( const char* fn, int lx, int ly, const uchar* data );

#endif // _LIMLIB_
