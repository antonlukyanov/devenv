#ifndef __CONFIG_H__
#define __CONFIG_H__

#if defined(_WIN32) && !defined(__MINGW32__)

typedef __int64 int_t;
typedef unsigned __int64 unsigned_t;
#if defined(__IBMCPP__)
#define INT_FORMAT "ll"
#else
#define INT_FORMAT "I64"
#endif

#elif SIZEOF_LONG == 8

typedef long int_t;
typedef unsigned long unsigned_t;
#define INT_FORMAT "l"

#else 

typedef long long int_t;
typedef unsigned long long unsigned_t;
#ifdef __MINGW32__
#define INT_FORMAT "I64"
#else
#define INT_FORMAT "ll"
#endif

#endif

#endif
