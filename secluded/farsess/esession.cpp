// Сохранение и восстановление сессии редактирования
// (c) ltwood, 2005/01/02
// (c) ltwood, 2005/05/31

#include "plugin.hpp"

#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <io.h>

//// утилиты

// проверка наличия файла с заданным именем
bool file_exists( const char* fname )
{
  return (access(fname, 0) == 0);
}

// получение полного имени для файла
void file_expand( char* buf, const char* fname )
{
  char* _p;
  GetFullPathName(fname, 1024, buf, &_p);
}

// отладочный вывод в DebugString
void zzz( const char *fmt, ... )
{
  char buf[1024];
  strcpy(buf, "far: ");
  va_list va;
  va_start(va, fmt);
  vsprintf(buf + strlen(buf), fmt, va);
  va_end(va);
  OutputDebugString(buf);
}

//// номера сообщений из файла ресурсов

#define MSG_PLUGIN_NAME     0
#define MSG_CREATE          1
#define MSG_LOAD            2
#define MSG_SAVE            3
#define MSG_CLOSE           4
#define MSG_SAVEALL         5
#define MSG_ABOUT           6

#define MSG_NOSESSIONFILE   7
#define MSG_FILEEXISTS      8
#define MSG_NOACTIVESESSION 9
#define MSG_ALREADYACTIVE   10
#define MSG_NOEDITORS       11
#define MSG_EDITORBUSY      12

//// singletone far_env

class far_env {
public:
  // получение экземпляра
  static far_env& inst() { return _inst; }

  // инициализация при старте
  void set_startup( const PluginStartupInfo* psi );

  // получение строки из ресурса
  const char *get_msg( int id ) const;

  // вывод меню
  int show_menu( const char* title, const FarMenuItem* items, int num ) const;

  // вывод сообщения об ошибке
  void show_error( const char* msg );

  // вывод сообщения с заданным числом строк
  // последние bnum строк интерпретируются как кнопки
  void show_message( const char* items[], int num, int bnum );

  // открыть обычный редактор
  bool edt_open( const char* fn );

  // получение информации о текущем активном окне редактирования
  bool edt_getinfo( EditorInfo& ei ) const;

  // установка позиции в текущем активном окне редактирования
  bool edt_setpos( EditorSetPosition esp ) const;

  // сохранить текст в текущем активном окне редактирования
  bool edt_save() const;

  // закрыть текущее активное окно редактирования
  bool edt_close();

  // активизация окна по номеру
  bool win_select( int pos );

  // получение количества окон
  int win_num() const;

  // получение информации об окне
  bool win_getinfo( WindowInfo& wi, int idx ) const;

private:
  static far_env _inst; // представитель

  far_env(){} // синглетон нельзя создавать

  PluginStartupInfo _info;
};

far_env far_env::_inst;

void far_env::set_startup( const PluginStartupInfo* psi )
{
  _info = *psi;
}

const char* far_env::get_msg( int id ) const
{
  return _info.GetMsg(_info.ModuleNumber, id);
}

int far_env::show_menu( const char* title, const FarMenuItem* items, int num ) const
{
  return _info.Menu(
    _info.ModuleNumber,
    -1, -1,                                  /*X, Y*/
    0,                                       /*MaxHeight*/
    FMENU_WRAPMODE | FMENU_AUTOHIGHLIGHT,    /*Flags*/
    title,                                   /*Top Title*/
    0,                                       /*Bottom title*/
    0,                                       /*HelpTopic*/
    0,                                       /*BreakKeys*/
    0,                                       /*BreakCode*/
    items,                                   /*Items*/
    num                                      /*ItemsNumber*/
  );
}

void far_env::show_error( const char* msg )
{
  static const char* items[] = {
    "Error",
    "",
    "Ok",
  };
  items[1] = msg;

  _info.Message(
    _info.ModuleNumber,
    FMSG_WARNING,       // Flags
    0,                  // HelpTopic
    items,
    sizeof(items)/sizeof(items[0]),
    1                   // ButtonsNumber
  );
}

void far_env::show_message( const char* items[], int num, int bnum )
{
  _info.Message(
    _info.ModuleNumber,
    0      /*Flags*/,
    0      /*HelpTopic*/,
    items,
    num,   /*ItemsNumber*/
    1      /*ButtonsNumber*/
  );
}

bool far_env::edt_getinfo( EditorInfo& ei ) const
{
  return _info.EditorControl(ECTL_GETINFO, &ei) == TRUE;
}

bool far_env::edt_open( const char* fn )
{
  if( !file_exists(fn) )
    return false;
  int res = _info.Editor(
    fn,    // file name
    0,     // std title
    0, 0, -1, -1, // X1, Y1, X2, Y2; full screen
    EF_NONMODAL | EF_IMMEDIATERETURN | EF_ENABLE_F6, // normal editor
    0, 0   // line, column; initial pos
  );
  if( res == EEC_OPEN_ERROR || res == EEC_LOADING_INTERRUPTED )
    return false;
  return true;
}

bool far_env::edt_setpos( EditorSetPosition esp ) const
{
  return _info.EditorControl(ECTL_SETPOSITION, &esp) != TRUE;
}

bool far_env::edt_save() const
{
  return _info.EditorControl(ECTL_SAVEFILE, 0/*current mode*/) == TRUE;
}

bool far_env::edt_close()
{
  if( _info.EditorControl(ECTL_QUIT, 0/*no mean*/) != TRUE )
    return false;
  if( _info.AdvControl(_info.ModuleNumber, ACTL_COMMIT, 0/*no mean*/) != TRUE)
    return false;
  return true;
}

bool far_env::win_select( int pos )
{
  if( _info.AdvControl(_info.ModuleNumber, ACTL_SETCURRENTWINDOW, (void*)pos) != TRUE )
    return false;
  if( _info.AdvControl(_info.ModuleNumber, ACTL_COMMIT, 0/*no mean*/) != TRUE)
    return false;
  return true;
}

int far_env::win_num() const
{
  return _info.AdvControl(_info.ModuleNumber, ACTL_GETWINDOWCOUNT, 0);
}

bool far_env::win_getinfo( WindowInfo& wi, int idx ) const
{
  wi.Pos = idx;
  return _info.AdvControl(_info.ModuleNumber, ACTL_GETWINDOWINFO, &wi) == TRUE;
}

//// editor operations

void save_all_files()
{
  // save current window
  WindowInfo wi;
  far_env::inst().win_getinfo(wi, -1);
  int cur_pos = wi.Pos;

  int win_num = far_env::inst().win_num();
  for( int j = 0; j < win_num; j++ ){
    if( !far_env::inst().win_getinfo(wi, j) )
      continue;
    if( wi.Type == WTYPE_EDITOR && wi.Modified ){
      // здесь нигде нет проверок успешности, поскольку достаточно просто попытки
      // кстати, значение, возвращаемое при ACTL_COMMIT похоже не имеет смысла
      far_env::inst().win_select(j);
      far_env::inst().edt_save();
    }
  }

  // restore current window
  far_env::inst().win_select(cur_pos);
}

void close_all_files()
{
  // save current window
  int cur_pos = -1;
  WindowInfo wi;
  if( far_env::inst().win_getinfo(wi, -1) )
    if( wi.Type != WTYPE_EDITOR )
      cur_pos = wi.Pos;

  int act_num;
  do{
    int win_num = far_env::inst().win_num();
    act_num = 0;
    for( int j = 0; j < win_num; j++ ){
      if( !far_env::inst().win_getinfo(wi, j) )
        continue;
      if( wi.Type == WTYPE_EDITOR ){
        far_env::inst().win_select(j);
        far_env::inst().edt_close();
        act_num++;
        break;
      }
    }
  }while( act_num );

  // restore current window
  if( cur_pos != -1 )
    far_env::inst().win_select(cur_pos);
}

//// singletone edt_list

// Информация об окне редактирования
struct edt_info {
  int id;
  char* fn;
  EditorSetPosition pos; // int CurLine, CurPos, CurTabPos, TopScreenLine, LeftPos, Overtype

  edt_info(){
    id = -1;  // неиспользуемый элемент
  }

  void set( const EditorInfo& ei ){
    id = ei.EditorID;
    fn = strdup(ei.FileName);
    upd(ei);
  }

  void upd( const EditorInfo& ei ){
    pos.CurLine = ei.CurLine;
    pos.CurPos = ei.CurPos;
    pos.CurTabPos = ei.CurTabPos;
    pos.TopScreenLine = ei.TopScreenLine;
    pos.LeftPos = ei.LeftPos;
    pos.Overtype = ei.Overtype;
  }
};

// размер таблицы файлов
// это в 8 раз больше, чем реально бывает открыто файлов ;)
// и при таком размере массива линейный поиск -- лучшее решение ;))

const int MAXEDITS = 64;

// список окон редактирования
class edt_list {
public:
  static edt_list& inst() { return _inst; } // получение экземпляра

  void add( const EditorInfo& ei );
  void del( int id );
  void upd( const EditorInfo& ei );

  bool save( const char* fname ) const;

  int len() const { return _fnum; }

private:
  static edt_list _inst; // представитель

  edt_info _edits[MAXEDITS];
  int _fnum;

  // поиск в таблице производится при каждом событии от редактора,
  // поэтому простое кэширование результатов последнего поиска
  // существенно повышает произодительность.
  mutable int _last_id, _last_idx;

  edt_list() {   // синглетон нельзя создавать
    _fnum = 0;      // количество файлов
    _last_id = -1;  // аргумент последнего поиска
    _last_idx = -1; // результат последнего поиска
  }

  int search_empty() const;
  int search( int id ) const;
};

edt_list edt_list::_inst;

// поиск в таблице свободного слота
int edt_list::search_empty() const
{
  int j;
  for( j = 0; j < MAXEDITS; j++ ){
    if( _edits[j].id == -1 )
      break;
  }
  if( j < MAXEDITS )
    return j;
  else
    return -1;
}

// поиск в таблице открытых редакторов
int edt_list::search( int id ) const
{
  if( id == _last_id )
    return _last_idx;

  int j;
  for( j = 0; j < MAXEDITS; j++ )
    if( _edits[j].id == id )
      break;
  if( j < MAXEDITS ){
    _last_id = id;
    _last_idx = j;
    return j;
  }else
    return -1;
}

void edt_list::add( const EditorInfo& ei )
{
  int idx = search_empty();
  if( idx == -1 )
    return;
  _edits[idx].set(ei);
  ++_fnum;
}

void edt_list::del( int id )
{
  int idx = search(id);
  if( idx == -1 )
    return;
  free(_edits[idx].fn);
  _edits[idx].id = -1;
  --_fnum;
}

void edt_list::upd( const EditorInfo& ei )
{
  int idx = search(ei.EditorID);
  if( idx == -1 )
    return;
  _edits[idx].upd(ei);
}

bool edt_list::save( const char* fname ) const
{
  FILE *file = fopen(fname, "wt");
  if( file == 0 )
    return false;
  for( int j = 0; j < MAXEDITS; j++ ){
    if( _edits[j].id == -1 )
      continue;
    EditorSetPosition pos = _edits[j].pos;
    fprintf(file, "%s\x7%d\x7%d\x7%d\x7%d\x7%d\x7%d\x7\n",
      _edits[j].fn,
      pos.CurLine, pos.CurPos, pos.CurTabPos,
      pos.TopScreenLine, pos.LeftPos, pos.Overtype
    );
  }
  fclose(file);
  return true;
}

//// status file

const char FILENAME[] = "esession.far";

class status {
public:
  static status& inst() { return _inst; }

  void pinup();
  void close() { _is_act = false; }

  bool save( bool overwrite );
  bool load();

  bool is_act() const { return _is_act; }

private:
  static status _inst;

  status(){
    _is_act = false;
  }

  const char* status::parse_line( char* line, EditorSetPosition& esp ) const;

  char _fname[1024];
  bool _is_act;
};

status status::_inst;

void status::pinup()
{
  file_expand(_fname, FILENAME);
  _is_act = true;
}

bool status::save( bool overwrite )
{
  if( !overwrite && file_exists(_fname) ){
    far_env::inst().show_error(far_env::inst().get_msg(MSG_FILEEXISTS));
    return false;
  }

  return edt_list::inst().save(_fname);
}

bool status::load()
{
  if( !file_exists(_fname) ){
    far_env::inst().show_error(far_env::inst().get_msg(MSG_NOSESSIONFILE));
    return false;
  }

  // save current window
  WindowInfo wi;
  far_env::inst().win_getinfo(wi, -1);
  int cur_pos = wi.Pos;

  FILE *file = fopen(_fname, "rt");
  if( file == 0 )
    return false;
  static char buf[1024];
  while( fgets(buf, 1024, file) ){
    EditorSetPosition esp;
    const char* fn = parse_line(buf, esp);
    if( fn != 0 && far_env::inst().edt_open(fn) )
      far_env::inst().edt_setpos(esp);
  }
  fclose(file);

  // restore current window
  far_env::inst().win_select(cur_pos);

  return true;
}

const char* status::parse_line( char* line, EditorSetPosition& esp ) const
{
  char* p = line;
  char* pp = strchr(p, '\x7');
  if( pp == 0 ) return 0;
  *pp = 0;
  char* fn = p;
  p = pp + 1;
  int nums[6];
  for( int j = 0; j < 6; j++ ){
    pp = strchr(p, '\x7');
    if( pp == 0 ) return 0;
    *pp = 0;
    if( sscanf(p, "%d", nums + j) != 1 )
      return 0;
    p = pp + 1;
  }

  esp.CurLine = nums[0];
  esp.CurPos = nums[1];
  esp.CurTabPos = nums[2];
  esp.TopScreenLine = nums[3];
  esp.LeftPos = nums[4];
  esp.Overtype = nums[5];

  return fn;
}

//// session

void session_create()
{
  if( status::inst().is_act() ){
    far_env::inst().show_error(far_env::inst().get_msg(MSG_ALREADYACTIVE));
    return;
  }
  if( edt_list::inst().len() == 0 ){
    far_env::inst().show_error(far_env::inst().get_msg(MSG_NOEDITORS));
    return;
  }
  status::inst().pinup();
  if( !status::inst().save(false/*overwrite*/) )
    status::inst().close();
}

void session_load()
{
  if( status::inst().is_act() ){
    far_env::inst().show_error(far_env::inst().get_msg(MSG_ALREADYACTIVE));
    return;
  }
  if( edt_list::inst().len() != 0 ){
    far_env::inst().show_error(far_env::inst().get_msg(MSG_EDITORBUSY));
    return;
  }
  status::inst().pinup();
  if( !status::inst().load() )
    status::inst().close();
}

void sesion_save()
{
  if( !status::inst().is_act() ){
    far_env::inst().show_error(far_env::inst().get_msg(MSG_NOACTIVESESSION));
    return;
  }
  status::inst().save(true/*overwrite*/);
}

void session_close()
{
  if( !status::inst().is_act() ){
    far_env::inst().show_error(far_env::inst().get_msg(MSG_NOACTIVESESSION));
    return;
  }
  if( status::inst().save(true/*overwrite*/) ){
    save_all_files();
    close_all_files();
    status::inst().close();
  }
}

//// общие функции

void about()
{
  static const char* items[] = {
    "About ESession",
    "Editor Session Saver",
    "(c) Michael Machin aka ltwood",
    "ver 1.02.b, 2005.05.31",
    "Ok"
  };
  far_env::inst().show_message(items, sizeof(items)/sizeof(items[0]), 1);
}

//// внешние функции плагина

// экспорт функций в GCC
#define PLUGEXP __attribute__((dllexport)) __attribute__((stdcall))

extern "C" {
  PLUGEXP int GetMinFarVersion();
  PLUGEXP void SetStartupInfo( const PluginStartupInfo* psi );
  PLUGEXP void GetPluginInfo( PluginInfo* pi );
  PLUGEXP HANDLE OpenPlugin( int OpenFrom, int Item );
  PLUGEXP int ProcessEditorEvent( int Event, void *Param );
};

// возвращает минимальную версию FAR'а, с которой работает плагин
int GetMinFarVersion(void)
{
  return MAKEFARVERSION(1,70,1634);
}

// вызывается Far'ом перед вызовом любых других функций
// при вызове плагину передается информацию о его окружении
PLUGEXP void SetStartupInfo( const PluginStartupInfo* psi )
{
  far_env::inst().set_startup(psi);
}

// вызывается Far'ом для получения информации о плагине
PLUGEXP void GetPluginInfo( PluginInfo* pi )
{
  pi->StructSize=sizeof(PluginInfo);

  // в каких меню показывать
  pi->Flags = PF_EDITOR | PF_VIEWER;

  // статический массив строк для пунктов главного меню,
  // соответствующих данному плагину
  static const char* PluginMenuStrings[1];
  PluginMenuStrings[0] = far_env::inst().get_msg(MSG_PLUGIN_NAME);

  // регистрация строк в меню плагинов
  pi->PluginMenuStringsNumber = 1;
  pi->PluginMenuStrings = PluginMenuStrings;
}

// вызывается при активизации плагина
// плагины, создающие панели и существующие в нескольких копиях должны возвращать
// свой handle (произвольный адрес), идентифицирующий копию плагина.
// этот адрес будет потом передаваться FAR'ом в другие функции плагина
PLUGEXP HANDLE OpenPlugin( int OpenFrom, int Item )
{
  // создаем меню
  static FarMenuItem items[] = {
    // {string, selected, checked, separator}
    { "", 1, 0, 0 }, // create
    { "", 0, 0, 0 }, // load
    { "", 0, 0, 0 }, // save
    { "", 0, 0, 0 }, // close
    { "", 0, 0, 1 }, // --
    { "", 0, 0, 0 }, // Save All
    { "", 0, 0, 1 }, // --
    { "", 0, 0, 0 }, // About
  };
  strcpy(items[0].Text, far_env::inst().get_msg(MSG_CREATE));
  strcpy(items[1].Text, far_env::inst().get_msg(MSG_LOAD));
  strcpy(items[2].Text, far_env::inst().get_msg(MSG_SAVE));
  strcpy(items[3].Text, far_env::inst().get_msg(MSG_CLOSE));
  // -- [4]
  strcpy(items[5].Text, far_env::inst().get_msg(MSG_SAVEALL));
  // -- [6]
  strcpy(items[7].Text, far_env::inst().get_msg(MSG_ABOUT));

  // показываем меню
  int todo = far_env::inst().show_menu(
    far_env::inst().get_msg(MSG_PLUGIN_NAME),
    items, sizeof(items)/sizeof(items[0])
  );

  // выполняем действие
  switch( todo ){
    case 0: // CREATE
      session_create();
      break;
    case 1: // LOAD
      session_load();
      break;
    case 2: // SAVE
      sesion_save();
      break;
    case 3: // CLOSE
      session_close();
      break;
    case 4: // --
      break;
    case 5: // SAVEALL
      save_all_files();
      break;
    case 6: // --
      break;
    case 7: // ABOUT
      about();
      break;
    default:
      break;
  }

  // возвращаем флаг неудачи, поскольку плагин не создает панелей
  return INVALID_HANDLE_VALUE;
}

// вызывается по событиям от редактора
PLUGEXP int ProcessEditorEvent( int Event, void *Param )
{
  EditorInfo ei;
  int* pid;
  switch( Event ){
    case EE_READ:       // открытие нового редактора
      far_env::inst().edt_getinfo(ei);
      edt_list::inst().add(ei);
      break;
    case EE_REDRAW:     // перерисовка экрана редактора
      far_env::inst().edt_getinfo(ei);
      edt_list::inst().upd(ei);
      break;
    case EE_CLOSE:      // закрытие редактора
      pid = static_cast<int*>(Param);
      edt_list::inst().del(*pid);
      break;
    case EE_SAVE:       // сохранение файла
      break;
  }
}
