#include "defs.h"
#include "console.h"
#include "filename.h"

#include <windows.h>

using namespace lwml;

#include "revision.hg"

const char VER[] = "lwhich, ver. 1.2." HG_VER ", (c) ltwood, 2004 Aug";

const int BUF_LEN = 2048;

const char PATHEXT_ENV[]   = "PATHEXT";
const char PATHEXT_DELIM[] = ";";

const char SS_LWHICH[] = "lwhich";

// ������� SearchPath(0, ...) ���� ����� � ����������� � ��������� �������:
// 1. The directory from which the application loaded.
// 2. The current directory.
// 3. The Windows system directory. The name of this directory is SYSTEM32.
// 4. The 16-bit Windows system directory. The name of this directory is SYSTEM.
// 5. The Windows directory.
// 6. The directories that are listed in the PATH environment variable.

void check_file( const char* fname, const char* fextn )
{
  static char buf[BUF_LEN];
  char* pp;

  int len = SearchPath(
    0,                    // search std dirs
    fname,
    fextn,
    BUF_LEN, buf,
    &pp                   // character immediately following the final slash in the path
  );
  if( len > BUF_LEN )
    fail_assert("too long path, buffer overflow");
  if( len != 0 )
    printf("%s\n", buf);
}

int main( int argc, char *argv[] ){
try{
  console::init(argc, argv);

  if( console::argc() < 1 )
    console::usage(VER, "lwhich file ...");

  for( int j = 0; j < console::argc(); j++ ){
    filename fn(console::argv(j).ascstr());
    if( !fn.extn().is_empty() )
      check_file(fn.name().ascstr(), fn.extn().ascstr());
    else{
      if( getenv(PATHEXT_ENV) == 0 )
        fail_syscall("can't find PATHEXT in environment");

      strng extlist(getenv(PATHEXT_ENV));
      while( !extlist.is_empty() ){
        strng ext = extlist.get_word(PATHEXT_DELIM);
        fn.set_extn(ext.ascstr());
        check_file(fn.name().ascstr(), fn.extn().ascstr());
      }
    }
  }

}catch( error& err ){
  console::handlex(err);
}
}

// Version history:
//
// 1.1:
//   - ������ ������
// 1.2:
//   - ���������� ������� ������ ��� ������������� ����������
//     (���� ��������� ��� ����������).
//   - ������ 1.1 � ������ ���������� ���������� ������ ����
//     � ����������� ".EXE", ��������� ������� SearchPath()
//     �� �������� ��� ���������� (NULL) ����������.
//     � ������ 1.2 ��� ���������� ���������� ���������������
//     ������������ ����� ������ �� ����� ������������,
//     ������� ����������� �� ���������� ��������� PATHEXT.
//     ���� ������������ ��������� ����� ������, �� ��� ����
//     ��� ���������� ����.
//   - ��� ����������� ������ ������ 1.1 �������� ���������,
//     � ������ 1.2 ����� ��������� ������.
