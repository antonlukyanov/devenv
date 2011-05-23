-- Этот скрипт не следует запускать вручную.

model = arg[1]
if not model then model = 'dll' end

dofile('tools/istools.lua')

-- параметры

build_name = 'build-lwdg-' .. model
wxsrc_msys_path = '/usr/local/src/wxWidgets-2.6.4'
lwdg_msys_path = '/lwdg'
wxdst_msys_path = lwdg_msys_path .. '/wx'
patch_msys_path = lwdg_msys_path .. '/utils/third-party/wx/wxwidgets-2.6.4.diff'

options = '--enable-vendor=lwdg --with-msw --enable-gui --with-opengl --enable-exceptions --disable-precomp-headers'
if model == 'static' then
  options = options .. ' --enable-static --disable-shared --enable-monolithic'
else
  options = options .. ' --enable-shared --disable-static'
end

-- подготовка fstab в msys

msys = get_cfg_path('msys')
mingw = get_cfg_path('mingw')
wxsrc = get_cfg_path('wxsrc')

execf('cp %s/etc/fstab temp', msys)

file = assert(io.open(msys .. '/etc/fstab', 'wt'))
file:write(mingw, ' /mingw\n')
file:write(calc_home(), ' ', lwdg_msys_path, '\n')
file:write(wxsrc, ' ', wxsrc_msys_path, '\n')
file:close()

-- подготовка и запуск скрипта сборки

file = assert(io.open('temp/install_wx.sh', 'wt'))
function w(...) file:write(string.format(...), '\n') end

w('wxname=%s', build_name)
w('cd %s', wxsrc_msys_path)
w('patch -N --strip=1 --input=%s', patch_msys_path)
w('mkdir $wxname')
w('cd $wxname')
w('../configure --prefix=%s/$wxname %s', wxdst_msys_path, options)
w('make')
w('make install')

file:close()

os.execute(msys .. '/bin/sh ./temp/install_wx.sh')

execf('cp temp/fstab %s/etc/fstab ', msys)
