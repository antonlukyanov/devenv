--- ������ ������ ��������� ��������� �������� ���������.
-- ���� ������ �� ������� ��������� �������. � ������� ������������ ������������� ����
-- � �������������,  ��� ������ ��� ������� �� ���������� install ����������� devenv.
-- ��������� ������, ������� ���������� � ����������:
-- 
--   cleanenv   - ��������� ������� ���������� ���������;
--   setenv     - ��������� ��������� ���������� ���������;
--   testprg    - ��������� ������� �������� � �� ������;
--   createtree - ������� ������������� ������������� ��������� ��������;
--   reglua     - ������������ ���������� .lua � Windows;
--   lutils     - �������� ������� lua;
--   extutl     - �������� ������� ����������� � �������;
--   localutl   - �������� ��������� ��������� ������� ��� ����������� ��� � ��������� �� lwml.
--   
-- ����� �������� ������� ���������� ���������, ��� ���������� ��� ������� ������ luafilesystem.

dofile 'tools/istools.lua'

--
-- ��������� ������ �����
--

local tasks = {}
local tasks_str = ""
for j = 1, #arg do
  tasks[arg[j]] = true
  tasks_str = tasks_str .. arg[j] .. ' '
end
msg("Tasks: " .. tasks_str)

-- ������������ ������ ��� Linux � OSX.
local user_home = ''
if os_type ~= 'windows' then
  user_home = get_env('HOME')
end

-- <...>/devenv
local home = get_home_path()
-- <...>/devenv/devenv-repository
local repo_home = get_devenv_repo_path()
local fmt = string.format


--
-- ���������� ���������� �����
--

if tasks['cleanenv'] then
  msg "Cleaning environment variables..."

  -- � Windows ���������� �������� � ��������.
  if os_type == 'windows' then
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
  else
    -- (os_type == 'osx' or os_type == 'linux')
    -- � unix-�������� ������������ �������� ���� �������� � ����������, ������� ��������
    -- � ����� .devenv.    
    local devenv = user_home .. '/.devenv'
    rmfile(devenv)
    mkfile(devenv)
    if is_file(devenv) then
      msg "  .devenv was successfully cleaned"
    end
  end
end

--
-- ������������� ���������� �����
--

local env = {
  LWML_ZZZ  = ":log:dump:jit",
  LWDG_HOME = home,
  LUA_PATH  = string.format("%s;./?.lua;%s/lutils/?.lua;%s/lutils/lib/?.lua", package.path, home, home),
  LUA_CPATH = os_type == 'windows'
                and string.format("%s;./?.dll;%s/share/?.dll", package.cpath, home)
                or  string.format("%s;./?.so;%s/share/?.so", package.cpath, home),
}

if os_type ~= 'windows' then
  env.LD_LIBRARY_PATH = home .. '/share'
end

if tasks['setenv'] then
  msg "Setting environment variables..."
  
  local local_paths = {
    'utils',
    'share',
    'lutils',
  }
  
  if os_type == 'windows' then
    local pe = get_env('pathext')
    local pe_tbl = split(pe)
    
    if not pe_tbl['.lua'] then
      set_env('pathext', pe .. ';.lua')
    end
    
    for k, v in pairs(env) do
      set_env(k, v)
    end
    
    log('# current path: <' .. get_env('path') ..'>')
    
    local path_tbl = split(get_env('path'))
    local upath_tbl = split(get_user_path() or '')
    local path_changed = false
    
    local function test_path( path )
      path = norm_path(path)
      if not path_tbl[path] then
        path_tbl[path] = path
        upath_tbl[path] = path
        path_changed = true
        log('PATH+=' .. path)
      end
    end
    
    for _, v in pairs(local_paths) do
      test_path(home .. '/' .. v)
    end
  
    if path_changed then
      msg "  Setting PATH..."
      set_user_env('path', join(upath_tbl))
      set_proc_env('path', join(path_tbl))
    else
      msg "  PATH is ok."
    end
  else
    local devenv = io.open(user_home .. '/.devenv', 'w')
    
    -- ! ����� ����� ���������� ����� pathext?
    
    for k, v in pairs(env) do
      devenv:write('export ', k, "='", v, "':$", k, '\n')
    end
    devenv:write('\n')
    
    for i, path in pairs(local_paths) do
      local_paths[i] = home .. '/' .. path
    end
    devenv:write("export PATH='", table.concat(local_paths, ":"), "':$PATH")
    
    if devenv then
      devenv:close()
    end
    
    msg "  .devenv was successfully written"
    
    -- ������� ���������� ���������� ����� �������� shell ������������.
    local rc_name
    local shell = pipe('echo $SHELL')
    if shell:match('zsh') then
      rc_name = '.zshrc'
    elseif shell:match('bash') then
      rc_name = '.bashrc'
    end
    
    if not rc_name then
      stop('Could not determine shell type (supported: zsh, bash)')
    end
    
    -- ����� �������.
    local rc_filepath = user_home .. '/' .. rc_name
    local rc_filepath_orig = rc_filepath .. '.orig'
    
    if not is_file(rc_filepath_orig) then
      execf('cp', '%s %s', rc_filepath, rc_filepath_orig)
    end
    
    -- �������� �� ������� ������ �������� .devenv � �������. ���� ��� ����, ��
    -- ��� ��� � ������ �� ����.
    local rc = assert(io.open(rc_filepath, 'r'))
    local rc_contents = rc:read('*a')
    rc:close()
    
    if not rc_contents:match('source ~/%.devenv') then
      rc = assert(io.open(rc_filepath, 'a'))
      rc:write('\n')
      rc:write('if [ -f ~/.devenv ]; then source ~/.devenv; fi\n')
      rc:close()
      msg("  " .. rc_name .. ' was successfully updated')
    else
      msg("  no need to update " .. rc_name)
    end
  end
end

--
-- ��������� ������� �������� � �� ������
--
if tasks['testprg'] then
  msg "Testing standard programs..."
  
  local progs = {}
  if os_type == 'windows' then
    progs = {
      ['sh.exe'] = 'please, install msys (1.0.10)',
      ['strip.exe'] = 'please, install mingw (package binutils-2.17.50)',
      ['dos2unix.exe'] = 'please, install mingw (package mingw-utils-0.3)',
      ['gcc.exe'] = 'please, install mingw (package gcc-core-3.4.5)',
      ['g++.exe'] = 'please, install mingw (package gcc-g++-3.4.5)',
    }
  else
    progs = {
      ['bash'] = 'please, install bash',
      ['strip'] = 'please, install strip',
      ['gcc'] = 'please, install gcc',
      ['g++'] = 'please, install g++',  
    }
    
    -- ��� OSX �������� �� strip ���� �����-�� ������, �.�.
    -- � ���� ��� ���������� --version � -v, � ��� ������� ����� ������.
    if os_type == 'osx' then
      progs['strip'] = nil
    end
  end
  
  for prog, msg in pairs(progs) do
    test_exist(prog, msg)
  end
  
  if os_type == 'windows' then
    test_ver('sh.exe', '2.04.0')
    test_ver('gcc.exe', '3.4.5')
  else
    test_ver('gcc', '4.9.1')
  end
end

--
-- ������� ������������� ������������� ��������� ��������
--

if tasks['createtree'] then
  msg "Creating directory tree..."

  local shell
  if os_type == 'windows' then
    shell = 'sh'
  else
    shell = 'bash'
  end
  
  execf(shell, '-c "mkdir -p %s/include"', home)
  execf(shell, '-c "mkdir -p %s/lib"', home)
  execf(shell, '-c "mkdir -p %s/lutils/lib"', home)
  execf(shell, '-c "mkdir -p %s/share"', home)
  execf(shell, '-c "mkdir -p %s/utils"', home)
end

--
-- ������������ ���������� .lua. ������ ��� Windows
--

if tasks['reglua'] then
  msg "Registering lua..."
  if os_type == 'windows' then
    reg_ext('.lua', 'luascript', home .. '/utils/lua.exe')
  else
    msg "  WARNING: you can register .lua only in Windows."
  end
end

--
-- ���������� lua-����������
--

if tasks['lutils'] then
  msg "Building lua utilities..."
  
  -- �������� lua-�������.
  lua_make('lutils', 'setup.lua')
  
  -- ��� Linux � OSX �� ����� �������� llake � lred � exe, ������� ��� ���� ������
  -- ����� ������� �������� ��� ���������� � �������� � ������ ����� #!, �����
  -- ����� ���� ���������.
  if os_type ~= 'windows' then
    execf('cp', '%s/lutils/llake/llake.lua %s/lutils/llake.lua ', repo_home, home)
    execf('cp', '%s/lutils/utils/lred.lua %s/lutils/lred.lua ', repo_home, home)
    
    -- ��� ����� � ����������� .lua.
    local cmd = fmt("find '%s/lutils' -maxdepth 1 -type f -iname '*.lua' | sed s,^./,,", home)
    local dir = assert(io.popen(cmd))
    
    for filepath in dir:lines() do
      -- �.�. ����� ���������, �� ����� ��������� �� � ������ � ��� ����� ���������� ������ � ������.
      local file = assert(io.open(filepath, 'r'))
      local script = file:read('*a')
      file:close()
      
      msg(filepath)
      
      local hashbang = '#!/usr/bin/env lua'
      -- ��������� ���� �� #! � ����� ������ �����, ���� ���, �� ���������.
      if not script:match('^' .. hashbang) then
        file = assert(io.open(filepath ,'w'))
        file:write(hashbang .. '\n\n')
        file:write(script)
        file:close()
        msg("  added hashbang to the beginning.")
      end 
      
      execf('chmod', 'u+x %s', filepath)
      
      -- ������ �������, ����� ����� ���� ��������� ������� ��� ���������� .lua.
      local link_name = filepath:gsub('(.*)(%.lua)', '%1')
      if not is_file(link_name) then
        execf('ln', '-s %s %s', filepath, link_name)
        msg("  created symlink.")
      else
        msg("  no need to create symlink.")
      end
    end
    
    dir:close()
  end
end

--
-- ������ ������� ������
--

if tasks['extutl'] then
  msg "Building external utilities..."
  
  -- �������� libjpeg.
  msg "  Building libjpeg..."
  lua_make('third-party/libjpeg')

  -- �������� libzlib.
  msg "  Building libzlib..."
  lua_make('third-party/zlib')

  -- �������� libtiff.
  msg "  Building libtiff..."
  lua_make('third-party/libtiff')

  if os_type == 'windows' then
    -- �������� lua.
    msg "  Building lua interpreter..."
    local lua_path = 'third-party/lua-addons/setup'
    execf('cp', 'temp/standalone-lua.exe ../%s', lua_path)
    lua_make(lua_path, 'build_lua.lua')
    rmfile('../' .. lua_path .. '/' .. 'standalone-lua.exe')
      
    -- �������� ��������� lua-������.
    msg "  Building lua module lfs"
    lua_make(lua_path, 'build_lfs.lua')
    
    -- @Todo: � Lua 5.2 �� ����������. �������� �� luaL_putchar().
    -- msg "  Building lua module md5"
    -- lua_make(lua_path, 'build_md5.lua')
    
    -- ����������� ����������� lua-�������.
    msg "  Building lua scripts..."
    
    local hlpath = repo_home .. '/lutils'
    execf('lua', '%s/lutils/luaccc.lua lred.exe %s/utils/lred.lua >nul', home, hlpath)
    execf('lua', '%s/lutils/luaccc.lua llake.exe %s/llake/llake.lua >nul', home, hlpath)
    execf('mv', 'lred.exe llake.exe %s/utils', home)
    
    -- �������� ��������� �������.
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
end

if tasks['md5'] then
  local lua_path = 'third-party/lua-addons/setup'
  msg "Building lua module md5"
  lua_make(lua_path, 'build_md5.lua')
end

--
-- ������ ������ � ���������, ������������ ��� ������ llake.
--
if tasks['localutl'] then
  msg "Building local utilities..."

  -- @Todo: ���������� ��� Linux: lswg, lualwml, limlib.

  if os_type == 'windows' then
    -- ����������� �� lwml �������.
    llake_make('secluded/ldatav', 'ldatav.exe', 'utils')
    llake_make('secluded/limlib', 'limlib.dll', 'share')
    llake_make('secluded/llogsrv', 'llogsrv.dll', 'share')
  
    -- ��������� �� lwml �������.
    llake_make('lwml-dep/dllver', 'dllver.exe', 'utils')
    llake_make('lwml-dep/limcov', 'limcov.dll', 'share')
    
    -- @Todo: ��������� ������ � ����������������.
    -- llake_make('lualib/lswg', 'lswg.dll', 'share')
    
    -- @Todo: �� ���������� � Lua 5.2.
    -- llake_make('lualib/lswp', 'lswp.dll', 'share')
    -- llake_make('lualib/lualwml', 'lualwml.dll', 'share')
    llake_make('lwml-dep/lwhich', 'lwhich.exe', 'utils')
  
    -- �����������.
    local hlc_path = '../lwml-dep/limcov'
    execf('cp', '%s/limcov_dll.h %s/include', hlc_path, home)
    execf('cp', '%s/limcov.a %s/lib/liblimcov.a', hlc_path, home)
  else
    llake_make('secluded/llogsrv', 'llogsrv', 'share')
  end
end
