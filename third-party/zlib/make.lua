require "libsys"

__ = sys.exec

src_path = "src/"

mlist = "adler32.c compress.c crc32.c gzio.c uncompr.c deflate.c trees.c " ..
         "zutil.c inflate.c infback.c inftrees.c inffast.c"

mlist_p = ''
for s in mlist:gmatch('%S+') do
  mlist_p = mlist_p .. src_path .. s .. ' '
end

__('gcc -c -Isrc -I. ' .. mlist_p)
__('ar rcu libzlib.a *.o' )
__('rm *.o' )

-- setup

home = os.getenv('LWDG_HOME')

lib = home .. "/lib"
inc = home .. "/include"

__("mv libzlib.a " .. lib)
__({INC = inc, SRC = src_path}, "cp ${SRC}/zlib.h ${INC}")
__({INC = inc}, "cp zconf.h ${INC}")
