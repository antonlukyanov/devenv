-- Этот скрипт не следует запускать вручную.

-- В скрипте используются относительные пути в предположении,
-- что скрипт был запущен из директории install репозитория utils

dofile('tools/istools.lua')

--
-- Формируем список задач
--
do
  tasks = {}
  local tasks_str = ""
  for j =1, #arg do
    tasks[arg[j]] = true
    tasks_str = tasks_str .. arg[j] .. ' '
  end
  msg("Tasks: " .. tasks_str)
end

home = calc_home()

--
-- Сбрасываем переменные среды
--
if tasks['cleanenv'] then
  msg "Cleaning environment variables..."

  del_env("lwml_zzz", "")
  del_env("lua_path", "")
  del_env("lua_cpath", "")
  del_env("lwdg_home", "")
  del_env("wxwin", "")

  path_tbl = split(get_env('path'))
  upath_tbl = split(get_user_path() or '')

  local path_changed = false

  function del_path( path )
    path = norm_path(path)
    if upath_tbl[path] then
      path_tbl[path] = nil
      upath_tbl[path] = nil
      path_changed = true
      log('PATH-=' .. path)
    end
  end

  del_path(home .. '/utils')
  del_path(home .. '/share')
  del_path(home .. '/lutils')

  del_path(home .. "/wx/build-lwdg-dll/lib")

  if path_changed then
    msg "  Setting PATH..."
    local new_user_path = join(upath_tbl)
    if new_user_path == "" then
      del_user_env('path')
    else
      set_user_env('path', new_user_path)
    end
    set_proc_env('path', join(path_tbl))
  else
    msg "  PATH is ok."
  end
end

--
-- Устанавливаем переменные среды
--
if tasks['setenv'] then
  msg "Setting environment variables..."

  do
    local pe = get_env('pathext')
    local pe_tbl = split(pe)
    if not pe_tbl['.lua'] then
      set_env('pathext', pe .. ';.lua')
    end
  end

  set_env("lwml_zzz", ":log:dump:jit")

  set_env("lua_path", string.format("./?.lua;%s/lutils/?.lua;%s/lutils/lib/?.lua", home, home))
  set_env("lua_cpath", string.format("./?.dll;%s/share/?.dll", home))

  set_env("lwdg_home", home)

  set_env("wxwin", home .. "/wx/")

  log('# current path: <' .. get_env('path') ..'>')
  path_tbl = split(get_env('path'))
  upath_tbl = split(get_user_path() or '')

  local path_changed = false

  function test_path( path )
    path = norm_path(path)
    if not path_tbl[path] then
      path_tbl[path] = path
      upath_tbl[path] = path
      path_changed = true
      log('PATH+=' .. path)
    end
  end

  test_path(home .. '/utils')
  test_path(home .. '/share')
  test_path(home .. '/lutils')

  test_path(home .. "/wx/build-lwdg-dll/lib")

  if path_changed then
    msg "  Setting PATH..."
    set_user_env('path', join(upath_tbl))
    set_proc_env('path', join(path_tbl))
  else
    msg "  PATH is ok."
  end
end

--
-- Проверяем наличие программ и их версии.
--
if tasks['testprg'] then
  msg "Testing standard programs..."

  -- проверяем наличие программ
  function test_exist( prog, msg )
    if exec(prog .. ' --version >nul 2>nul') ~= 0 then
      stop("can't run <%s>, %s", prog, msg)
    end
  end

  -- msys
  test_exist('sh.exe', 'please, install msys (1.0.10)')

  -- mingw
  test_exist('strip.exe', 'please, install mingw (package binutils-2.17.50)')
  test_exist('dos2unix.exe', 'please, install mingw (package mingw-utils-0.3)')
  test_exist('gcc.exe', 'please, install mingw (package gcc-core-3.4.5)')
  test_exist('g++.exe', 'please, install mingw (package gcc-g++-3.4.5)')

  -- проверяем версии программ
  function test_ver( prog, ver )
    local fn = '.' .. os.tmpname()
    if exec(prog .. ' --version >' .. fn) ~= 0 then
      stop("can't run <%s>", prog)
    end
    local file = assert(io.open(fn, 'rt'))
    local pver = file:read('*line')
    file:close()
    os.remove(fn)

    local pver_label = pver:match('(%d+%.%d+%.%d+)')
    local pver_l1, pver_l2, pver_l3 = pver:match('(%d+)%.(%d+)%.(%d+)')
    if type(ver) == 'string' and pver ~= ver then
      return
    elseif type(ver) == 'function' and ver(pver_l1, pver_l2, pver_l3) then
      return
    else
      if type(ver) == 'string' then
        msg('** expected: ver=<' .. ver .. '>')
        msg('** ...found: ver=<' .. pver .. '>')
      end
      stop("incorrect version of <%s>", prog)
    end
  end

  test_ver('sh.exe', '2.04.0')
  test_ver('gcc.exe', '3.4.5')
end

--
-- создаем отсутствующие поддиректории домашнего каталога
--
if tasks['createtree'] then
  msg "Creating directory tree..."

  execf('sh -c "mkdir -p %s/include"', home)
  execf('sh -c "mkdir -p %s/lib"', home)
  execf('sh -c "mkdir -p %s/lutils/lib"', home)
  execf('sh -c "mkdir -p %s/share"', home)
  execf('sh -c "mkdir -p %s/utils"', home)
end

--
-- регистрируем расширение .lua
--
if tasks['reglua'] then
  msg "Registering lua..."

  reg_ext('.lua', 'luascript', home .. '/utils/lua.exe')
end

--
-- Построение lua-подсистемы
--
if tasks['lutils'] then
  msg "Building lua utilities..."

  -- копируем lua-утилиты
  lua_make('lutils', 'setup.lua')
end

--
-- Сборка внешних утилит
--
if tasks['extutl'] then
  msg "Building external utilities..."

  -- собираем lua
  msg "  Building lua interpreter..."
  local lua_path = 'third-party/lua-addons/setup'
  execf('cp temp/standalone-lua.exe ../%s', lua_path)
  lua_make(lua_path, 'build_lua.lua')
  os.remove('../' .. lua_path .. '/' .. 'standalone-lua.exe')

  -- собираем libjpeg
  msg "  Building libjpeg..."
  lua_make('third-party/libjpeg')

  -- собираем libzlib
  msg "  Building libzlib..."
  lua_make('third-party/zlib')

  -- собираем libtiff
  msg "  Building libtiff..."
  lua_make('third-party/libtiff')

  -- собираем сторонние lua-модули
  msg "  Building lua modules..."
  lua_make(lua_path, 'build_lfs.lua')
  lua_make(lua_path, 'build_md5.lua')

  -- компилируем специфичные lua-скрипты
  msg "  Building lua scripts..."
  local hlpath = '../lutils' --!!
  execf('lua %s/lutils/luaccc.lua %s/utils/lred.lua >nul', home, hlpath)
  execf('lua %s/lutils/luaccc.lua %s/llake/llake.lua >nul', home, hlpath)
  execf('mv lred.exe llake.exe %s/utils', home)

  -- собираем сторонние утилиты
  msg "  Building additional utilities..."
  lua_make('third-party/ccalc')
  lua_make('third-party/dbmon')
  lua_make('third-party/winutl')
  lua_make('third-party/jpeg2ps')
  lua_make('third-party/mimetex')

  if not is_file(home .. '/share/libiconv2.dll') then
    msg("** can't find <libiconv2.dll>, building luaiconv.dll skipped")
  else
    lua_make('third-party/luaiconv')
  end
end

--
-- Сборка утилит и библиотек, использующих при сборке llake.
--
if tasks['localutl'] then
  msg "Building local utilities..."

  function make( path, name, dst )
    cdrun(path, 'llake -s make build.llk 2>nul 1>nul')
    local src = '../' .. path .. '/' .. name
    local dst = home .. '/' .. dst
    execf("mv %s %s", src, dst)
  end

  -- независимые от lwml утилиты

  make('secluded/ldatav', 'ldatav.exe', 'utils')
  make('secluded/limlib', 'limlib.dll', 'share')
  make('secluded/llogsrv', 'llogsrv.dll', 'share')

  -- зависимые от lwml утилиты

  make('lwml-dep/dllver', 'dllver.exe', 'utils')
  make('lwml-dep/limcov', 'limcov.dll', 'share')
  make('lualib/lswg', 'lswg.dll', 'share')
  make('lualib/lswp', 'lswp.dll', 'share')
  make('lualib/lualwml', 'lualwml.dll', 'share')
  make('lwml-dep/lwhich', 'lwhich.exe', 'utils')

  -- копирование

  local hlc_path = '../lwml-dep/limcov'
  execf('cp %s/limcov_dll.h %s/include', hlc_path, home)
  execf('cp %s/limcov.a %s/lib/liblimcov.a', hlc_path, home)
end
