Патч для бага в заголовках gcc 4.6.2

Из заголовка '/mingw/lib/gcc/mingw32/4.6.2/include/float.h'
не включается заголовок '/mingw/include/float.h'.

do-patch-gcc.sh
  скрипт для применения патча
float.diff
  сам патч
float-bug.cpp
  тестовое приложение для демонстрации бага
