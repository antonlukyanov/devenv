#include <windows.h>
#include <stdio.h>
#include <time.h>
#include <dir.h>
#include <sys/stat.h>
#include <time.h>

// export

#define EXPORT __attribute__((dllexport))

typedef unsigned int uint;

extern "C" {
  EXPORT const char* zzz_ver();
  EXPORT int llogsrv_ver();
  EXPORT void llogsrv_log( const char* asp, const char* msg );
  EXPORT int llogsrv_isdump();
  EXPORT uint llogsrv_getid();
  EXPORT uint llogsrv_getct();
};

// version

// Версия используется при проверке корректности отладочного окружения.
// При этом проверяется старшая часть версии, возвращаемая функцией llogsrv_ver().
// Эта часть версии должна меняться только при изменении интерфейса библиотеки.

#include "revision.hg"

#define VER_MAIN 3
#define VER_SUBV 02

#define MK_STR_(arg) #arg
#define MK_STR(arg) MK_STR_(arg)

static const char ver[] = MK_STR(VER_MAIN) "." MK_STR(VER_SUBV) "." HG_VER;
static const int iver = VER_MAIN;

const char* zzz_ver()
{
  return ver;
}

int llogsrv_ver()
{
  return iver;
}

/*#lake:stop*/

// utils

const int BUFLEN = 1024;

namespace utils {
  // Функция безопасного форматного вывода в буфер.
  // В конец строки гарантированно прописывается символ-ограничитель.
  // Возвращает число выведенных символов или -1 при переполнении буфера.
  // Гарантируется, что эти функции никогда не генерируют исключений.

  // Функция snprintf может записать ровно buflen символов и вернуть число buflen.
  // В этом случае считается, что произошло перепонение буфера и следует использовать
  // буфер большей длины.
  // В функци prot_vsprintf() при переполнении происходит простое обрезание результата
  // и возвращается признак ошибки.
  int prot_vsprintf( char* buf, int buflen, const char* fmt, va_list va )
  {
    int numch = vsnprintf(buf, buflen, fmt, va);
    if( numch >= 0 && numch < buflen )
      return numch;
    // при переполнении буфера
    buf[buflen-1] = 0;  // записываем завершающий нуль
    return -1;          // возвращаем признак ошибки
  }

  int prot_sprintf( char* buf, int buflen, const char* fmt, ... )
  {
    va_list va;
    va_start(va, fmt);
    int numch = prot_vsprintf(buf, buflen, fmt, va);
    va_end(va);
    return numch;
  }

  // Функция strncpy(dst, src, num) копирует не более num символов,
  // заполняя нулями остаток строки dst.
  // Если исходная строка длиннее num, то будет скопировано ровно
  // num символов и не будет записан завершающий нуль.
  char* prot_strcpy( char* dst, const char* src, int buflen )
  {
    if( src ){
      strncpy(dst, src, buflen-1);
      dst[buflen-1] = 0;  // дописываем завершающий нуль
    } else
      dst[0] = 0; // формируем строку нулевой длины

    return dst;
  }

  // заменяем слэши на правильные
  void norm_path( char* buf )
  {
    for( char* pch = buf; *pch; pch++ ){
      if( *pch == '\\' )
        *pch = '/';
    }
  }

  const char* get_app_path()
  {
    static char buf[BUFLEN];

    // получаем значение переменной среды или путь к приложению
    const char* env = getenv("LWML_APP_HOME");
    if( env != 0 ){
      prot_strcpy(buf, env, BUFLEN);
      norm_path(buf);
    } else {
      int res = GetModuleFileName(0, buf, BUFLEN);
      if( res == 0 || res == BUFLEN )
        return 0;

      norm_path(buf);

      // убираем имя исполнимого файла
      char* psl = strrchr(buf, '/');
      if( psl == 0 )
        return 0;
      *psl = 0;
    }

    return buf;
  }

  const char* current_path()
  {
    static char buf[BUFLEN];
    if( getcwd(buf, BUFLEN) == 0 )
      prot_sprintf(buf, BUFLEN, "unknown");
    return buf;
  }
};

// internal data and procs

namespace {
  CRITICAL_SECTION log_cs;
  bool log_is_first_call = true;
  FILE* log_file = 0;

  CRITICAL_SECTION dump_cs;
  bool dump_is_first_call = true;
  bool is_dump;

  CRITICAL_SECTION id_cs;
  bool id_is_first_call = true;
  uint id_val;

  CRITICAL_SECTION cnt_cs;
  bool cnt_is_first_call = true;
  uint cnt_val;

  void put_wrap( const char* s )
  {
    if( strchr(s, ',') != 0 || strchr(s, '"') != 0 || strchr(s, '\n') != 0 ){
      fputc('"', log_file);
      for( const char* pch = s; *pch; pch++ ){
        if( *pch == '"' )
          fputs("\"\"", log_file);
        if( *pch == '\n' )
          fputc(' ', log_file);
        else
          fputc(*pch, log_file);
      }
      fputc('"', log_file);
    } else {
      fputs(s, log_file);
    }
  }

  void out_log_rec( const char* asp, const char* msg )
  {
    fprintf(log_file, "%lu,", GetCurrentThreadId());
    fprintf(log_file, "%ld,", clock());
    put_wrap(asp);
    fputc(',', log_file);
    put_wrap(msg);
    fputc('\n', log_file);
    fflush(log_file);
  }

  void open_log()
  {
    static char buf[BUFLEN];
    const char* app = utils::get_app_path();
    if( app == 0 ){
      log_file = 0;
      return;
    }

    utils::prot_sprintf(buf, BUFLEN, "%s/_%08x.log", app, llogsrv_getid());
    log_file = fopen(buf, "wt");

    out_log_rec("llogsrv:cwd", utils::current_path());
  }

  bool test_dump()
  {
    static char buf[BUFLEN];
    const char* app = utils::get_app_path();
    if( app == 0 )
      return false;
    utils::prot_sprintf(buf, BUFLEN, "%s/dump", app);

    bool is_ex = (access(buf, 0) == 0);
    if( !is_ex ) return false;

    struct stat sst;
    if( stat(buf, &sst) != 0 )
      return false;
    return (S_IFDIR & sst.st_mode) != 0;
  }
};

// main procs

void llogsrv_log( const char* asp, const char* msg )
{
  if( log_is_first_call ){
    InitializeCriticalSection(&log_cs);
    EnterCriticalSection(&log_cs);
    open_log();
    log_is_first_call = false;
    LeaveCriticalSection(&log_cs);
  }
  if( log_file ){
    EnterCriticalSection(&log_cs);
    out_log_rec(asp, msg);
    LeaveCriticalSection(&log_cs);
  }
}

int llogsrv_isdump()
{
  if( dump_is_first_call ){
    InitializeCriticalSection(&dump_cs);
    EnterCriticalSection(&dump_cs);
    is_dump = test_dump();
    dump_is_first_call = false;
    LeaveCriticalSection(&dump_cs);
  }
  return is_dump;
}

uint llogsrv_getid()
{
  if( id_is_first_call ){
    InitializeCriticalSection(&id_cs);
    EnterCriticalSection(&id_cs);
    id_val = time(0);
    id_is_first_call = false;
    LeaveCriticalSection(&id_cs);
  }
  return id_val;
}

uint llogsrv_getct()
{
  if( cnt_is_first_call ){
    InitializeCriticalSection(&cnt_cs);
    EnterCriticalSection(&cnt_cs);
    cnt_val = 0;
    cnt_is_first_call = false;
    LeaveCriticalSection(&cnt_cs);
  }
  EnterCriticalSection(&cnt_cs);
  ++cnt_val;
  LeaveCriticalSection(&cnt_cs);
  return cnt_val;
}
