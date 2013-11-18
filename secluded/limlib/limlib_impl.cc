#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include <math.h>

#include "limlib_impl.h"

extern "C" {
  #define ALL_STATIC
  /**/#include "jpeglib.h"
  #define AVOID_WIN32_FILEIO
  /**/#include "tiffio.h"
}

char const* last_err_msg = 0;

// jpeg

struct my_error_mgr
{
  struct jpeg_error_mgr pub;
  jmp_buf setjmp_buffer;
};

typedef struct my_error_mgr * my_error_ptr;

void my_error_exit( j_common_ptr cinfo )
{
  my_error_ptr myerr = (my_error_ptr) cinfo->err;
  (*cinfo->err->output_message)(cinfo); //!!
  longjmp(myerr->setjmp_buffer, 1);
}

void my_output_message( j_common_ptr cinfo )
{
  static char buffer[JMSG_LENGTH_MAX];
  (*cinfo->err->format_message) (cinfo, buffer);
  last_err_msg = buffer;
}

bool readjpeghdr( const char* filename, int* lx, int* ly )
{
  last_err_msg = 0;

  struct jpeg_decompress_struct cinfo;
  struct my_error_mgr jerr;
  FILE * infile;

  if( (infile = fopen(filename, "rb")) == NULL ){
    last_err_msg = "can't open file";
    return false;
  }

  cinfo.err = jpeg_std_error(&(jerr.pub));
  jerr.pub.error_exit = my_error_exit;
  jerr.pub.output_message = my_output_message;
  if( setjmp(jerr.setjmp_buffer) ){
    jpeg_destroy_decompress( &cinfo );
    fclose( infile );
    if( 0 == last_err_msg )
      last_err_msg = "unknown error occured";
    return false;
  }
  jpeg_create_decompress( &cinfo );
  jpeg_stdio_src( &cinfo, infile );
  (void) jpeg_read_header(&cinfo, TRUE);
//----------------------------
  *lx = cinfo.image_width;
  *ly = cinfo.image_height;
//---------------------
  jpeg_destroy_decompress(&cinfo);
  fclose(infile);
  return true;
}

bool readjpeg( char const* filename, unsigned char* data )
{
  last_err_msg = 0;

  struct jpeg_decompress_struct cinfo;
  struct my_error_mgr jerr;
  FILE * infile;
  JSAMPROW row_pointer;

  if( (infile = fopen(filename, "rb")) == NULL ){
    last_err_msg = "can't open jpeg";
    return false;
  }

  cinfo.err = jpeg_std_error(&(jerr.pub));
  jerr.pub.error_exit = my_error_exit;
  jerr.pub.output_message = my_output_message;
  if( setjmp(jerr.setjmp_buffer) ){
    jpeg_destroy_decompress( &cinfo );
    fclose( infile );
    if( 0 == last_err_msg )
      last_err_msg = "unknown error occured";
    return false;
  }
  jpeg_create_decompress( &cinfo );
  jpeg_stdio_src( &cinfo, infile );
  (void) jpeg_read_header(&cinfo, TRUE);
///---------------------
  cinfo.out_color_space = JCS_GRAYSCALE;
  (void) jpeg_start_decompress(&cinfo);

  int width = cinfo.output_width;
  row_pointer = (JSAMPROW)malloc(cinfo.output_width * sizeof(JSAMPLE));
  if( row_pointer == 0 )
    return false;

  while( cinfo.output_scanline < cinfo.output_height ){
    (void) jpeg_read_scanlines(&cinfo, &row_pointer, 1);
    int sh = width * (cinfo.output_scanline-1);
    for( int i = 0; i < width; i++ )
      data[sh + i] = row_pointer[i];
  }

  free(row_pointer);

  (void) jpeg_finish_decompress(&cinfo);
///-------------------------
  jpeg_destroy_decompress(&cinfo);
  fclose(infile);
  return true;
}

bool readjpeg_rgb( char const* filename, unsigned char* data )
{
  last_err_msg = 0;

  struct jpeg_decompress_struct cinfo;
  struct my_error_mgr jerr;
  FILE * infile;
  JSAMPROW row_pointer;

  if( (infile = fopen(filename, "rb")) == NULL ){
    last_err_msg = "can't open jpeg";
    return false;
  }

  cinfo.err = jpeg_std_error(&(jerr.pub));
  jerr.pub.error_exit = my_error_exit;
  jerr.pub.output_message = my_output_message;
  if( setjmp(jerr.setjmp_buffer) ){
    jpeg_destroy_decompress( &cinfo );
    fclose( infile );
    if( 0 == last_err_msg )
      last_err_msg = "unknown error occured";
    return false;
  }
  jpeg_create_decompress( &cinfo );
  jpeg_stdio_src( &cinfo, infile );
  (void) jpeg_read_header(&cinfo, TRUE);
///---------------------
  cinfo.out_color_space = JCS_RGB;
  (void) jpeg_start_decompress(&cinfo);

  int width = cinfo.output_width;
  if( cinfo.num_components != 3 )
    return false;
  row_pointer = (JSAMPROW)malloc(cinfo.output_width * cinfo.num_components * sizeof(JSAMPLE));
  if( row_pointer == 0 )
    return false;

  while( cinfo.output_scanline < cinfo.output_height ){
    (void) jpeg_read_scanlines(&cinfo, &row_pointer, 1);
    int sh = width * cinfo.num_components * (cinfo.output_scanline-1);
    for( int i = 0; i < cinfo.num_components * width; i++ )
      data[sh + i] = row_pointer[i];
  }

  free(row_pointer);

  (void) jpeg_finish_decompress(&cinfo);
///-------------------------
  jpeg_destroy_decompress(&cinfo);
  fclose(infile);
  return true;
}

bool writejpeg( const char *filename, int lx, int ly, const unsigned char* data )
{
//  assert( BITS_IN_JSAMPLE == cdepth );
  last_err_msg = 0;

  struct jpeg_compress_struct cinfo;
  struct my_error_mgr jerr;

  FILE * outfile;
  JSAMPROW row_pointer;
//  int row_stride;

  if( (outfile = fopen(filename, "wb")) == NULL ){
    last_err_msg = "can't create file";
    return false;
  }

  cinfo.err = jpeg_std_error(&(jerr.pub));
  jerr.pub.error_exit = my_error_exit;
  jerr.pub.output_message = my_output_message;

  if( setjmp(jerr.setjmp_buffer) ){
    jpeg_destroy_compress( &cinfo );
    fclose( outfile );
    free(row_pointer);
    if( 0 == last_err_msg )
      last_err_msg = "unknown error occured";
    return false;
  }

  jpeg_create_compress( &cinfo );
  jpeg_stdio_dest( &cinfo, outfile );

  cinfo.image_width = lx;   /* image width and height, in pixels */
  cinfo.image_height = ly;
  cinfo.input_components = 1;   /* # of color components per pixel */
  cinfo.in_color_space = JCS_GRAYSCALE;   /* colorspace of input image */
  jpeg_set_defaults(&cinfo);
  jpeg_set_quality(&cinfo, 100, TRUE /* limit to baseline-JPEG values */);

  jpeg_start_compress(&cinfo, TRUE);

  row_pointer = (JSAMPROW)malloc(cinfo.image_width * sizeof(JSAMPLE));
  if( row_pointer == 0 )
    return false;
  while( cinfo.next_scanline < cinfo.image_height ){
    for( unsigned i = 0;  i < cinfo.image_width; i++ ){
      int idx = cinfo.image_width*cinfo.next_scanline + i;
      row_pointer[i] = data[idx];
    }
    (void) jpeg_write_scanlines( &cinfo, &row_pointer, 1 );
  }
  free(row_pointer);
  row_pointer = 0;

  jpeg_finish_compress(&cinfo);
  fclose(outfile);
  jpeg_destroy_compress(&cinfo);
  return true;
}

// tiff

void my_TIFFErrorHandler(const char* module, const char* fmt, va_list ap)
{
  static char eb[1024];
  static char err_buf[1024];
  char const *m = "(unknown libtiff module)";
  if( module != NULL )
    m = module;
  _vsnprintf(eb, sizeof(eb), fmt, ap);
  _snprintf(err_buf, sizeof(err_buf), "%s: %s.\n", m, eb );
}

// from rgb.cc

#define RED_GRAY_WEIGHT   0.299
#define GREEN_GRAY_WEIGHT 0.587
#define BLUE_GRAY_WEIGHT  0.114

bool readtiffhdr( const char* filename, int* lx, int* ly )
{
  bool ok = false;
  last_err_msg = 0;
  TIFFErrorHandler oldteh = TIFFSetErrorHandler( my_TIFFErrorHandler );
  TIFFErrorHandler oldtwh = TIFFSetWarningHandler( 0 );
  TIFF* tif = TIFFOpen(filename, "r");
  if( tif ){
    uint32 w, h;
    TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &w);
    TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h);
    *lx = w;
    *ly = h;
    TIFFClose(tif);
    ok = true;
  } else {
    if( last_err_msg == 0 )
      last_err_msg = "cannot open tiff file";
    ok = false;
  }
  TIFFSetErrorHandler( oldteh );
  TIFFSetWarningHandler( oldtwh );
  return ok;
}

namespace fpr {
  typedef double real;
  inline real round( real x ) { return (x < 0.0) ? ceil(x - 0.5) : floor(x + 0.5); }
  inline int lround( real x ) { return static_cast<int>(round(x)); }
};

bool readtiff( char const* filename, unsigned char* data )
{
  last_err_msg = 0;
  TIFFErrorHandler oldteh = TIFFSetErrorHandler( my_TIFFErrorHandler );
  TIFFErrorHandler oldtwh = TIFFSetWarningHandler( 0 );
  TIFF* tif = TIFFOpen(filename, "r");
  if( tif == 0 ){
    last_err_msg = "cannot open tiff file";
    return false;
  }

  uint32 w, h;
  TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &w);
  TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h);

  int width = w;
  int height = h;
  uint32* buf = (uint32*)malloc(width * height * sizeof(uint32));
  if( buf == 0 )
    return false;
  if( TIFFReadRGBAImage(tif, width, height, buf, 0) ){
    for( int y = 0; y < height; y++ ){
      int buf_sh = y * width;
      int tiff_sh = (height-1 - y) * width;
      for( int x = 0; x < width; x++ ){
        int tif_idx = tiff_sh + x;
        double br = RED_GRAY_WEIGHT * TIFFGetR(buf[tif_idx]) +
                    GREEN_GRAY_WEIGHT * TIFFGetG(buf[tif_idx]) +
                    BLUE_GRAY_WEIGHT * TIFFGetB(buf[tif_idx]);
        data[buf_sh + x] = static_cast<unsigned char>(fpr::lround(br));
      }
    }
  } else {
    last_err_msg = "cannot read tiff image";
    return false;
  }
  free(buf);
  TIFFClose(tif);

  TIFFSetErrorHandler( oldteh );
  TIFFSetWarningHandler( oldtwh );
  return true;
}

bool readtiff_rgb( char const* filename, unsigned char* data )
{
  last_err_msg = 0;
  TIFFErrorHandler oldteh = TIFFSetErrorHandler( my_TIFFErrorHandler );
  TIFFErrorHandler oldtwh = TIFFSetWarningHandler( 0 );
  TIFF* tif = TIFFOpen(filename, "r");
  if( tif == 0 ){
    last_err_msg = "cannot open tiff file";
    return false;
  }

  uint32 w, h;
  TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &w);
  TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h);

  int width = w;
  int height = h;
  uint32* buf = (uint32*)malloc(width * height * sizeof(uint32));
  if( buf == 0 )
    return false;
  if( TIFFReadRGBAImage(tif, width, height, buf, 0) ){
    for( int y = 0; y < height; y++ ){
      int buf_sh = y * width * 3;
      int tiff_sh = (height-1 - y) * width;
      for( int x = 0; x < width; x++ ){
        int tif_idx = tiff_sh + x;
        int buf_idx = buf_sh + 3*x;
        data[buf_idx + 0] = TIFFGetR(buf[tif_idx]);
        data[buf_idx + 1] = TIFFGetG(buf[tif_idx]);
        data[buf_idx + 2] = TIFFGetB(buf[tif_idx]);
      }
    }
  } else {
    last_err_msg = "cannot read tiff image";
    return false;
  }
  free(buf);
  TIFFClose(tif);

  TIFFSetErrorHandler( oldteh );
  TIFFSetWarningHandler( oldtwh );
  return true;
}
