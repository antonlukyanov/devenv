#include "console.h"

#include "dload.h"

using namespace lwml;

#include "revision.svn"

const char VER[] = "dllver, ver. 1.0." SVN_VER ", internal lwdg utility";

typedef const char* (*ver_func)();

int main( int argc, char *argv[] ){
try{
  console::init(argc, argv);

  if( console::argc() != 1 && console::argc() != 2 )
    console::usage(VER, "dllver dllname [fname]");

  void* dll = dl_load(console::argv(0).ascstr());
  if( dll == 0 )
    fail_syscall("can't load dll");

  dproc f = dl_proc(dll, (console::argc()==2) ? console::argv(1).ascstr() : "zzz_ver");
  if( f == 0 )
    fail_syscall("can't load proc");

  ver_func vf = reinterpret_cast<ver_func>(f);
  printf("%s\n", vf());

}catch( error& er ){
  console::handlex(er);
}
}
