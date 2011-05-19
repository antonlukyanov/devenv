#include "luaextn.h"

#include <windows.h>

#include "revision.svn"

/*#lake:stop*/

using namespace lwml;

LUA_DEF_FUNCTION( gpf_off, L )
{
  luaextn ex(L);
LUA_TRY
  SetErrorMode(SEM_NOGPFAULTERRORBOX);

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( set_background, L )
{
  luaextn ex(L);
LUA_TRY
  SetPriorityClass(GetCurrentProcess(), BELOW_NORMAL_PRIORITY_CLASS);

  return ex.ret_num();
LUA_CATCH(ex)
}

namespace {
  int run( const char* cmdl, WORD show_window )
  {
    STARTUPINFO si;
    si.cb = sizeof(si);
    si.lpReserved = NULL;
    si.lpDesktop = NULL;
    si.lpTitle = NULL;
    si.dwX = 0;
    si.dwY = 0;
    si.dwXSize = 0;
    si.dwYSize = 0;
    si.dwXCountChars = 0;
    si.dwYCountChars = 0;
    si.dwFillAttribute = 0;
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = show_window;
    si.cbReserved2 = 0;
    si.lpReserved2 = NULL;
    si.hStdInput = NULL;
    si.hStdOutput = NULL;
    si.hStdError = NULL;

    PROCESS_INFORMATION pi;
    BOOL res = CreateProcess(
      NULL, // lpApplicationName -- use lpCommandLine
      (CHAR*)cmdl, // lpCommandLine
      NULL, // LPSECURITY_ATTRIBUTES lpProcessAttributes
      NULL, // LPSECURITY_ATTRIBUTES lpThreadAttributes
      TRUE, // bInheritHandles
      0,    // dwCreationFlags
      NULL, // LPVOID lpEnvironment -- use inherited environment
      NULL, // LPCTSTR lpCurrentDirectory -- use inherited cwd
      &si,  // lpStartupInfo
      &pi   // lpProcessInformation
    );

    if( res ){
      DWORD exit_code;
      WaitForSingleObject(pi.hProcess, INFINITE);
      GetExitCodeProcess(pi.hProcess, &exit_code);
      CloseHandle(pi.hProcess);
      CloseHandle(pi.hThread);
      return exit_code;
    } else
      return -1;
  }
};

LUA_DEF_FUNCTION( run_min, L )
{
  luaextn ex(L);
LUA_TRY
  const char* cmdl = ex.get_str(1);

  ex.put_int(run(cmdl, SW_SHOWMINNOACTIVE));

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( run_hide, L )
{
  luaextn ex(L);
LUA_TRY
  const char* cmdl = ex.get_str(1);

  ex.put_int(run(cmdl, SW_HIDE));

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_BEGIN_LIBRARY(proc)
  LUA_FUNCTION(gpf_off)
  LUA_FUNCTION(set_background)
  LUA_FUNCTION(run_min)
  LUA_FUNCTION(run_hide)
LUA_END_LIBRARY

LUA_BEGIN_EXPORT(libproc)
  LUA_EXPORT_LIBRARY(proc)
LUA_END_EXPORT

