#include <windows.h>
#include <windowsx.h>

#include <stdio.h>

// common const

#define PATHSTRLEN   256

#include "revision.hg"

const char VER[] = "1.00." HG_VER;
const char DELIM[] = "--------------------------------------------------------------";

// common func

void message( char *content ){
  char buf[128];
  sprintf(buf, "spclip v%s:", VER);
  MessageBox(0, content, buf, MB_OK | MB_ICONHAND);
}

// win handlers

HWND next_viewer = 0;
FILE *spfile = 0;

void OnDestroy( HWND hwnd ){
  PostQuitMessage(0);
}

LRESULT CALLBACK winproc( HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam ){
  HANDLE ptr;
  switch( uMsg ){
    case WM_DRAWCLIPBOARD:
      OpenClipboard(0);
      ptr = GetClipboardData(CF_TEXT);
      if( ptr != 0 && spfile != 0 ){
        fprintf(spfile, "%s\n", DELIM);
        fprintf(spfile, "%s\n", (char*)ptr);
        fprintf(spfile, "%s\n", DELIM);
        fflush(spfile);
      }
      CloseClipboard();
      if( next_viewer )
        SendMessage(next_viewer, WM_DRAWCLIPBOARD, 0, 0);
      break;
    case WM_DESTROY: 
      return HANDLE_WM_DESTROY(hwnd, wParam, lParam, OnDestroy);
    default:         
      return DefWindowProc(hwnd, uMsg, wParam, lParam);
  }
  return 0;
}

// win class

#define WINDOW_CLASS "spy-slip"

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

// WinMain

int __stdcall WinMain(
  HINSTANCE hInstance, HINSTANCE hPrevInstance,
  LPSTR lpszCmdLine, int nCmdShow )
{
  char filename[PATHSTRLEN];

  if( _argc != 2 ){
    message("usage: spclip filename");
    return 1;
  }
  strcpy(filename, _argv[1]);

  if( !registerclass() ) return 1;
  HWND hwnd = CreateWindow(
    WINDOW_CLASS, "", WS_OVERLAPPEDWINDOW,
    CW_USEDEFAULT, 0, 50, 50,
    NULL, NULL, GetModuleHandle(0), 0
  );
  if( !hwnd ){
    message("error: failed to create window");
    return 1;
  }
  ShowWindow(hwnd, SW_HIDE);

  next_viewer = SetClipboardViewer(hwnd);

  spfile = fopen(filename, "ab");
  if( !spfile ){
    message("error: can't open file");
    return 1;
  }

  MSG msg;
  while( GetMessage(&msg, 0, 0, 0) > 0 ){
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  fclose(spfile);
  ChangeClipboardChain(hwnd, next_viewer);

  return 0;
}
