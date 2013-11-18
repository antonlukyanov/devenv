/* Copyright (c) 1990  Microsoft Corporation
 * Module Name:
 *     dbmon.c
 * Abstract:
 *     A simple program to print strings passed to OutputDebugString when
 *     the app printing the strings is not being debugged.
 * Author:
 *     Kent Forschmiedt (kentf) 30-Sep-1994
 *     Michal Vodicka (some changes)
 * Revision History:
 *     $Revision: 3 $
 * Some minor changes:
 *     ltwood, 2005, Oct
 */

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <ctype.h>

void error( const char* msg )
{
  fprintf(stderr, "dbmon: %s\n", msg);
  exit(1);
}

double get_time()
{
  return (double)clock() / CLK_TCK;
}

void cls()
{
  for( int j = 0; j < 300; j++ )
    putchar('\n');
}

int main( int argc, char ** argv )
{
  printf("DbMon, ver. 3.1, 2005.10.19\n");
  printf("usage: dbmon [prefix]\n");
  const char* pref = (argc == 2) ? argv[1] : 0;
  printf("prefix: %s\n", pref ? pref : "no prefix");
  int pref_len = pref ? strlen(pref) : 0;
  printf("--\n");

  // security

  SECURITY_ATTRIBUTES sa;
  SECURITY_DESCRIPTOR sd;

  sa.nLength = sizeof(SECURITY_ATTRIBUTES);
  sa.bInheritHandle = TRUE;
  sa.lpSecurityDescriptor = &sd;

  if( !InitializeSecurityDescriptor(&sd, SECURITY_DESCRIPTOR_REVISION) )
    error("unable to InitializeSecurityDescriptor");

  if( !SetSecurityDescriptorDacl(&sd, TRUE, (PACL)NULL, FALSE) )
    error("unable to SetSecurityDescriptorDacl");

  // synchronization objects

  HANDLE AckEvent = CreateEvent(&sa, FALSE, FALSE, "DBWIN_BUFFER_READY");
  if( !AckEvent )
    error("unable to create synchronization object");
  if( GetLastError() == ERROR_ALREADY_EXISTS )
    error("already running");
  HANDLE ReadyEvent = CreateEvent(&sa, FALSE, FALSE, "DBWIN_DATA_READY");
  if( !ReadyEvent )
    error("unable to create synchronization object");

  // mapping object

  HANDLE SharedFile = CreateFileMapping((HANDLE)-1, &sa, PAGE_READWRITE, 0, 4096, "DBWIN_BUFFER");
  if (!SharedFile)
    error("unable to create file mapping object");
  LPVOID SharedMem = MapViewOfFile(SharedFile, FILE_MAP_READ, 0, 0, 512);
  if( !SharedMem )
    error("unable to map shared memory");

  LPSTR  String = (LPSTR)SharedMem + sizeof(DWORD);
  LPDWORD pThisPid = (DWORD*)SharedMem;

  // main cicle

  FILE* file = fopen("dbmon.log", "wt");
  if( !SharedMem )
    error("unable to open logfile");
  int buf_len = 10;
  char* buf = (char*)malloc(buf_len);
  if( !buf )
    error("unable to allocate buffer");

  DWORD last_pid = 0;
  double tm0 = get_time();
  SetEvent(AckEvent);
  while( 1 ){
    if( WaitForSingleObject(ReadyEvent, INFINITE) != WAIT_OBJECT_0 )
      error("wait failed");
    double tm = get_time() - tm0;
    int str_len = strlen(String);
    if( str_len+1 > buf_len ){
      buf_len = str_len + 1;
      buf = (char*)realloc(buf, buf_len);
      if( !buf )
        error("unable to reallocate buffer");
    }
    strcpy(buf, String);

    if( pref == 0 || strncmp(String, pref, pref_len) == 0 ){
      if( *pThisPid != last_pid ){
        cls();
        last_pid = *pThisPid;
      }
      if( !pref )
        printf("%lu: ", *pThisPid);
      fprintf(file, "%lu: %.1lf: ", *pThisPid, tm);

      for( int j = str_len - 1; j >= 0 && buf[j] == '\n'; j-- )
        buf[j] = 0;

      printf("%s\n", buf);
      fprintf(file, "%s\n", buf);
      fflush(stdout);
      fflush(file);
    }
    SetEvent(AckEvent);
  }

  free(buf);
  fclose(file);
  return 0;
}
