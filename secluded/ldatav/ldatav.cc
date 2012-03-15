#include <windows.h>
#include <windowsx.h>

#undef min
#undef max

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <limits.h>

/*#lake:res:ldatav_win*/

#ifdef _MSC_VER
#define for if(true) for
#define _argc __argc
#define _argv __argv
#endif

// data const

const int MAX_DATA_NUM = 3;

int colors[MAX_DATA_NUM][3] = {
  {   0,   0, 250 },
  { 250,   0, 250 },
  { 255,   0,   0 },
};

// mnu const

#define MNU_HOME         101
#define MNU_PGUP         102
#define MNU_LEFT         103
#define MNU_CLEFT        104
#define MNU_CRIGHT       105
#define MNU_RIGHT        106
#define MNU_PGDN         107
#define MNU_END          108
#define MNU_POINT        109
#define MNU_UP           110
#define MNU_CUP          111
#define MNU_CDN          112
#define MNU_DN           113
#define MNU_RESET        114
#define MNU_INS          115
#define MNU_DEL          116
#define MNU_PLUS         117
#define MNU_MINUS        118
#define MNU_QUIT         119
#define MNU_RELOAD       120
#define MNU_FIT          121
#define MNU_RESCALE      122
#define MNU_EXPORT       123

#define MNU_ANTIA        124
#define MNU_TRAN0        125
#define MNU_TRAN1        126
#define MNU_TRAN2        127
#define MNU_TRAN3        128
#define MNU_TRAN4        129

// common macro

#define int_cast(x)  static_cast<int>(x)
#define real_cast(x) static_cast<double>(x)

// common const

const int MSG_LEN = 512;
const int TITLE_LEN = 512;
const int CAPTION_LEN = 256;

const double MUL = 1.41421356237309505;
const double DIV = 0.70710678118654752;

const double WIN_DEF_WIDTH = 0.75;
const double WIN_DEF_HEIGHT = 0.75;

#include "revision.hg"

const char LDATAV_VER[] = "2.63." HG_VER;

// common func

void message( char *fmt, ... ){
  char msg[MSG_LEN];
  va_list va;
  va_start(va, fmt);
  vsprintf(msg, fmt, va);
  va_end(va);

  char title[TITLE_LEN];
  sprintf(title, "ldatav v%s:", LDATAV_VER);
  MessageBox(0, msg, title, MB_OK | MB_ICONHAND);
}

// color model

struct rgbcolor {
  rgbcolor( float _r, float _g, float _b ) : r(_r), g(_g), b(_b) {}

  float r, g, b;
};
struct hsbcolor {
  hsbcolor( float _h, float _s, float _b ) : h(_h), s(_s), b(_b) {}

  float h, s, b;
};

rgbcolor hsb2rgb( const hsbcolor& hsb )
{
  float h = 360.0 * hsb.h; // important: hue as degree
  float s = hsb.s;
  float v = hsb.b;

  h = fmod(h, 360.0);
  h /= 60.0;
  int i = int_cast(h);
  float f = h - i;  // f is the fractional part of h
  float j = v * (1.0 - s);
  float k = v * (1.0 - s * f);
  float l = v * (1.0 - s * (1.0 - f));

  float r = 0.0, g = 0.0, b = 0.0; // has no mean!
  switch( i ){
    case 0: r = v; g = l; b = j; break;
    case 1: r = k; g = v; b = j; break;
    case 2: r = j; g = v; b = l; break;
    case 3: r = j; g = k; b = v; break;
    case 4: r = l; g = j; b = v; break;
    case 5: r = v; g = j; b = k; break;
    default:
      r = g = b = 0; // fail_unexpected();
  }

  return rgbcolor(r, g, b);
}

template <typename T>
  inline T t_min( const T& t1, const T& t2 ) { return (t1 < t2) ? t1 : t2; }
template <typename T>
  inline T t_max( const T& t1, const T& t2 ) { return (t1 > t2) ? t1 : t2; }

template <typename T>
  inline T t_min( const T& t1, const T& t2, const T& t3 ) { return t_min<T>(t_min<T>(t1, t2), t3); }
template <typename T>
  inline T t_max( const T& t1, const T& t2, const T& t3 ) { return t_max<T>(t_max<T>(t1, t2), t3); }

const float UNDEFINED_COLOR = 0.0;

hsbcolor rgb2hsb( const rgbcolor& rgb )
{
  float h, s, v;

  float r = rgb.r;
  float g = rgb.g;
  float b = rgb.b;

  // определение "светлоты"2
  float max = t_max<float>(r, g, b);
  v = max;

  // определение насыщенности
  float min = t_min<float>(r, g, b);
  if( v == 0.0 ) s = 0.0;
    else s = (v - min) / v;

  // Определение цветового тона
  if( s == 0 )
    h = UNDEFINED_COLOR;
  else{
    float delta = max - min;
    float cr = (max - r) / delta;
    float cg = (max - g) / delta;
    float cb = (max - b) / delta;

    h = 0; // has no mean!
    if( r == max )
      h = cb - cg;       // цвет между желтым и пурпурным
    else if( g == max )
      h = 2.0 + cr - cb; // цвет между голубым и желтым
    else if( b == max )
      h = 4.0 + cg - cr; // цвет между пурпурным и голубым
    else
      h = 0; // fail_unexpected();

    h *= 60.0;
    if( h < 0 ) h += 360.0; // приведение к положительным величинам
  }

  return hsbcolor(h / 360.0, s, v);
}

float scale( float x, float a, float b, float c, float d ){
  return c + (d-c) * (x-a)/(b-a);
}

// Буфер для исходныъ путей к файлам.
class full_names_buffer{
public:
  full_names_buffer(){
    reset();
  }

  void reset(){
    for( int i = 0; i < MAX_DATA_NUM; ++i )
      _full_names[i][0] = '\0';
    _num = 0;
  }

  bool add_name( const char* fn ){
    if( _num >= MAX_DATA_NUM ){
      message("error: too many data files");
      return false;
    }
    strncpy(_full_names[_num], fn, MAX_PATH);
    _full_names[_num][MAX_PATH-1] = '\0';
    ++_num;
    return true;
  }

  const char* get_name( int idx ) const { return _full_names[idx]; }
  int num() const { return _num; }

private:
  int _num;
  char _full_names[MAX_DATA_NUM][MAX_PATH];
};

full_names_buffer full_names;

// storage

class data_storage {
public:
  data_storage() : _num(0)
  {
    for( int i = 0; i < MAX_DATA_NUM; ++i )
      _data[0]  = 0;
    _fnames[0] = '\0';
  }

  bool add( const char* fname );

  void done();

  int num() const { return _num; }

  const char* get_names() const { return _fnames; }

  int len( int k ) const { return _len[k]; }
  int max_len() const { return _max_len; }

  // возвращает значение отмасштабированное на отрезок [-0.5,0.5]
  double get_scaled( int k, int j ) const {
    return (_data[k][j] - min()) / (max() - min()) - 0.5;
  }

  double min() const { return (_min < _max) ? _min : _min - 1.0; }
  double max() const { return (_max > _min) ? _max : _max + 1.0; }

  double unscale( double v ) const {
    return min() + (v + 0.5)*(max() - min());
  }

  void reload(); // Перечитать файлы.

private:
  int _num;
  int _len[MAX_DATA_NUM];
  int _max_len;
  double _min, _max;
  double* _data[MAX_DATA_NUM];
  char _fnames[(MAX_DATA_NUM+1) * MAX_PATH]; // лишнее место резервируется под разделители

  bool read_file( const char* fn, int slot );
};

bool data_storage::read_file( const char* fname, int slot )
{
  FILE* txtfile = fopen(fname, "rt");
  if( txtfile == 0 ){
    message("error: can't open data file <%s>", fname);
    return false;
  }

  // пропускаем строку-заголовок
  if( fgetc(txtfile) != '#' )
    rewind(txtfile);
  else {
    while( 1 ){
      int ch = fgetc(txtfile);
      if( ch == EOF || ch == '\n' )
        break;
    }
  }
  int pos = ftell(txtfile);

  // считаем числа
  double buf;
  int sz = 0;
  while( fscanf(txtfile, "%lf", &buf) == 1 )
    sz++;
  if( sz == 0 ){
    message("error: can't read data from <%s>", fname);
    return false;
  }

  // заводим память
  _len[slot] = sz;
  _data[slot] = (double*)malloc(sz * sizeof(double));
  if( _data[slot] == 0 ){
    message("no more memory for data");
    return false;
  }

  // читаем данные
  fseek(txtfile, pos, SEEK_SET);
  for( int j = 0; j < sz; j++ ){
    fscanf(txtfile, "%lf", &buf);
    _data[slot][j] = buf;
  }
  fclose(txtfile);

  // считаем пределы изменения
  double min = _data[slot][0];
  double max = _data[slot][0];
  for( int j = 1; j < sz; j++ ){
    double v = _data[slot][j];
    if( v > max ) max = v;
    if( v < min ) min = v;
  }
  if( _num == 0 ){
    _min = min;
    _max = max;
  } else {
    _min = (min < _min) ? min : _min;
    _max = (max > _max) ? max : _max;
  }

  return true;
}

bool data_storage::add( const char* fname )
{
  char basename[_MAX_FNAME], ext[_MAX_EXT];

  if( _num >= MAX_DATA_NUM ){
    message("error: too many data files");
    return false;
  }
  if( _num != 0 )
    strcat(_fnames, ", ");
  _splitpath(fname, 0, 0, basename, ext);
  strcat(_fnames, basename);
  strcat(_fnames, ext);
  bool res = read_file(fname, _num);
  if( _num == 0 )
    _max_len = _len[_num];
  else
    _max_len = (_len[_num] > _max_len) ? _len[_num] : _max_len;
  ++_num;
  return res;
}

void data_storage::done()
{
  for( int j = 0; j < _num; j++ )
  {
    free(_data[j]);
    _data[j] = 0;
  }
  _num = 0;
  _fnames[0] = '\0';
}

data_storage data;

// window

#define DP 1 // size of pixel
#define HSHIFT 8

class data_window {
public:
  data_window() : _is_subpexel(false), _alpha_idx(0) {
    _pen = CreatePen(PS_SOLID, 1, RGB(0,0,0));
    _col_r = _col_g = _col_b = 0;
  }
  ~data_window(){
    DeleteObject(_pen);
  }

  void setup( HWND hw, HMENU hm ) {
    hwnd = hw; hmnu = hm;
    CheckMenuItem(hmnu, MNU_TRAN0 + _alpha_idx, MF_BYCOMMAND | MF_CHECKED);
  }

  void init( int x, int y, int th, HDC _hdc ) {
    xsize = x;
    ysize = y;
    text_height = th;
    hdc = _hdc;
  }

  // преобразование экранных пикселей в число [0; 1] относительно
  // начала координат графика
  double normed_x( int x ){
    return xsize != (2*HSHIFT+1) ? real_cast(x-HSHIFT) / (xsize - (2*HSHIFT+1)) : 0.;
  }
  double normed_y( int y ){
    int ysz = ysize - 2 * text_height - 1;
    return ysz ? real_cast(ysize-1 - y - text_height) / ysz : 0.;
  }

  void exit();
  void set_title( const char* );
  void set_aspoint( bool is_aspnt );
  void repaint();
  void grid();
  void point( double x, double y, bool is_line );
  void reset();

  void clear_rect( int l, int t, int r, int b );
  void puttext( int x, int y, const char* );
  void put_header_text( const char* );
  void put_footer_text( const char* );

  const char* get_saveas_name(
    const char* title, const char* filetype, const char* ext
  );

  void set_alpha( int alpha_idx );

  void swap_subpixel();
  void set_subpixel( bool );

  void set_color( int r, int g, int b ){
    _col_r = r;
    _col_g = g;
    _col_b = b;
    DeleteObject(_pen);
    _pen = CreatePen(PS_SOLID, 1, (b * 256 + g) * 256 + r);
  }

private:
  HWND hwnd;
  HMENU hmnu;
  int xsize, ysize, text_height;

  bool newpoint;
  double cx, cy;

  HDC hdc;
  bool _is_subpexel;
  int _alpha_idx;

  HPEN _pen;
  int _col_r, _col_g, _col_b;

  int X( double x ) const {
    return HSHIFT + int_cast(x * (xsize - (2*HSHIFT+1)));
  }
  int Y( double y ) const {
    int ysz = ysize - 2 * text_height - 1;
    return ysize - (text_height + 1 + int_cast(y * ysz));
  }

  COLORREF mk_rgb( double v );

  void pixel( double x, double y );
  void line_std( double x1, double y1, double x2, double y2 );
  void line_sp_i( int x1, int y1, int x2, int y2 );
  void line_sp( double x1, double y1, double x2, double y2 );

  void clear_header();
  void clear_footer();

  const char* create_filter( const char* filetype, const char* ext );
};

void data_window::exit()
{
  PostMessage(hwnd, WM_SYSCOMMAND, SC_CLOSE, 0);
}

void data_window::set_title( const char* title ){
  SetWindowText(hwnd, title);
}

void data_window::set_aspoint( bool is_aspnt ){
  UINT st = is_aspnt ? MF_CHECKED : MF_UNCHECKED;
  CheckMenuItem(hmnu, MNU_POINT, MF_BYCOMMAND | st);
}

void data_window::repaint(){
  InvalidateRect(hwnd, 0, TRUE);
}

void data_window::pixel( double x, double y ){
  int xs = X(x);
  int ys = Y(y);

//~   Ellipse(hdc, xs-DP, ys-DP, xs+DP, ys+DP);
  MoveToEx(hdc, xs-DP, ys, NULL);
  LineTo(hdc, xs+DP+1, ys);
  MoveToEx(hdc, xs, ys-DP, NULL);
  LineTo(hdc, xs, ys+DP+1);
}

inline int lmax( int x1, int x2 )
{
  return (x1 > x2) ? x1 : x2;
}

COLORREF data_window::mk_rgb( double v )
{
  rgbcolor rgb(_col_r/255.0, _col_g/255.0, _col_b/255.0);
  hsbcolor hsb = rgb2hsb(rgb);
  hsb.s = scale(v, 0.0, 1.0, hsb.s, 0.0);
  rgb = hsb2rgb(hsb);
  return RGB(int(255 * rgb.r), int(255 * rgb.g), int(255 * rgb.b));
}

void data_window::line_sp_i( int x1, int y1, int x2, int y2 )
{
  int len = lmax(labs(x2-x1), labs(y2-y1));
  double dx = real_cast(x2-x1) / real_cast(len);
  double dy = real_cast(y2-y1) / real_cast(len);

  int sdx = 1, sdy = 0;
  if( labs(x2-x1) > labs(y2-y1) ){
    sdx = 0;
    sdy = 1;
  }

  double x = x1;
  double y = y1;
  int endl = len+1;
  for( int j = 0; j < endl; j++ ){
    int ix = int_cast(x);
    int iy = int_cast(y);
    double v = (x - ix)*sdx + (y - iy)*sdy;
    // рисование идет черным цветом, поэтому пикселы меняются местами
    SetPixel(hdc, ix, iy, mk_rgb(v));
    SetPixel(hdc, ix + sdx, iy + sdy, mk_rgb(1-v));
    x += dx;
    y += dy;
  }
}

void data_window::line_sp( double x1, double y1, double x2, double y2 )
{
  line_sp_i(X(x1), Y(y1), X(x2), Y(y2));
}

void data_window::line_std( double x1, double y1, double x2, double y2 ){
  POINT dummy;
  MoveToEx(hdc, X(x1), Y(y1), &dummy);
  LineTo(hdc, X(x2), Y(y2));
}

void data_window::grid(){
  HPEN pen = CreatePen(PS_SOLID, 1, RGB(190,190,190));
  HGDIOBJ old_pen = SelectObject(hdc, pen);
  for( int j = 0; j < 11; j++ )
    line_std(real_cast(j) / 10.0, 0.0, real_cast(j) / 10.0, 1.0);
  for( int j = 0; j < 11; j++ )
    line_std(0.0, real_cast(j) / 10.0, 1.0, real_cast(j) / 10.0);
  //HGDIOBJ stdpen = GetStockObject(BLACK_PEN);
  SelectObject(hdc, old_pen);
  DeleteObject(pen);
}

void data_window::point( double x, double y, bool is_line ){
  HGDIOBJ old_pen = SelectObject(hdc, _pen);
  if( newpoint ){
    cx = x;
    cy = y;
    newpoint = false;
    if( !is_line )
      pixel(x, y);
  }else{
    if( is_line ){
      if( _is_subpexel )
        line_sp(cx, cy, x, y);
      else
        line_std(cx, cy, x, y);
    } else
      pixel(x, y);
    cx = x;
    cy = y;
  }
  SelectObject(hdc, old_pen);
}

void data_window::reset()
{
  newpoint = true;
}

void data_window::clear_rect( int l, int t, int r, int b )
{
  HPEN wp = (HPEN)GetStockObject(WHITE_PEN);
  HBRUSH wb = (HBRUSH)GetStockObject(WHITE_BRUSH);
  HPEN op = (HPEN)SelectObject(hdc, wp);
  HBRUSH ob = (HBRUSH)SelectObject(hdc, wb);
  Rectangle(hdc, l, t, r, b);
  SelectObject(hdc, op);
  SelectObject(hdc, ob);
}

void data_window::clear_header()
{
  clear_rect(0, 0, xsize-1, text_height);
}

void data_window::clear_footer()
{
  clear_rect(0, ysize - text_height, xsize-1, ysize);
}

void data_window::puttext( int x, int y, const char* str )
{
  TextOut(hdc, x, y, str, strlen(str));
}

void data_window::put_header_text( const char* str )
{
  clear_header();
  puttext(10, 0, str);
}

void data_window::put_footer_text( const char* str )
{
  clear_footer();
  puttext(10, ysize - text_height, str);
}

const char* data_window::create_filter( const char* filetype, const char* ext ){
  static char filter[MAX_PATH];
  sprintf(filter, "%s (*.%s)", filetype, ext);
  char* mask = filter + strlen(filter) + 1;
  sprintf(mask, "*.%s", ext);
  *(mask + strlen(mask) + 1) = 0;

  return filter;
}

const char* data_window::get_saveas_name(
  const char* title, const char* filetype, const char* ext
)
{
  static char filename[MAX_PATH];
  filename[0] = 0;

  OPENFILENAME fn;
  memset(&fn, 0, sizeof(fn));
  fn.lStructSize = sizeof(fn);
  fn.hwndOwner = hwnd;
  fn.lpstrFilter = create_filter(filetype, ext);
  fn.nFilterIndex = 1;             // 1-based index of the initial filter
  fn.lpstrFile = filename;
  fn.nMaxFile = sizeof(filename);  // size of initial filename buffer
  fn.lpstrDefExt = ext;
  fn.Flags = OFN_EXPLORER | OFN_HIDEREADONLY;
  fn.lpstrTitle = title;
  fn.Flags |= OFN_OVERWRITEPROMPT;

  if( GetSaveFileName(&fn) != TRUE )
    return 0;
  else
    return filename;
}

void data_window::set_alpha( int alpha_idx )
{
  CheckMenuItem(hmnu, MNU_TRAN0 + _alpha_idx, MF_BYCOMMAND | MF_UNCHECKED);
  _alpha_idx = alpha_idx;
  CheckMenuItem(hmnu, MNU_TRAN0 + _alpha_idx, MF_BYCOMMAND | MF_CHECKED);

#ifndef WS_EX_LAYERED
  #define WS_EX_LAYERED 0x80000
#endif

#ifndef LWA_ALPHA
  #define LWA_ALPHA 2
#endif

  // SetLayeredWindowAttributes() pointer.
  // Function resides in User32.dll
  typedef BOOL (WINAPI *FuncSLWA)(HWND hwnd, COLORREF key, BYTE alpha, DWORD flags);
  HMODULE hMod = GetModuleHandle("User32.dll");
  if( !hMod )
    return;
  FuncSLWA slwa = (FuncSLWA)GetProcAddress(hMod, "SetLayeredWindowAttributes");

  if( !slwa )
    return;

  LONG exstyle = GetWindowLong(hwnd, GWL_EXSTYLE);
  SetWindowLong(hwnd, GWL_EXSTYLE, exstyle | WS_EX_LAYERED);
  COLORREF cl = 0;
  slwa(hwnd, cl, 255 - alpha_idx * 50, LWA_ALPHA);
}

void data_window::swap_subpixel()
{
  _is_subpexel = !_is_subpexel;
  CheckMenuItem(hmnu, MNU_ANTIA, MF_BYCOMMAND | (_is_subpexel ? MF_CHECKED : MF_UNCHECKED));
  repaint();
}

void data_window::set_subpixel( bool sp )
{
  _is_subpexel = sp;
  CheckMenuItem(hmnu, MNU_ANTIA, MF_BYCOMMAND | (_is_subpexel ? MF_CHECKED : MF_UNCHECKED));
  repaint();
}

data_window window;

// EPS file

#define MM_PER_INCH    25.4  // миллиметров в дюйме
#define PSPT_PER_INCH  72.0  // пунктов в миллиметре

#define EPS_FONT_HEIGHT 4.0  // размер шрифта
#define EPS_LINE_WIDTH  0.01 // толщина линии сетки
#define DATA_LINE_WIDTH 0.2  // толщина линии графика
#define EPS_PIXEL_SIZE  0.2  // радиус пиксела

class eps_file {
public:
  eps_file( const char*, double w, double h );
  ~eps_file();

  void point( double x, double y, bool is_line );
  void reset() { newpoint = true; }

  void set_color( int r, int g, int b );

  void clip() { clip(0.0, 0.0, 1.0, 1.0); }
  void noclip();

  void puttext( const char*, bool top = false );

private:
  FILE* file;
  double _w, _h;

  bool newpoint;
  double cx, cy;

  double mm2pspt( double mm );

  double X( double x ) const {
    return 2.0 + x * (_w-4.0); // 2.0 - сдвиг слева, 4.0 = 2 * 2.0
  }
  double Y( double y ) const {
    double ysz = _h - 2 * EPS_FONT_HEIGHT;
    return EPS_FONT_HEIGHT + y * ysz;
  }

  void header( double width, double height );
  void trailer();

  // mm
  void setwidth( double w );
  void puts( double x, double y, const char* str );

  // условные единицы
  void clip( double x1, double y1, double x2, double y2 );
  void line( double x1, double y1, double x2, double y2 );
  void pixel( double x, double y );

  void grid();
};

eps_file::eps_file( const char* fn, double w, double h  ){
  file = fopen(fn, "wt");
  if( file == 0 ){
    message("error: can't create EPS file");
    return;
  }
  header(w, h);
  grid();
}

eps_file::~eps_file(){
  trailer();
  fclose(file);
}

void eps_file::grid(){
  setwidth(EPS_LINE_WIDTH);
  for( int j = 0; j < 11; j++ )
    line(real_cast(j) / 10.0, 0.0, real_cast(j) / 10.0, 1.0);
  for( int j = 0; j < 11; j++ )
    line(0.0, real_cast(j) / 10.0, 1.0, real_cast(j) / 10.0);
  setwidth(DATA_LINE_WIDTH);
}

double eps_file::mm2pspt( double mm ){
  return PSPT_PER_INCH * (mm / MM_PER_INCH);
}

void eps_file::header( double width, double height ){
  _w = width;
  _h = height;
  fprintf(file, "%%!PS-Adobe-2.0 EPSF-2.0\n");
  fprintf(file, "%%%%Pages: 0 0\n");
  fprintf(file, "%%%%BoundingBox: 0.0 0.0 %f %f\n", mm2pspt(width), mm2pspt(height));
  fprintf(file, "%%%%EndComments\n");
  fprintf(file, "0 0 translate\n");
  fprintf(file, "/Courier findfont\n");
  fprintf(file, "%f scalefont setfont\n", mm2pspt(EPS_FONT_HEIGHT));
  fprintf(file, "/pixel {%f 0 360 arc fill} def\n", mm2pspt(EPS_PIXEL_SIZE));
}

void eps_file::trailer(){
  fprintf(file, "showpage\n");
  fprintf(file, "%%%%Trailer\n");
}

void eps_file::setwidth( double w ){
  fprintf(file, "%f setlinewidth\n", mm2pspt(w));
}

void eps_file::clip( double x1, double y1, double x2, double y2 ){
  fprintf(file, "gsave\n");
  x1 = X(x1); x2 = X(x2);
  y1 = Y(y1); y2 = Y(y2);
  fprintf(file,
    "newpath %f %f moveto %f %f lineto %f %f lineto %f %f lineto closepath clip\n",
    mm2pspt(x1), mm2pspt(y1), mm2pspt(x2), mm2pspt(y1),
    mm2pspt(x2), mm2pspt(y2), mm2pspt(x1), mm2pspt(y2)
  );
}

void eps_file::noclip(){
  fprintf(file, "grestore\n");
}

void eps_file::set_color( int r, int g, int b )
{
  fprintf(file, "%.3f %.3f %.3f setrgbcolor\n", r/255.0, g/255.0, b/255.0);
}

void eps_file::line( double x1, double y1, double x2, double y2 ){
  x1 = X(x1); x2 = X(x2);
  y1 = Y(y1); y2 = Y(y2);
  fprintf(file,
    "newpath %f %f moveto %f %f lineto stroke\n",
    mm2pspt(x1), mm2pspt(y1), mm2pspt(x2), mm2pspt(y2)
  );
}

void eps_file::pixel( double x, double y ){
  x = X(x); y = Y(y);
  fprintf(file,
    "newpath %f %f pixel\n",
    mm2pspt(x), mm2pspt(y)
  );
}

void eps_file::puts( double x, double y, const char* str ){
  fprintf(file, "%f %f moveto (%s) show stroke\n", mm2pspt(x), mm2pspt(y), str);
}

void eps_file::point( double x, double y, bool is_line ){
  if( newpoint ){
    cx = x;
    cy = y;
    newpoint = false;
    if( !is_line )
      pixel(x, y);
  }else{
    if( is_line )
      line(cx, cy, x, y);
    else
      pixel(x, y);
    cx = x;
    cy = y;
  }
}

void eps_file::puttext( const char* str, bool top ){
  double y = top ? _h - EPS_FONT_HEIGHT : 0.0;
  puts(3.0, y+1.0, str); // 3.0 - сдвиг слева, 1.0 - сдвиг от базовой линии
}

// renderer

#define STARTSCRSIZE 100

class data_renderer {
public:
  data_renderer();

  void init( int st, int sz );
  void reset();
  void rescale();

  double x2idx( double x );
  double y2value( double y );

  void show_data();

  void grid( int num );
  void point( int step );
  void page( int num );
  void shift( double sh );
  void home();
  void end();
  void xscale( double mul );
  void yscale( double mul );
  void invmode();
  void fit();

  void export_to_eps( const char* fn );

private:
  int     start0, scrsize0;
  int     start, scrsize;
  double  ystart, _yscale;
  bool    showline;

  void set_asline( bool st = true );
};

void data_renderer::set_asline( bool st ){
  showline = st;
  window.set_aspoint(!showline);
}

data_renderer::data_renderer()
{
  ystart = 0.5;
  _yscale = 1.0;
  set_asline();
}

void data_renderer::init( int st, int sz ){
  start0 = start = st;
  scrsize0 = scrsize = sz;
}

void data_renderer::reset(){
  start = start0;
  scrsize = scrsize0;

  ystart = 0.5;
  _yscale = 1.0;
  set_asline();
}

void data_renderer::rescale(){
  scrsize = scrsize0;

  ystart = 0.5;
  _yscale = 1.0;
  set_asline();
}

// [0: 1] -> индекс в исходных данных
double data_renderer::x2idx( double x )
{
  return start + x * (scrsize-1);
}
// [0: 1] -> значение исходных данных
double data_renderer::y2value( double y )
{
  return data.unscale((y - ystart) / _yscale);
}

void data_renderer::show_data(){
  char title[TITLE_LEN];
  window.grid();
  sprintf(title, "%s - ldatav, ver. %s, (c) ltwood", data.get_names(), LDATAV_VER);
  window.set_title(title);

  for( int kk = 0; kk < data.num(); kk++ ){
    window.reset();
    window.set_color(colors[kk][0], colors[kk][1], colors[kk][2]);
    double dx = 1.0 / (scrsize-1);
    for( int k = 0; k < scrsize; k++ ){
      int pos = start + k;
      if( pos < 0 ) continue;
      if( pos >= data.len(kk) ) break;
      double y = data.get_scaled(kk, pos);
      window.point(k * dx, ystart + _yscale * y, showline);
    }
  }

  char buf[CAPTION_LEN];

  // Верхняя строка информации.

  // Видимый в окне диапазон значений.
  double y_min = y2value(0);
  double y_max = y2value(1);
  sprintf(buf, "Y: [%lg, %lg]  win=[%lg, %lg]  scale=%.3lf",
    data.min(), data.max(), y_min, y_max, _yscale);
  window.put_header_text(buf);

  // Нижняя строка информации.

  int len = data.num() > 0 ? data.len(0) : 0; // Длина первого набора данных.
  sprintf(buf, "X: len=%d [%d, %d]  win=%d  grid=%.2lf", len, start, start+scrsize-1, scrsize, scrsize/10.0);
  window.put_footer_text(buf);
}

void data_renderer::grid( int num ){
  int dx = scrsize / 10;
  if( dx != 0 )
    start += num * dx;
  else
    start += (num < 0) ? -1 : +1;
}

void data_renderer::point( int step ){
  start += step;
}

void data_renderer::page( int num ){
  start += num * scrsize;
}

void data_renderer::shift( double sh ){
  ystart += sh;
}

void data_renderer::home(){
  start = 0;
}

void data_renderer::end(){
  start = data.max_len() - scrsize;
}

void data_renderer::xscale( double mul ){
  scrsize = int_cast(scrsize * mul);
  if( scrsize < 3 )
    scrsize = 3;
}

void data_renderer::yscale( double mul ){
  if( _yscale * mul > 128.0 + 1.0 ) return;
  if( _yscale * mul < 0.1 ) return;
  _yscale *= mul;
  ystart = 0.5 - mul * (0.5 - ystart);
}

void data_renderer::invmode(){
  showline = !showline;
  window.set_aspoint(!showline);
}

void data_renderer::fit(){
  rescale();
  start = 0;
  scrsize = data.max_len();
}

void data_renderer::export_to_eps( const char* fn ){
  eps_file eps(fn, 150, 100);

  eps.clip();
  for( int kk = 0; kk < data.num(); kk++ ){
    eps.reset();
    eps.set_color(colors[kk][0], colors[kk][1], colors[kk][2]);
    double dx = 1.0 / (scrsize-1);
    for( int k = 0; k < scrsize; k++ ){
      int pos = start + k;
      if( pos < 0 ) continue;
      if( pos >= data.len(kk) ) break;
      double y = data.get_scaled(kk, pos);
      eps.point(k * dx, ystart + _yscale * y, showline);
    }
  }
  eps.noclip();
  eps.set_color(0, 0, 0);

  char buf[CAPTION_LEN];
  sprintf(buf, "Y: [%lg, %lg]", data.min(), data.max());
  eps.puttext(buf, true);
  sprintf(buf, "X: [%d, %d]  win=%d  grid=%.2lf", start, start+scrsize-1, scrsize, scrsize/10.0);
  eps.puttext(buf);
}

data_renderer renderer;

// keyboard

void kb_esc(){
  window.exit();
}

void kb_left(){
  renderer.grid(-1);
  window.repaint();
}

void kb_right(){
  renderer.grid(+1);
  window.repaint();
}

void kb_cleft(){
  renderer.point(-1);
  window.repaint();
}

void kb_cright(){
  renderer.point(+1);
  window.repaint();
}

void kb_up(){
  renderer.shift(-0.1);
  window.repaint();
}

void kb_down(){
  renderer.shift(+0.1);
  window.repaint();
}

void kb_cup(){
  renderer.shift(-0.01);
  window.repaint();
}

void kb_cdown(){
  renderer.shift(+0.01);
  window.repaint();
}

void kb_pgup(){
  renderer.page(-1);
  window.repaint();
}

void kb_pgdn(){
  renderer.page(+1);
  window.repaint();
}

void kb_home(){
  renderer.home();
  window.repaint();
}

void kb_end(){
  renderer.end();
  window.repaint();
}

void kb_ins(){
  renderer.xscale(DIV);
  window.repaint();
}

void kb_del(){
  renderer.xscale(MUL);
  window.repaint();
}

void kb_plus(){
  renderer.yscale(MUL);
  window.repaint();
}

void kb_minus(){
  renderer.yscale(DIV);
  window.repaint();
}

void kb_mul(){
  renderer.invmode();
  window.repaint();
}

void kb_div(){
  renderer.rescale();
  window.repaint();
}

void kb_reset(){
  renderer.reset();
  window.repaint();
}

void kb_fit(){
  renderer.fit();
  window.repaint();
}

void kb_reload(){
  data.done();
  for( int j = 0; j < full_names.num(); j++ ){
    if( !data.add(full_names.get_name(j)) ){
      window.exit();
      return;
    }
  }
  window.repaint();
}

void kb_export(){
  const char* fn = window.get_saveas_name("Export to EPS", "Encapsulated Postscript", "eps");
  if( fn != 0 )
    renderer.export_to_eps(fn);
}

void kb_antia()
{
  window.swap_subpixel();
}

void kb_tran( int t )
{
  window.set_alpha(t);
}

// win handlers

void OnPaint( HWND hwnd ){
  PAINTSTRUCT ps;
  HDC dc = BeginPaint(hwnd, &ps);
  SelectObject(dc, GetStockObject(BLACK_BRUSH));

  HFONT fnt = (HFONT)GetStockObject(ANSI_VAR_FONT);
  SelectObject(dc, fnt);

  TEXTMETRIC tm;
  GetTextMetrics(dc, &tm);

  RECT client;
  GetClientRect(hwnd, &client);

  window.init(client.right-client.left, client.bottom-client.top, tm.tmHeight, dc);
  renderer.show_data();

  EndPaint(hwnd, &ps);
}

void OnDestroy( HWND hwnd ){
  PostQuitMessage(0);
}

void OnMouseMove( HWND hwnd, SHORT x, SHORT y, UINT state )
{
  HDC dc = GetDC(hwnd);
  SelectObject(dc, GetStockObject(BLACK_BRUSH));

  HFONT fnt = (HFONT)GetStockObject(ANSI_VAR_FONT);
  SelectObject(dc, fnt);

  TEXTMETRIC tm;
  GetTextMetrics(dc, &tm);

  RECT client;
  GetClientRect(hwnd, &client);
  int client_width = client.right-client.left;
  int client_height = client.bottom-client.top;

  window.init(client_width, client_height, tm.tmHeight, dc);

  // будем показывать координаты мыши
  static SIZE last_text_size = {0, 0};
  // стереть старый текст
  window.clear_rect(client.right - last_text_size.cx - 10, 0, client.right, last_text_size.cy);

  char buf[CAPTION_LEN];
  sprintf(buf, "%g, %g",
    renderer.x2idx(window.normed_x(x)), renderer.y2value(window.normed_y(y))
  );
  GetTextExtentPoint32(dc, buf, strlen(buf), &last_text_size);
  window.puttext(client.right - last_text_size.cx - 10, 0, buf);

  ReleaseDC(hwnd, dc);
}

void OnCommand( HWND hwnd, int wp, HWND lp1, UINT lp2 ){
  switch( wp ){
    case MNU_RESET:   kb_reset();     break;
    case MNU_FIT:     kb_fit();       break;
    case MNU_RELOAD:  kb_reload();    break;
    case MNU_HOME:    kb_home();      break;
    case MNU_PGUP:    kb_pgup();      break;
    case MNU_LEFT:    kb_left();      break;
    case MNU_CLEFT:   kb_cleft();     break;
    case MNU_CRIGHT:  kb_cright();    break;
    case MNU_RIGHT:   kb_right();     break;
    case MNU_PGDN:    kb_pgdn();      break;
    case MNU_END:     kb_end();       break;
    case MNU_POINT:   kb_mul();       break;
    case MNU_UP:      kb_up();        break;
    case MNU_CUP:     kb_cup();       break;
    case MNU_CDN:     kb_cdown();     break;
    case MNU_DN:      kb_down();      break;
    case MNU_RESCALE: kb_div();       break;
    case MNU_INS:     kb_ins();       break;
    case MNU_DEL:     kb_del();       break;
    case MNU_PLUS:    kb_plus();      break;
    case MNU_MINUS:   kb_minus();     break;
    case MNU_QUIT:    kb_esc();       break;
    case MNU_EXPORT:  kb_export();    break;

    case MNU_ANTIA:   kb_antia();     break;
    case MNU_TRAN0:   kb_tran(0);     break;
    case MNU_TRAN1:   kb_tran(1);     break;
    case MNU_TRAN2:   kb_tran(2);     break;
    case MNU_TRAN3:   kb_tran(3);     break;
    case MNU_TRAN4:   kb_tran(4);     break;
  }
}

void OnKeyDown( HWND hwnd, UINT vk, BOOL down, int rep, UINT flags ){
  int ctrl = GetKeyState(VK_CONTROL) & 0x8000;
  switch( vk ){
    case VK_ESCAPE: kb_esc();   break;
    case VK_RIGHT:
      if( ctrl )
          kb_cright();
        else
          kb_right();
      break;
    case VK_LEFT:
      if( ctrl )
          kb_cleft();
        else
          kb_left();
      break;
    case VK_UP:
      if( ctrl )
          kb_cup();
        else
          kb_up();
      break;
    case VK_DOWN:
      if( ctrl )
          kb_cdown();
        else
          kb_down();
      break;
    case VK_NEXT:     kb_pgdn();  break;
    case VK_PRIOR:    kb_pgup();  break;
    case VK_HOME:     kb_home();  break;
    case VK_END:      kb_end();   break;
    case VK_INSERT:   kb_ins();   break;
    case VK_DELETE:   kb_del();   break;
    case VK_ADD:      kb_plus();  break;
    case VK_SUBTRACT: kb_minus(); break;
    case VK_MULTIPLY: kb_mul();   break;
    case VK_DIVIDE:
      if( ctrl )
          kb_reset();
        else
          kb_div();
      break;
    case VK_F5:       kb_fit();   break;
    case 'R':
      if( ctrl )
          kb_reload();
      break;
  }
}

LRESULT CALLBACK winproc( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam ){
  switch( uMsg ){
    case WM_PAINT:   return HANDLE_WM_PAINT(hwnd, wParam, lParam, OnPaint);
    case WM_MOUSEMOVE: return HANDLE_WM_MOUSEMOVE(hwnd, wParam, lParam, OnMouseMove);
    case WM_KEYDOWN: return HANDLE_WM_KEYDOWN(hwnd, wParam, lParam, OnKeyDown);
    case WM_DESTROY: return HANDLE_WM_DESTROY(hwnd, wParam, lParam, OnDestroy);
    case WM_COMMAND: return HANDLE_WM_COMMAND(hwnd, wParam, lParam, OnCommand);
    default:         return DefWindowProc(hwnd, uMsg, wParam, lParam);
  }
}

// win class

#define WINDOW_CLASS "win-data-viewer"

bool registerclass()
{
  WNDCLASS wndclass;

  wndclass.style         = CS_HREDRAW | CS_VREDRAW;
  wndclass.lpfnWndProc   = winproc;
  wndclass.cbClsExtra    = 0;
  wndclass.cbWndExtra    = sizeof(void*);
  wndclass.hInstance     = GetModuleHandle(0);
  wndclass.hIcon         = 0;
  wndclass.hCursor       = LoadCursor(0, IDC_CROSS);
  wndclass.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
  wndclass.lpszMenuName  = NULL;
  wndclass.lpszClassName = WINDOW_CLASS;

  if( !RegisterClass(&wndclass) ){
    message("error: failed to register class");
    return false;
  }
  return true;
}

// menu

void setmenu( HMENU mnu )
{
  HMENU act = CreatePopupMenu();
  AppendMenu(act, MF_ENABLED, MNU_RESCALE, "Reset &Scale\t[Gray/]");
  AppendMenu(act, MF_ENABLED, MNU_RESET,   "&Reset All\t[Ctrl+Gray/]");
  AppendMenu(act, MF_ENABLED, MNU_FIT,     "&Fit Data\tF5");
  AppendMenu(act, MF_ENABLED, MNU_RELOAD,  "Re&load files\tCtrl-R");
  AppendMenu(act, MF_ENABLED, MNU_EXPORT,  "&Export to EPS");
  AppendMenu(act, MF_SEPARATOR, 0, 0);
  AppendMenu(act, MF_ENABLED, MNU_QUIT,    "&Quit\t[Esc]");

  HMENU xpos = CreatePopupMenu();
  AppendMenu(xpos, MF_ENABLED, MNU_HOME,   "&Home\t[Home]");
  AppendMenu(xpos, MF_ENABLED, MNU_PGUP,   "Page Left\t[PgUp]");
  AppendMenu(xpos, MF_ENABLED, MNU_LEFT,   "Grid &Left\t[Left]");
  AppendMenu(xpos, MF_ENABLED, MNU_CLEFT,  "Point Left\t[Ctrl+Left]");
  AppendMenu(xpos, MF_ENABLED, MNU_CRIGHT, "Point Right\t[Ctrl+Right]");
  AppendMenu(xpos, MF_ENABLED, MNU_RIGHT,  "Grid &Right\t[Right]");
  AppendMenu(xpos, MF_ENABLED, MNU_PGDN,   "Page Right\t[PgDn]");
  AppendMenu(xpos, MF_ENABLED, MNU_END,    "&End\t[End]");

  HMENU ypos = CreatePopupMenu();
  AppendMenu(ypos, MF_ENABLED, MNU_UP,     "Grid &Up\t[Up]");
  AppendMenu(ypos, MF_ENABLED, MNU_CUP,    "Point Up\t[Ctrl+Up]");
  AppendMenu(ypos, MF_ENABLED, MNU_CDN,    "Point Down\t[Ctrl+Down]");
  AppendMenu(ypos, MF_ENABLED, MNU_DN,     "Grid &Down\t[Down]");

  HMENU sc = CreatePopupMenu();
  AppendMenu(sc, MF_ENABLED, MNU_INS,    "Horz Zoom &In\t[Ins]");
  AppendMenu(sc, MF_ENABLED, MNU_DEL,    "Horz Zoom &Out\t[Del]");
  AppendMenu(sc, MF_ENABLED, MNU_PLUS,   "Vert Zoom In\t[Gray+]");
  AppendMenu(sc, MF_ENABLED, MNU_MINUS,  "Vert Zoom Out\t[Gray-]");

  HMENU vi = CreatePopupMenu();
  AppendMenu(vi, MF_ENABLED, MNU_POINT,  "As &Points\t[Gray*]");
  AppendMenu(vi, MF_ENABLED, MNU_ANTIA,  "Use &Antialisasing");
  AppendMenu(vi, MF_SEPARATOR, 0, 0);
  AppendMenu(vi, MF_ENABLED, MNU_TRAN0,  "&No Trabsparency");
  AppendMenu(vi, MF_ENABLED, MNU_TRAN1,  "Trabsparency &20%");
  AppendMenu(vi, MF_ENABLED, MNU_TRAN2,  "Trabsparency &40%");
  AppendMenu(vi, MF_ENABLED, MNU_TRAN3,  "Trabsparency &60%");
  AppendMenu(vi, MF_ENABLED, MNU_TRAN4,  "Trabsparency &80%");

  AppendMenu(mnu, MF_POPUP, (UINT)act,  "&Actions");
  AppendMenu(mnu, MF_POPUP, (UINT)xpos, "&X-Pos");
  AppendMenu(mnu, MF_POPUP, (UINT)ypos, "&Y-Pos");
  AppendMenu(mnu, MF_POPUP, (UINT)sc,   "&Scale");
  AppendMenu(mnu, MF_POPUP, (UINT)vi,   "&Visualisation");
}

// WinMain

bool is_opt( const char* s )
{
  return strlen(s) >= 2 && s[0] == '-' && isalpha(s[1]);
}

int count_arg()
{
  int res = 0;
  for( int j = 1; j < _argc; j++ ){
    if( !is_opt(_argv[j]) )
      res++;
  }
  return res;
}

const char* get_arg( int k )
{
  int arg_num = count_arg();
  if( k < 0 || k > arg_num - 1 )
    return 0;

  int j, k1 = 0;
  for( j = 1; j < _argc; j++ ){
    if( !is_opt(_argv[j]) ){
      if( k1 == k )
        break;
      ++k1;
    }
  }
  return _argv[j];
}

// возвращает -1, если опция не найдена
int get_opt_pos( char ch )
{
  for( int j = 1; j < _argc; j++ ){
    if( is_opt(_argv[j]) && _argv[j][1] == ch )
      return j;
  }
  return -1;
}

const char* get_opt( char ch )
{
  int k = get_opt_pos(ch);
  if( k == -1 )
    return 0;
  char *res = _argv[k] + 2;  // skip '-<ch>'
  if( *res == ':' || *res == '=' ) res++;
  return res;
}

int __stdcall WinMain(
  HINSTANCE hInstance, HINSTANCE hPrevInstance,
  LPSTR lpszCmdLine, int nCmdShow )
{
  int scrsize = 0; // чтобы обозначить Fit as default
  int start = 0;

  int data_num = count_arg();
  if( data_num < 1 ){
    message("usage: ldatav [-x:xpos] [-y:ypos] [-w:width] [-h:height] [-l:len] [-s:pos] [-t:alpha] [-a] datafile ...");
    return 1;
  }

  if( get_opt('l') ){
    if( sscanf(get_opt('l'), "%d", &scrsize) != 1 || scrsize < 0 ){
      message("error: incorrect parameter in option '-l'");
      return 1;
    }
  }
  if( get_opt('s') ){
    if( sscanf(get_opt('s'), "%d", &start) != 1 ){
      message("error: incorrect parameter in option '-s'");
      return 1;
    }
  }

  int alpha_idx = 0;
  if( get_opt('t') ){
    if( sscanf(get_opt('t'), "%d", &alpha_idx) != 1 || alpha_idx < 0 || alpha_idx > 4 ){
      message("error: incorrect parameter in option '-a'");
      return 1;
    }
  }
  if( get_opt('a') )
    window.set_subpixel(true);

  RECT dt_rect;
  SystemParametersInfo(SPI_GETWORKAREA, 0, &dt_rect, 0);

  int x0 = int_cast(0.5 * (1.0 - WIN_DEF_WIDTH) * (dt_rect.right - dt_rect.left));
  int y0 = int_cast(0.5 * (1.0 - WIN_DEF_HEIGHT) * (dt_rect.bottom - dt_rect.top));
  if( get_opt('x') ){
    if( sscanf(get_opt('x'), "%d", &x0) != 1  ){
      message("error: incorrect parameter in option '-x'");
      return 1;
    }
  }
  if( get_opt('y') ){
    if( sscanf(get_opt('y'), "%d", &y0) != 1  ){
      message("error: incorrect parameter in option '-y'");
      return 1;
    }
  }

  int w = int_cast(WIN_DEF_WIDTH * (dt_rect.right - dt_rect.left));
  int h = int_cast(WIN_DEF_HEIGHT * (dt_rect.bottom - dt_rect.top));
  if( get_opt('w') ){
    if( sscanf(get_opt('w'), "%d", &w) != 1  ){
      message("error: incorrect parameter in option '-w'");
      return 1;
    }
  }
  if( get_opt('h') ){
    if( sscanf(get_opt('h'), "%d", &h) != 1  ){
      message("error: incorrect parameter in option '-h'");
      return 1;
    }
  }

  renderer.init(start, scrsize == 0 ? STARTSCRSIZE : scrsize);

  for( int j = 0; j < data_num; j++ ){
    const char* dfn = get_arg(j);
    if( !(data.add(dfn) && full_names.add_name(dfn)) )
      return 1;
  }

  // Fit, если ноль или не указано; startpos игнорируется
  if( scrsize == 0 )
    renderer.fit();

  if( !registerclass() ) return 1;
  HMENU mnu = CreateMenu();
  setmenu(mnu);
  HWND hwnd = CreateWindow(
    WINDOW_CLASS, "", WS_OVERLAPPEDWINDOW,
    x0, y0, w, h,
    NULL, mnu, GetModuleHandle(0), 0
  );
  if( !hwnd ){
    message("error: failed to create window");
    return 1;
  }

  SetClassLong(hwnd, GCL_HICON, (LONG) LoadIcon(hInstance, "mainicon"));

  window.setup(hwnd, mnu);
  if( alpha_idx != 0 )
    window.set_alpha(alpha_idx);
  ShowWindow(hwnd, SW_SHOW);

  MSG msg;
  while( GetMessage(&msg, 0, 0, 0) > 0 ){
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  data.done();
  return 0;
}
