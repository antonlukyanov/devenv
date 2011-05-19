home = os.getenv('LWDG_HOME')

function copy( dst, src )
  os.execute('cp ' .. './'..src .. ' ' .. home..'/'..dst)
end

list = {
 { 'lutils/lib', 'lib/libawk.lua' },
 { 'lutils/lib', 'lib/libcmdl.lua' },
 { 'lutils/lib', 'lib/libcsv.lua' },
 { 'lutils/lib', 'lib/libdir.lua' },
 { 'lutils/lib', 'lib/libexport.lua' },
 { 'lutils/lib', 'lib/libfname.lua' },
 { 'lutils/lib', 'lib/libhtml.lua' },
 { 'lutils/lib', 'lib/libiconv.lua' },
 { 'lutils/lib', 'lib/libiexplorer.lua' },
 { 'lutils/lib', 'lib/liblang.lua' },
 { 'lutils/lib', 'lib/libluaps.lua' },
 { 'lutils/lib', 'lib/libmacro.lua' },
 { 'lutils/lib', 'lib/libmd5.lua' },
 { 'lutils/lib', 'lib/libprot.lua' },
 { 'lutils/lib', 'lib/librexp.lua' },
 { 'lutils/lib', 'lib/libsys.lua' },
 { 'lutils/lib', 'lib/libwaki.lua' },
 { 'lutils/lib', 'lib/librepo.lua' },

 { 'lutils', 'luaht/luaht.lua' },
 { 'lutils', 'luaht/mkdoc.lua' },

 { 'lutils', 'lwdg/imgfact.lua' },
 { 'lutils', 'lwdg/llog.lua' },
 { 'lutils', 'lwdg/mkam.lua' },
 { 'lutils', 'lwdg/find866.lua' },
 { 'lutils', 'lwdg/lakitall.lua' },
 { 'lutils', 'lwdg/rdep.lua' },
 { 'lutils', 'lwdg/lsvnsync.lua' },
 { 'lutils', 'lwdg/cpunver.lua' },

 { 'lutils', 'meta/luacc.lua' },
 { 'lutils', 'meta/luaccc.lua' },
 { 'lutils/lib', 'meta/luacc_driver.lua' },

 { 'lutils', 'rcs/mkrcs.lua' },
 { 'lutils/lib', 'rcs/librcs.lua' },

 { 'lutils', 'utils/bin2hex.lua' },
 { 'lutils', 'utils/cplist.lua' },
 { 'lutils', 'utils/csv2html.lua' },
 { 'lutils', 'utils/fhist.lua' },
 { 'lutils', 'utils/hex2bin.lua' },
 { 'lutils', 'utils/hist.lua' },
 { 'lutils', 'utils/lenv.lua' },
 { 'lutils', 'utils/lgrep.lua' },
 { 'lutils', 'utils/lsed.lua' },
 { 'lutils', 'utils/ltimer.lua' },
 { 'lutils', 'utils/lwc.lua' },
 { 'lutils', 'utils/mkbinchunk.lua' },
 { 'lutils', 'utils/mktmpd.lua' },
 { 'lutils', 'utils/pwd.lua' },
}

for _, r in ipairs(list) do
  copy(r[1], r[2])
end
