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

namespace {
  bool set_proc_prior( HANDLE hProc, int prior )
  {
    DWORD prior_code;
    switch( prior ){
      case -2:
        prior_code = IDLE_PRIORITY_CLASS;
        break;
      case -1:
        prior_code = BELOW_NORMAL_PRIORITY_CLASS;
        break;
      case 0:
        prior_code = NORMAL_PRIORITY_CLASS;
        break;
      case 1:
        prior_code = ABOVE_NORMAL_PRIORITY_CLASS;
        break;
      case 2:
        prior_code = HIGH_PRIORITY_CLASS;
        break;
      default:
        return false;
    }

    if( SetPriorityClass(hProc, prior_code) == 0 )
      return false;
    return true;
  }
};

LUA_DEF_FUNCTION( set_priority, L )
{
  luaextn ex(L);
LUA_TRY

  int p = ex.get_int(1);

  if( set_proc_prior(GetCurrentProcess(), p) )
    ex.put_bool(true);
  else
    ex.put_error("lswp.set_priority: can't set priority");

  return ex.ret_num();
LUA_CATCH(ex)
}

namespace {
  // show_window = { SW_HIDE, SW_SHOWMINNOACTIVE, SW_SHOWNORMAL }
  bool run( uint* pid, const char* cmdl, const char* pwd, int prior, bool do_wait, WORD win )
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
    si.wShowWindow = win;
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
      pwd , // LPCTSTR lpCurrentDirectory -- use inherited cwd for NULL
      &si,  // lpStartupInfo
      &pi   // lpProcessInformation
    );

    if( !res )
      return false;

    if( !set_proc_prior(pi.hProcess, prior) )
      return false;

    if( do_wait )
      WaitForSingleObject(pi.hProcess, INFINITE);

    DWORD exit_code;
    GetExitCodeProcess(pi.hProcess, &exit_code);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    *pid = exit_code;
    return true;
  }
};

LUA_DEF_FUNCTION( run, L )
{
  luaextn ex(L);
LUA_TRY
  const char* cmdl = ex.get_str(1);

  // default params
  const char* pwd = 0;
  int prior = 0;
  bool do_wait = true;
  const char* window = "normal";

  if( ex.arg_num() > 1 ){
    luaL_checktype(L, 2, LUA_TTABLE);

    lua_pushstring(L, "pwd");
    lua_gettable(L, 2);
    if( !lua_isnil(L, -1) )
      pwd = luaL_checkstring(L, -1);

    lua_pushstring(L, "priority");
    lua_gettable(L, 2);
    if( !lua_isnil(L, -1) )
      prior = static_cast<int>(luaL_checknumber(L, -1));

    lua_pushstring(L, "wait");
    lua_gettable(L, 2);
    if( !lua_isnil(L, -1) )
      do_wait = lua_toboolean(L, -1);

    lua_pushstring(L, "window");
    lua_gettable(L, 2);
    if( !lua_isnil(L, -1) )
      window = luaL_checkstring(L, -1);
  }

  WORD win;
  if( strcmp(window, "normal") == 0 )
    win = SW_SHOWNORMAL;
  else if( strcmp(window, "min") == 0 )
    win = SW_SHOWMINNOACTIVE;
  else if( strcmp(window, "hide") == 0 )
    win = SW_HIDE;
  else {
    ex.put_error("lswp.run: incorrect window state");
    return ex.ret_num();
  }

  uint pid;
  if( run(&pid, cmdl, pwd, prior, do_wait, win) )
    ex.put_int(pid);
  else
    ex.put_error("lswp.run: can't start process");

  return ex.ret_num();
LUA_CATCH(ex)
}

LUA_DEF_FUNCTION( sleep, L )
{
  luaextn ex(L);
LUA_TRY
  int tm = (ex.arg_num() >= 1) ? ex.get_int(1) : 0;
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
  LUA_FUNCTION(run)
  LUA_FUNCTION(sleep)
  LUA_FUNCTION(kill)
  LUA_FUNCTION(ps)
LUA_END_LIBRARY

LUA_BEGIN_EXPORT(lswp)
  LUA_EXPORT_LIBRARY(lswp)
LUA_END_EXPORT
