/*
  Command line animated gif creator.
  Base on UnFREEz by http://www.whitsoftdev.com/
*/

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#pragma pack(push,gifpacking,1)

typedef struct {
  char cSignature[3]; // Must be 'GIF'
  char cVersion[3];   // Must be '89a'
} GIF_HEADER;

typedef struct { // 7 bytes
  unsigned short iWidth;
  unsigned short iHeight;
  unsigned char iSizeOfGct : 3;
  unsigned char iSortFlag : 1;
  unsigned char iColorResolution : 3;
  unsigned char iGctFlag : 1;
  unsigned char iBackgroundColorIndex;
  unsigned char iPixelAspectRatio;
} GIF_LOGICAL_SCREEN_DESCRIPTOR;

typedef struct { // 6 bytes
  unsigned char iBlockSize;           // Must be 4
  unsigned char iTransparentColorFlag : 1;
  unsigned char iUserInputFlag : 1;
  unsigned char iDisposalMethod : 3;
  unsigned char iReserved : 3;
  unsigned short iDelayTime;
  unsigned char iTransparentColorIndex;
  unsigned char iBlockTerminator;     // Must be 0
} GIF_GRAPHIC_CONTROL_EXTENSION;

typedef struct { // 9 bytes
  unsigned short iLeft;
  unsigned short iTop;
  unsigned short iWidth;
  unsigned short iHeight;
  unsigned char iSizeOfLct : 3;
  unsigned char iReserved : 2;
  unsigned char iSortFlag : 1;
  unsigned char iInterlaceFlag : 1;
  unsigned char iLctFlag : 1;
} GIF_IMAGE_DESCRIPTOR;

#pragma pack(pop,gifpacking)

unsigned short iGctSize[]={6,12,24,48,96,192,384,768};

void MakeGIF(
  const char fn_out[], const int frame_delay,
  const char* const fn_in[], const int in_len
);

void usage( void )
{
  puts("Command line animated gif creator.");
  puts("Base on UnFREEz by http://www.whitsoftdev.com/");
  puts("Usage:");
  puts("unfreez out.gif frame_delay in1.gif [in2.gif ...]");
  puts("  frame_delay is in 1/100 sec");
  puts("Images must be of the same width and height.");
  puts("No transformation and/or repacking will be applied.");
}

void die( const char msg[] )
{
  perror(msg);
  exit(EXIT_FAILURE);
}

int main( int ac, char* av[] )
{
  int frame_delay;
  if( ac < 4 ){
    usage();
    return 0;
  }
  frame_delay = atoi(av[2]);
  if( frame_delay < 0 ){
    fprintf(stderr, "Negative frame_delay.\n");
    exit(EXIT_FAILURE);
  }
  MakeGIF(av[1], frame_delay, &av[3], ac-3);
  return 0;
}

void check_read( size_t n )
{
  if( n != 1 )
    die("read error");
}

void check_write( size_t n )
{
  if( n != 1 )
    die("write error");
}

/*
  frame_delay in 1/100th sec
*/
void MakeGIF(
  const char fn_out[], const int frame_delay,
  const char* const fn_in[], const int in_len
)
{
  const int is_loop = 1;
  int i;
  char szColorTable[768];
  unsigned char c;
  FILE *f_out, *f_in;

  GIF_HEADER gh;
  GIF_LOGICAL_SCREEN_DESCRIPTOR glsd1, glsd;
  GIF_GRAPHIC_CONTROL_EXTENSION ggce;
  GIF_IMAGE_DESCRIPTOR gid;
  memset(&glsd1, 0, sizeof(GIF_LOGICAL_SCREEN_DESCRIPTOR));

  f_out = fopen(fn_out, "wb");
  if( !f_out )
    die("out file");

  strncpy((char *)&gh,"GIF89a",6);
  check_write(fwrite(&gh, sizeof(GIF_HEADER), 1, f_out));
  check_write(fwrite(&glsd1, sizeof(GIF_LOGICAL_SCREEN_DESCRIPTOR), 1, f_out));

  if( is_loop ) {
    check_write(fwrite("\41\377\013NETSCAPE2.0\003\001\377\377\0", 19, 1, f_out));
  }

  for( i = 0; i < in_len; ++i ) {
    memset(&glsd, 0, sizeof(GIF_LOGICAL_SCREEN_DESCRIPTOR));
    memset(&ggce, 0, sizeof(GIF_GRAPHIC_CONTROL_EXTENSION));
    memset(&gid, 0, sizeof(GIF_IMAGE_DESCRIPTOR));
    f_in = fopen(fn_in[i], "rb");
    if( !f_in )
      die("in file");

    check_read(fread(&gh, sizeof(GIF_HEADER), 1, f_in));
    if( strncmp(gh.cSignature,"GIF",3) || (strncmp(gh.cVersion,"89a",3) && strncmp(gh.cVersion,"87a",3)) )
      die("Not a GIF file, or incorrect version number");

    check_read(fread(&glsd, sizeof(GIF_LOGICAL_SCREEN_DESCRIPTOR), 1, f_in));
    if( glsd.iGctFlag )
      check_read(fread(szColorTable, iGctSize[glsd.iSizeOfGct], 1, f_in));

    if( glsd1.iWidth < glsd.iWidth )
      glsd1.iWidth = glsd.iWidth;
    if( glsd1.iHeight < glsd.iHeight )
      glsd1.iHeight = glsd.iHeight;

    for (;;) {
      if( 1 != fread(&c, 1, 1, f_in) )
        die("Premature end of file encountered; no GIF image data present");

      if( c == 0x2C ){
        check_read(fread(&gid, sizeof(GIF_IMAGE_DESCRIPTOR), 1, f_in));
        if( gid.iLctFlag ){
          check_read(fread(szColorTable, iGctSize[gid.iSizeOfLct], 1, f_in));
        } else {
          gid.iLctFlag = 1;
          gid.iSizeOfLct = glsd.iSizeOfGct;
        }
        break;
      }
      else if( c == 0x21 ){
        check_read(fread(&c, 1, 1, f_in));
        if( c == 0xF9 ){
          check_read(fread(&ggce, sizeof(GIF_GRAPHIC_CONTROL_EXTENSION), 1, f_in));
        } else {
          for(;;){
            check_read(fread(&c, 1, 1, f_in));
            if( !c ) break;
            fseek(f_in, c, SEEK_CUR);
          }
        }
      }
    }
    ggce.iBlockSize = 4;
    ggce.iDelayTime = frame_delay;
    ggce.iDisposalMethod = 2;
    c = (char)0x21;
    check_write(fwrite(&c, 1, 1, f_out));
    c = (char)0xF9;
    check_write(fwrite(&c, 1, 1, f_out));
    check_write(fwrite(&ggce, sizeof(GIF_GRAPHIC_CONTROL_EXTENSION), 1, f_out));
    c = (char)0x2C;
    check_write(fwrite(&c, 1, 1, f_out));
    check_write(fwrite(&gid, sizeof(GIF_IMAGE_DESCRIPTOR), 1, f_out));
    check_write(fwrite(szColorTable, iGctSize[gid.iSizeOfLct], 1, f_out));
    check_read(fread(&c, 1, 1, f_in));
    check_write(fwrite(&c, 1, 1, f_out));
    for(;;){
      check_read(fread(&c, 1, 1, f_in));
      check_write(fwrite(&c, 1, 1, f_out));
      if( !c ) break;
      check_read(fread(szColorTable, c, 1, f_in));
      check_write(fwrite(szColorTable, c, 1, f_out));
    }
    fclose(f_in);
  }

  c = (char)0x3B;
  check_write(fwrite(&c, 1, 1, f_out));
  fseek(f_out, 6, SEEK_SET);
  check_write(fwrite(&glsd1, sizeof(GIF_LOGICAL_SCREEN_DESCRIPTOR), 1, f_out));
  fclose(f_out);
}
