#include "luaextn.h"

#include <windows.h>
#include <tlhelp32.h>

#include "revision.hg"

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

LUA_DEF_FUNCTION( set_priority, L )
{
  luaextn ex(L);
LUA_TRY

  int p = ex.get_int(1);

  DWORD prior;
  switch( p ){
    case -2:
      prior = IDLE_PRIORITY_CLASS;
      break;
    case -1:
      prior = BELOW_NORMAL_PRIORITY_CLASS;
      break;
    case 0:
      prior = NORMAL_PRIORITY_CLASS;
      break;
    case 1:
      prior = ABOVE_NORMAL_PRIORITY_CLASS;
      break;
    case 2:
      prior = HIGH_PRIORITY_CLASS;
      break;
    default:
      put_error("lswp.set_priority: incorrect priority");
      return ex.ret_num();
  }

  if( SetPriorityClass(GetCurrentProcess(), prior) == 0 )
    put_error("lswp.set_priority: can't set priority");
  else
    put_bool(true);

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

LUA_DEF_FUNCTION( run, L )
{
  luaextn ex(L);
LUA_TRY
  const char* cmdl = ex.get_str(1);

  ex.put_int(run(cmdl, SW_SHOWMINNOACTIVE));

  return ex.ret_num();
LUA_CATCH(ex)
}

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

LUA_DEF_FUNCTION( sleep, L )
{
  luaextn ex(L);
LUA_TRY
  int tm = (ex.arg_num() == 1) ? ex.get_int(1) : 0;
  Sleep(tm);
  return ex.ret_num();
LUA_CATCH(ex)
}

void put_win_error( luaextn& ex, const char* pref )
{
  char buffer[1024];
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, 0, GetLastError(), 0, buffer, sizeof(buffer), 0);
  ex.put_error("%s: %s", pref, buffer);
}

LUA_DEF_FUNCTION( kill, L )
{
  luaextn ex(L);
LUA_TRY

  int pid = ex.get_int(1);

  HANDLE hProc = OpenProcess(PROCESS_TERMINATE, FALSE, pid);

  if( hProc == NULL )
    ex.put_error("lswp.kill: incorrect pid");
  else {
    if( !TerminateProcess(hProc,1) )
      ex.put_error("lswp.kill: can't terminate");
    else
      ex.put_bool(true);
    CloseHandle(hProc);
  }

  return ex.ret_num();

LUA_CATCH(ex)
}

namespace {
  void push_proc_tbl( lua_State* L, int pid, const char* name, const char* path )
  {
    lua_newtable(L);
    
    lua_pushstring(L, "pid");
    lua_pushnumber(L, pid);
    lua_settable(L, -3);

    lua_pushstring(L, "name");
    lua_pushstring(L, name);
    lua_settable(L, -3);

    lua_pushstring(L, "path");
    lua_pushstring(L, path);
    lua_settable(L, -3);
  }
};

LUA_DEF_FUNCTION( ps, L )
{
  luaextn ex(L);
LUA_TRY

  HANDLE hSnap=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);

  if( hSnap == INVALID_HANDLE_VALUE )
    ex.put_error("lswp.ps: can't enumerate processes");
  else {
    PROCESSENTRY32 pe;
    pe.dwSize = sizeof(pe);

    lua_newtable(L);
    if( Process32First(hSnap, &pe) ){
      int idx = 1;
      do{
        MODULEENTRY32 me;
        HANDLE hMod;
        if( pe.th32ProcessID == 0 )
          continue;
        hMod = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, pe.th32ProcessID);
        if( hMod == INVALID_HANDLE_VALUE )
          continue;
        me.dwSize = sizeof(me);
        if( Module32First(hMod,&me) ){
          lua_pushnumber(L, idx++);
          push_proc_tbl(L, pe.th32ProcessID, me.szModule, me.szExePath);
          lua_settable(L, -3);
        }
        CloseHandle(hMod);
      }while( Process32Next(hSnap, &pe) );
    }
    ex.i_have_created_stack_element();
    CloseHandle(hSnap);
    ex.put_bool(true);
  }

  return ex.ret_num();

LUA_CATCH(ex)
}

LUA_BEGIN_LIBRARY(lswp)
  LUA_FUNCTION(gpf_off)
  LUA_FUNCTION(set_priority)
  LUA_FUNCTION(run_min)
  LUA_FUNCTION(run_hide)

  LUA_FUNCTION(sleep)
  LUA_FUNCTION(kill)
  LUA_FUNCTION(ps)
LUA_END_LIBRARY

LUA_BEGIN_EXPORT(lswp)
  LUA_EXPORT_LIBRARY(lswp)
LUA_END_EXPORT
