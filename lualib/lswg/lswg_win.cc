#include "lswg_win.h"

#include "mtask.h"
#include "t_ring.h"
#include "refowner.h"
#include "refcount.h"
#include "igeom.h"

/*#lake:stop*/

#include <windows.h>
#include <windowsx.h>

namespace lswg {

#define WINDOW_CLASS "lua-simple-windows-graphics"

void zzz( const char* fmt, ... )
{
  static char buf[256];

  va_list va;
  va_start(va, fmt);
  vsprintf(buf, fmt, va);
  OutputDebugString(buf);
  va_end(va);
}

namespace {
  HWND hwnd;
  event wnd_ready(event::OFF);

  HDC wnd_dc, pnt_dc;
  locker lock_paint;
  bool is_auto_update = true;
  int cr_lx, cr_ly;

  t_ring<uint> key_ring(128);
  locker lkr;

  t_ring<int_point> mouse_ring(128);
  locker lmr;

  void OnPaint( HWND hwnd ){
    PAINTSTRUCT ps;
    HDC wdc = BeginPaint(hwnd, &ps);
    RECT r = ps.rcPaint;
    lock_paint.lock();
    BitBlt(wdc, r.left, r.top, r.right-r.left, r.bottom-r.top, wnd_dc, r.left, r.top, SRCCOPY);
    lock_paint.unlock();
    EndPaint(hwnd, &ps);
  }

  void OnDestroy( HWND hwnd )
  {
    PostQuitMessage(0);
  }


  void OnKey( HWND hwnd, UINT vk, BOOL down, int rep, UINT flags )
  {
    zzz("lswg: key");
    lkr.lock();
    key_ring.roll(vk);
    lkr.unlock();
  }

  void OnMouse( int x, int y )
  {
    zzz("lswg: mouse");
    lmr.lock();
    int_point pnt(x, y);
    mouse_ring.roll(pnt);
    lmr.unlock();
  }

  LRESULT CALLBACK winproc( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam ){
    switch( uMsg ){
      case WM_PAINT:       return HANDLE_WM_PAINT(hwnd, wParam, lParam, OnPaint);
      case WM_ERASEBKGND:  return 1;
      case WM_DESTROY:     return HANDLE_WM_DESTROY(hwnd, wParam, lParam, OnDestroy);
      case WM_KEYDOWN:     return HANDLE_WM_KEYDOWN(hwnd, wParam, lParam, OnKey);
      case WM_LBUTTONDOWN:
        if( wParam & MK_LBUTTON )
          OnMouse(LOWORD(lParam), HIWORD(lParam));
        return 0;
      default:             return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
  }

  bool registerclass()
  {
    WNDCLASS wndclass;

    wndclass.style         = CS_OWNDC | CS_HREDRAW | CS_VREDRAW | CS_NOCLOSE;
    wndclass.lpfnWndProc   = winproc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = sizeof(void*);
    wndclass.hInstance     = GetModuleHandle(0);
    wndclass.hIcon         = 0;
    wndclass.hCursor       = LoadCursor(0, IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = WINDOW_CLASS;

    if( !RegisterClass(&wndclass) )
      throw ex_window_create();
    return true;
  }
};

class wnd_func : public i_thread_function {
private:
  wnd_func( int lx, int ly, bool cr ) : _lx(lx), _ly(ly), _cr(cr) {}

public:
  static referer<wnd_func> create( int lx, int ly, bool cr = false ){
    return referer<wnd_func>(new(lwml_alloc) wnd_func(lx, ly, cr));
  }

  virtual void func() {
    !registerclass();
    DWORD sty = WS_OVERLAPPED | WS_CAPTION | WS_BORDER | WS_SYSMENU;

    RECT win_rect = {0, 0, _lx, _ly};

    // расчет размера окна, если задана клиентская часть
    if( _cr ){
      AdjustWindowRect(&win_rect, sty, FALSE);
      // сохранить новый размер окна
      _lx = win_rect.right - win_rect.left;
      _ly = win_rect.bottom - win_rect.top;
    }

    hwnd = CreateWindow(
      WINDOW_CLASS, "lswg", sty,
      0/*x*/, 0/*y*/, _lx, _ly,
      NULL/*parent*/, NULL/*menu*/, GetModuleHandle(0), 0
    );
    if( !hwnd )
      throw ex_window_create();
    HDC wdc = GetDC(hwnd);
    wnd_dc = CreateCompatibleDC(wdc);
    pnt_dc = CreateCompatibleDC(wdc);
    wnd_getsize(cr_lx, cr_ly); // размер клиентской области
    SelectObject(wnd_dc, CreateCompatibleBitmap(wdc, cr_lx, cr_ly));
    SelectObject(pnt_dc, CreateCompatibleBitmap(wdc, cr_lx, cr_ly));
    ShowWindow(hwnd, SW_SHOW);

    wnd_ready.set();
    MSG msg;
    while( GetMessage(&msg, 0, 0, 0) > 0 ){
      TranslateMessage(&msg);
      DispatchMessage(&msg);
    }
  }

private:
  int _lx, _ly;
  bool _cr;
};

refowner<thread> thr;

void wnd_open( int lx, int ly, bool cr )
{
  if( thr.is_ok() )
    return;
  referer<wnd_func> wfunc = wnd_func::create(lx, ly, cr);
  thr.reset(new(lwml_alloc) thread(wfunc));
  thr->start();
  wnd_ready.wait();
}

void wnd_setauto( bool is_auto )
{
  is_auto_update = is_auto;
}

void wnd_update()
{
  lock_paint.lock();
  BitBlt(wnd_dc, 0, 0, cr_lx, cr_ly, pnt_dc, 0, 0, SRCCOPY);
  lock_paint.unlock();
  InvalidateRect(hwnd, NULL, FALSE);
}

void wnd_clear( int col )
{
  HPEN pen = CreatePen(PS_SOLID, 1, col);
  HGDIOBJ old_pen = SelectObject(pnt_dc, pen);
  HBRUSH brush = CreateSolidBrush(col);
  HGDIOBJ old_brush = SelectObject(pnt_dc, brush);
  RECT client;
  GetClientRect(hwnd, &client);
  Rectangle(pnt_dc, client.left, client.top, client.right, client.bottom);
  SelectObject(pnt_dc, old_pen);
  SelectObject(pnt_dc, old_brush);
  DeleteObject(pen);
  DeleteObject(brush);
  if( is_auto_update )
    wnd_update();
}

void wnd_line( int x1, int y1, int x2, int y2, int col )
{
  HPEN pen = CreatePen(PS_SOLID, 1, col);
  HGDIOBJ old_pen = SelectObject(pnt_dc, pen);
  POINT dummy;
  MoveToEx(pnt_dc, x1, y1, &dummy);
  LineTo(pnt_dc, x2, y2);
  SelectObject(pnt_dc, old_pen);
  DeleteObject(pen);
  if( is_auto_update )
    wnd_update();
}

void wnd_ellipse( int x, int y, int rx, int ry, int extcol, int intcol )
{
  HPEN pen = CreatePen(PS_SOLID, 1, extcol);
  HGDIOBJ old_pen = SelectObject(pnt_dc, pen);
  if( intcol == -1 )
    Arc(pnt_dc, x-rx, y-ry, x+rx, y+ry, x-rx, y-ry, x-rx, y-ry);
  else{
    HBRUSH brush = CreateSolidBrush(intcol);
    HGDIOBJ old_brush = SelectObject(pnt_dc, brush);
    Ellipse(pnt_dc, x-rx, y-ry, x+rx, y+ry);
    SelectObject(pnt_dc, old_brush);
    DeleteObject(brush);
  }
  SelectObject(pnt_dc, old_pen);
  DeleteObject(pen);
  if( is_auto_update )
    wnd_update();
}

void wnd_rectangle( int x1, int y1, int x2, int y2, int extcol, int intcol )
{
  HPEN pen = CreatePen(PS_SOLID, 1, extcol);
  HGDIOBJ old_pen = SelectObject(pnt_dc, pen);
  if( intcol == -1 ){
    POINT dummy;
    MoveToEx(pnt_dc, x1, y1, &dummy);
    LineTo(pnt_dc, x2, y1);
    LineTo(pnt_dc, x2, y2);
    LineTo(pnt_dc, x1, y2);
    LineTo(pnt_dc, x1, y1);
  }else{
    HBRUSH brush = CreateSolidBrush(intcol);
    HGDIOBJ old_brush = SelectObject(pnt_dc, brush);
    Rectangle(pnt_dc, x1, y1, x2, y2);
    SelectObject(pnt_dc, old_brush);
    DeleteObject(brush);
  }
  SelectObject(pnt_dc, old_pen);
  DeleteObject(pen);
  if( is_auto_update )
    wnd_update();
}

void wnd_putpixel( int x, int y, int col )
{
  SetPixel(pnt_dc, x, y, col);
  if( is_auto_update )
    wnd_update();
}

void wnd_setfont( const char* face, int size, bool bf, bool it )
{
  int ppi = GetDeviceCaps(pnt_dc, LOGPIXELSY);
  int height = -(size * ppi) / 72;
  int weight = bf ? FW_BOLD : FW_NORMAL;

  HFONT font = CreateFont(
    height, 0, 0, 0, weight, it, 0, 0, 
    DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, 
    CLIP_DEFAULT_PRECIS, PROOF_QUALITY,
    DEFAULT_PITCH | FF_DONTCARE, face
  );
  if( font == 0 )
    throw ex_font();
  HGDIOBJ old = SelectObject(pnt_dc, font);
  DeleteObject(old);
}

void wnd_settextalign( const char* align )
{
  UINT fmode = 0;
  if( strchr(align, 'B') )
    fmode |= TA_BASELINE;
  if( strchr(align, 'b') )
    fmode |= TA_BOTTOM;
  if( strchr(align, 't') )
    fmode |= TA_TOP;
  if( strchr(align, 'l') )
    fmode |= TA_LEFT;
  if( strchr(align, 'r') )
    fmode |= TA_RIGHT;
  if( strchr(align, 'c') )
    fmode |= TA_CENTER;

  UINT res = SetTextAlign(pnt_dc, fmode);
  if( res == GDI_ERROR )
    throw ex_align();
}

void wnd_puttext( int x, int y, const char* text, int col, int bgcol )
{
  //HFONT fnt = (HFONT)GetStockObject(ANSI_VAR_FONT);
  //SelectObject(pnt_dc, fnt);

/*
  TEXTMETRIC tm;
  GetTextMetrics(pnt_dc, &tm);
  int th = tm.tmHeight;
*/
  SetTextColor(pnt_dc, col);
  if( bgcol < 0 ){
    SetBkMode(pnt_dc, TRANSPARENT);
    bgcol = -bgcol;
  }else{
    SetBkMode(pnt_dc, OPAQUE);
  }
  SetBkColor(pnt_dc, bgcol);
  TextOut(pnt_dc, x, y, text, strlen(text));
  if( is_auto_update )
    wnd_update();

  // workaround для странного поведения BitBlt
  SetTextColor(pnt_dc, 0);
  SetBkColor(pnt_dc, 0xffffff);
}

void wnd_setxor( bool is_xor)
{
  SetROP2(pnt_dc, is_xor ? R2_XORPEN : R2_COPYPEN);
}

void wnd_sleep( int tm )
{
  Sleep(tm);
}

void wnd_getsize( int& lx, int& ly )
{
  RECT client;
  GetClientRect(hwnd, &client);
  lx = client.right-client.left;
  ly = client.bottom-client.top;
}

bool wnd_iskey()
{
  lkr.lock();
  bool res = !key_ring.is_empty();
  lkr.unlock();
  return res;
}

uint wnd_getkey( uint* ch )
{
  lkr.lock();
  uint vk = key_ring.pop();
  *ch = MapVirtualKey(vk, 2);
  lkr.unlock();
  return vk;
}

bool wnd_getmouse( int& x, int& y )
{
  lkr.lock();
  bool is_ms = !mouse_ring.is_empty();
  if( is_ms ){
    int_point pnt = mouse_ring.pop();
    x = pnt.x();
    y = pnt.y();
  }
  lkr.unlock();
  return is_ms;
}

namespace{
  const int BMP_NUM = 9192;

  HANDLE bmp[BMP_NUM];
};

uint wnd_load( const char* fnm )
{
  int idx = -1;
  for( int j = 0; j < BMP_NUM; j++ ){
    if( bmp[j] == 0 ){
      idx = j;
      break;
    }
  }
  if( idx == -1 )
    throw ex_bmp_overfull();
  bmp[idx] = LoadImage(0, fnm, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE);
  if( bmp[idx] == 0 )
    throw ex_no_bmp();
  return idx;
}

void wnd_free( uint idx )
{
  if( idx > BMP_NUM-1 )
    return;
  if( bmp[idx] ){
    DeleteObject(bmp[idx]);
    bmp[idx] = 0;
  }
}

void wnd_imgsize( uint idx, int& lx, int& ly )
{
  if( idx > BMP_NUM-1 )
    return;
  if( bmp[idx] == 0 )
    throw ex_no_such_bmp();

  BITMAP info;
  GetObject(bmp[idx], sizeof(BITMAP), &info);
  lx = info.bmWidth;
  ly = info.bmHeight;
}

void wnd_put( uint idx, int x, int y, bool use_mask )
{
  if( idx > BMP_NUM-1 )
    return;
  if( bmp[idx] == 0 )
    throw ex_no_such_bmp();

  BITMAP info;
  GetObject(bmp[idx], sizeof(BITMAP), &info);
  HDC bmp_dc = CreateCompatibleDC(pnt_dc);
  SelectObject(bmp_dc, bmp[idx]);

  if( use_mask ){
    // [c/c] -> [!c/!c]
    BitBlt(pnt_dc, x, y, info.bmWidth, info.bmHeight, NULL, 0, 0, DSTINVERT);

    // [s/1] -> [0/1]
    HBITMAP mask = CreateBitmap(info.bmWidth, info.bmHeight, 1, 1, 0);
    HDC mask_dc = CreateCompatibleDC(pnt_dc);
    SelectObject(mask_dc, mask);
    BitBlt(mask_dc, 0, 0, info.bmWidth, info.bmHeight, bmp_dc, 0, 0, SRCCOPY);

    // [!c/!c] & [0/1] -> [0/!c]
    BitBlt(pnt_dc, x, y, info.bmWidth, info.bmHeight, mask_dc, 0, 0, SRCAND);

    DeleteDC(mask_dc);
    DeleteObject(mask);

    // [s/1] -> [!s/0]
    HBITMAP mbmp = CreateCompatibleBitmap(pnt_dc, info.bmWidth, info.bmHeight);
    HDC mbmp_dc = CreateCompatibleDC(pnt_dc);
    SelectObject(mbmp_dc, mbmp);
    BitBlt(mbmp_dc, 0, 0, info.bmWidth, info.bmHeight, bmp_dc, 0, 0, NOTSRCCOPY);

    // !([0/!c] | [!s/0]) -> !([!s/!c]) = [s/c]
    BitBlt(pnt_dc, x, y, info.bmWidth, info.bmHeight, mbmp_dc, 0, 0, NOTSRCERASE);

    DeleteDC(mbmp_dc);
    DeleteObject(mbmp);
  } else {
    BitBlt(pnt_dc, x, y, info.bmWidth, info.bmHeight, bmp_dc, 0, 0, SRCCOPY);
  }

  DeleteDC(bmp_dc);
  if( is_auto_update )
    wnd_update();
}

void wnd_fill( uint idx )
{
  if( idx > BMP_NUM-1 )
    return;
  if( bmp[idx] == 0 )
    throw ex_no_such_bmp();

  BITMAP info;
  GetObject(bmp[idx], sizeof(BITMAP), &info);
  HDC bmp_dc = CreateCompatibleDC(pnt_dc);
  SelectObject(bmp_dc, bmp[idx]);

  int lx = info.bmWidth;
  int ly = info.bmHeight;
  int nx = cr_lx / lx + 1;
  int ny = cr_ly / ly + 1;

  for( int jx = 0; jx < nx; jx++ )
    for( int jy = 0; jy < ny; jy++ )
      BitBlt(pnt_dc, jx * lx, jy * ly, lx, ly, bmp_dc, 0, 0, SRCCOPY);

  DeleteDC(bmp_dc);
  if( is_auto_update )
    wnd_update();
}

}; // namespace lswg
