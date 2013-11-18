//!! type title here
// lwml, (c) ltwood

#ifndef _LSWG_WIN_
#define _LSWG_WIN_

#include "defs.h"
#include "mdefs.h"

/*#lake:stop*/

namespace lswg {

using namespace lwml;

DEF_EX_CLASS(ex_base, ex_lswg);
DEF_EX_TYPE(ex_lswg, ex_window_create, "can't create window");
DEF_EX_TYPE(ex_lswg, ex_bmp_overfull, "too many bitmaps");
DEF_EX_TYPE(ex_lswg, ex_no_bmp, "can't find bitmap");
DEF_EX_TYPE(ex_lswg, ex_no_such_bmp, "no such bitmap");
DEF_EX_TYPE(ex_lswg, ex_font, "can't create font");
DEF_EX_TYPE(ex_lswg, ex_align, "incorrect text alignment");

void wnd_open( int lx, int ly, bool cr );
void wnd_setauto( bool is_auto );
void wnd_update();
void wnd_clear( int col );
void wnd_line( int x1, int y1, int x2, int y2, int col );
void wnd_ellipse( int x, int y, int rx, int ry, int extcol, int intcol );
void wnd_rectangle( int x1, int y1, int x2, int y2, int extcol, int intcol );
void wnd_putpixel( int x, int y, int col );
void wnd_setfont( const char* face, int size, bool bf, bool it );
void wnd_settextalign( const char* align );
void wnd_puttext( int x, int y, const char* text, int col, int bgcol );
void wnd_setxor( bool is_xor);
void wnd_sleep( int tm );
void wnd_getsize( int& lx, int& ly );
bool wnd_iskey();
uint wnd_getkey( uint* ch );
bool wnd_getmouse( int& x, int& y );
uint wnd_load( const char* );
void wnd_free( uint idx );
void wnd_imgsize( uint idx, int& lx, int& ly );
void wnd_put( uint idx, int x, int y, bool use_mask );
void wnd_fill( uint idx );

}; // namespace lswg

#endif // _LSWG_WIN_
