#include <stdio.h>
#include <malloc.h>

#include "limlib_dll.h"

#define RED_GRAY_WEIGHT   0.299
#define GREEN_GRAY_WEIGHT 0.587
#define BLUE_GRAY_WEIGHT  0.114

int main( int argc, char **argv )
{
  if(argc != 2){
    printf ( "Usage: test <imgfile>" );
    return 2;
  }
  int w, h;

  if( LIMLIB_OK != limlib_size( argv[1], &w, &h ) ){
    printf("error: %s\n", limlib_errmsg());
    return 1;
  }
  printf("lx = %d, ly = %d\n", w, h);

// grayscale
 
  unsigned char* data = (unsigned char*)malloc(w*h);
  if( data == 0 ){
    printf("error: can't allocate memory\n" );
    return 1;
  }

  if( LIMLIB_OK != limlib_load(argv[1], data) ){
    printf("error: %s\n", limlib_errmsg() );
    return 1;
  }
  if( LIMLIB_OK != limlib_save("out.jpg", w, h, data) ){
    printf("error: %s\n", limlib_errmsg() );
    return 1;
  }

// rgb

  unsigned char* data_rgb = (unsigned char*)malloc(w*h*3);
  if( data_rgb == 0 ){
    printf("error: can't allocate memory\n" );
    return 1;
  }

  if( LIMLIB_OK != limlib_load_rgb(argv[1], data_rgb) ){
    printf("error: %s\n", limlib_errmsg() );
    return 1;
  }
  for( int j = 0; j < w*h; j++ )
    data[j] = (unsigned char)(RED_GRAY_WEIGHT * data_rgb[3*j] + GREEN_GRAY_WEIGHT * data_rgb[3*j+1] + BLUE_GRAY_WEIGHT * data_rgb[3*j+2]);
  if( LIMLIB_OK != limlib_save("out_rgb.jpg", w, h, data) ){
    printf("error: %s\n", limlib_errmsg() );
    return 1;
  }

  return 0;
}
