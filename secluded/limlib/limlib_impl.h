#ifndef _LIMLIB_IMPL_
#define _LIMLIB_IMPL_

#include <malloc.h>

extern char const* last_err_msg;

bool readjpeghdr( const char* filename, int* lx, int* ly );
bool readtiffhdr( const char* filename, int* lx, int* ly );

bool readjpeg( const char* filename, unsigned char* data );
bool readtiff( const char* filename, unsigned char* data );

bool readjpeg_rgb( const char* filename, unsigned char* data );
bool readtiff_rgb( const char* filename, unsigned char* data );

bool writejpeg( const char* filename, int lx, int ly, const unsigned char* data );

#endif // _LIMLIB_IMPL_
