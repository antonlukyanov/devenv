#ifndef _LSWG_
#define _LSWG_

#include "platforms.h"

/*#lake:stop*/

#define OK            0
#define FAIL_LSWG     1
#define FAIL_INTERNAL 2

typedef int BOOL;
typedef unsigned int UINT;
typedef double REAL;

LWML_EXPORT const char* lswg_ver();
LWML_EXPORT const char* lswg_errmsg();

LWML_EXPORT int lswg_open( int lx, int ly, BOOL cr );
LWML_EXPORT int lswg_setauto( BOOL is_auto );
LWML_EXPORT int lswg_update();
LWML_EXPORT int lswg_clear( int col );
LWML_EXPORT int lswg_line( int x1, int y1, int x2, int y2, int col );
LWML_EXPORT int lswg_ellipse( int x, int y, int rx, int ry, int extcol, int intcol );
LWML_EXPORT int lswg_rectangle( int x1, int y1, int x2, int y2, int extcol, int intcol );
LWML_EXPORT int lswg_putpixel( int x, int y, int col );
LWML_EXPORT int lswg_setfont( const char* face, int size, bool bf, bool it );
LWML_EXPORT int lswg_settextalign( const char* align );
LWML_EXPORT int lswg_puttext( int x, int y, const char* text, int col, int bgcol );
LWML_EXPORT int lswg_setxor( BOOL is_xor);
LWML_EXPORT int lswg_sleep( int tm );
LWML_EXPORT int lswg_time( REAL* tm );
LWML_EXPORT int lswg_getsize( int* lx, int* ly );
LWML_EXPORT int lswg_iskey( BOOL* is_key );
LWML_EXPORT int lswg_getkey( UINT* key, UINT* ch );
LWML_EXPORT int lswg_getmouse( BOOL* is_mouse, int* x, int* y );
LWML_EXPORT int lswg_load( UINT* idx, const char* );
LWML_EXPORT int lswg_free( UINT idx );
LWML_EXPORT int lswg_imgsize( UINT idx, int* lx, int* ly );
LWML_EXPORT int lswg_put( UINT idx, int x, int y, BOOL use_mask );
LWML_EXPORT int lswg_fill( UINT idx );

#endif // _LSWG_
