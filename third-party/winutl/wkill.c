#include <windows.h>
#include <stdio.h>

int main(int argc,char **argv) {
  int	  pid;
  HANDLE  hProc;

  if (argc<2 || (pid=atoi(argv[1]))==0) {
    printf("usage: wkill <pid>\n");
    return 1;
  }
  hProc=OpenProcess(PROCESS_TERMINATE,FALSE,pid);
  if (hProc==NULL) {
    char    buffer[1024];
emsg:
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,0,GetLastError(),0,buffer,sizeof(buffer),0);
    printf("OpenProcess(): %s\n",buffer);
    return 1;
  }
  if (!TerminateProcess(hProc,1))
    goto emsg;
  CloseHandle(hProc);
  return 0;
}
