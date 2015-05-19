#include <pthread.h>
#include <stdio.h>
#include <stdarg.h>
#include <cstring>
#include <cstdlib>
#include <time.h>
#include <sys/stat.h>
#include <time.h>

#define OS_WIN   0
#define OS_OSX   0
#define OS_LINUX 0

#ifdef __MINGW32__ || __MINGW64__
  #define OS_WIN 1
#elif __APPLE__
  #define OS_OSX 1
#elif __linux__
  #define OS_LINUX 1
#endif

#if OS_WIN
  #include <windows.h>
  #include <dir.h>
  #define cwd getcwd
#else
  #include <sys/syscall.h>
  #include <sys/types.h>
  #include <unistd.h>
  #define cwd getcwd
#endif

#if OS_OSX
  #include <mach-o/dyld.h>
#endif

// export

#if OS_WIN
  #ifdef __GNUC__ >= 4
    #define EXPORT extern "C" __attribute__((dllexport))
  #else
    #define EXPORT extern "C" __declspec(dllexport)
  #endif
#else
  #if __GNUC__ >= 4
     #define EXPORT extern "C" __attribute__((visibility("default")))
  #else
     #define EXPORT extern "C"
  #endif
#endif

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
  // В этом случае считается, что произошло переполнение буфера и следует использовать
  // буфер большей длины.
  // В функции prot_vsprintf() при переполнении происходит простое обрезание результата
  // и возвращается признак ошибки.
  //
  // В gcc 4.6.x в реализации функции vsnprintf() вероятно содержится ошибка,
  // но она по-видимому не проявляется в тех вариантах использования этой функции, 
  // которые встречаются в данном модуле (ошибка связана с выводом вещественных чисел).
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

  // Заменяем слэши на правильные.
  void norm_path( char* buf )
  {
    for( char* pch = buf; *pch; pch++ ){
      if( *pch == '\\' )
        *pch = '/';
    }
  }

  void remove_last_part(const char* s)
  {
    char* psl = strrchr(s, '/');
    if( psl != 0 )
      *psl = 0;
  }

  const char* get_app_path()
  {
    static char buf[BUFLEN];

#if OS_WIN
    // Получаем значение переменной среды или путь к приложению.
    const char* env = getenv("LWML_APP_HOME");
    if( env != 0 ){
      prot_strcpy(buf, env, BUFLEN);
      norm_path(buf);
    } else {
      int res = GetModuleFileName(0, buf, BUFLEN);
      if( res == 0 || res == BUFLEN )
        return 0;
    }
#elif OS_OSX
    uint32_t size = BUFLEN;
    if( _NSGetExecutablePath(buf, &size) != 0 ){
        return 0;
    }
#else
    const char* link_name = "/proc/self/exe";
    const int ret = static_cast<int>(readlink(link_name, buf, BUFLEN - 1));

    if( ret == -1 ){
      return 0;
    }

    buf[ret] = 0;
#endif

    norm_path(buf);

#if OS_OSX
    static char out[BUFLEN];
    realpath(buf, out);
    strcpy(buf, out);
#endif

    // Убираем имя исполнимого файла.
    remove_last_part(buf);

    return buf;
  }

  const char* current_path()
  {
    static char buf[BUFLEN];
    if( cwd(buf, BUFLEN) == 0 )
      prot_sprintf(buf, BUFLEN, "unknown");
    return buf;
  }
};

pthread_mutex_t log_m = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t dump_m = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t id_m = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t cnt_m = PTHREAD_MUTEX_INITIALIZER;

// Internal data and procs

namespace {
  bool log_is_first_call = true;
  FILE* log_file = 0;

  bool dump_is_first_call = true;
  bool is_dump;

  bool id_is_first_call = true;
  uint id_val;

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
#if OS_WIN
    fprintf(log_file, "%lu,", GetCurrentThreadId());
#else
    fprintf(log_file, "%d,", static_cast<int>(syscall(SYS_gettid)));
#endif
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
    pthread_mutex_lock(&log_m);
    open_log();
    log_is_first_call = false;
    pthread_mutex_unlock(&log_m);
  }
  if( log_file ){
    pthread_mutex_lock(&log_m);
    out_log_rec(asp, msg);
    pthread_mutex_unlock(&log_m);
  }
}

int llogsrv_isdump()
{
  if( dump_is_first_call ){
    pthread_mutex_lock(&dump_m);
    is_dump = test_dump();
    dump_is_first_call = false;
    pthread_mutex_unlock(&dump_m);
  }
  return is_dump;
}

uint llogsrv_getid()
{
  if( id_is_first_call ){
    pthread_mutex_lock(&id_m);
    id_val = time(0);
    id_is_first_call = false;
    pthread_mutex_unlock(&id_m);
  }
  return id_val;
}

uint llogsrv_getct()
{
  if( cnt_is_first_call ){
    pthread_mutex_lock(&cnt_m);
    cnt_val = 0;
    cnt_is_first_call = false;
    pthread_mutex_unlock(&cnt_m);
  }
  pthread_mutex_lock(&cnt_m);
  ++cnt_val;
  pthread_mutex_unlock(&cnt_m);
  return cnt_val;
}

#if OS_WIN
  BOOL WINAPI DllMain
  (
    HINSTANCE hinstDLL,
    DWORD fdwReason,
    LPVOID lpReserved
  )
  {
    switch (fdwReason)
    {
    case DLL_PROCESS_DETACH:
      pthread_mutex_destroy(&log_m);
      pthread_mutex_destroy(&dump_m);
      pthread_mutex_destroy(&id_m);
      pthread_mutex_destroy(&cnt_m);
      break;
    }

    return TRUE;
  }
#else
  __attribute__((destructor))
  void llogsrv_destructor()
  {
    pthread_mutex_destroy(&log_m);
    pthread_mutex_destroy(&dump_m);
    pthread_mutex_destroy(&id_m);
    pthread_mutex_destroy(&cnt_m);
  }
#endif
