require "libsys"

__ = sys.exec

src_path = "src/"

mlist = "jcapimin.c jcapistd.c jctrans.c jcparam.c jdatadst.c jcinit.c jcmaster.c " .. 
        "jcmarker.c jcmainct.c jcprepct.c jccoefct.c jccolor.c jcsample.c jchuff.c " ..
        "jcphuff.c jcdctmgr.c jfdctfst.c jfdctflt.c jfdctint.c jdapimin.c jdapistd.c " ..
        "jdtrans.c jdatasrc.c jdmaster.c jdinput.c jdmarker.c jdhuff.c jdphuff.c " ..
        "jdmainct.c jdcoefct.c jdpostct.c jddctmgr.c jidctfst.c jidctflt.c jidctint.c " ..
        "jidctred.c jdsample.c jdcolor.c jquant1.c jquant2.c jdmerge.c jcomapi.c jutils.c " ..
        "jerror.c jmemmgr.c jmemnobs.c"

hlist = "cderror.h cdjpeg.h jchuff.h jdct.h jdhuff.h jerror.h jinclude.h jmemsys.h " ..
        "jmorecfg.h jpegint.h jpeglib.h jversion.h transupp.h"

mlist_p = ''
for s in mlist:gmatch('%S+') do
  mlist_p = mlist_p .. src_path .. s .. ' '
end

olist = ''
for s in mlist:gmatch('%S+') do
  olist = olist .. string.gsub(s, '(.*)%.c', '%1.o') .. ' '
end

__('gcc -c -D"INT32=long" -DALL_STATIC -Isrc -I. ' .. mlist_p)
__('ar rcu libjpeg.a ' .. olist )
__('rm *.o' )


-- setup

home = os.getenv('LWDG_HOME')

lib = home .. "/lib"
inc = home .. "/include"

__("mv libjpeg.a " .. lib)

for fn in hlist:gmatch('%S+') do
  __({SRC = src_path, FN = fn, INC = inc}, "cp ${SRC}/${FN} ${INC}")
end
__({INC = inc}, "cp jconfig.h ${INC}")
