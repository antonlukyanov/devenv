require "libsys"

__ = sys.exec

src_path = "src/"

mlist = "tif_aux.c tif_close.c tif_codec.c tif_color.c tif_compress.c tif_dir.c " ..
        "tif_dirinfo.c tif_dirread.c tif_dirwrite.c tif_dumpmode.c tif_error.c " ..
        "tif_extension.c tif_fax3.c tif_fax3sm.c tif_flush.c tif_getimage.c tif_jpeg.c " ..
        "tif_luv.c tif_lzw.c tif_next.c tif_ojpeg.c tif_open.c tif_packbits.c tif_pixarlog.c " ..
        "tif_predict.c tif_print.c tif_read.c tif_strip.c tif_swab.c tif_thunder.c tif_tile.c " ..
        "tif_unix.c tif_version.c tif_warning.c tif_write.c tif_zip.c"

hlist = "t4.h tif_dir.h tif_fax3.h tif_predict.h tiff.h tiffconf.h tiffio.h " ..
        "tiffiop.h tiffvers.h uvcode.h"

mlist_p = ''
for s in mlist:gmatch('%S+') do
  mlist_p = mlist_p .. src_path .. s .. ' '
end

__('gcc -c -DALL_STATIC -Isrc -I. -I../libjpeg/src -I../libjpeg -I../zlib -I../zlib/src ' .. mlist_p)
__('ar rcu libtiff.a *.o' )
__('rm *.o' )

-- setup

home = os.getenv('LWDG_HOME')

lib = home .. "/lib"
inc = home .. "/include"

__("mv libtiff.a " .. lib)

for fn in hlist:gmatch('%S+') do
  __({SRC = src_path, FN = fn, INC = inc}, "cp ${SRC}/${FN} ${INC}")
end
__({INC = inc}, "cp tif_config.h ${INC}")
