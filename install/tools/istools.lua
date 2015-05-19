-- Installation Support Tools

dofile '../lutils/lib/libplatform.lua'

success_code = platform.get_success_code()
os_type = platform.get_os_type()

--
-- �������� �������
--

lfs = require 'lfs'

--- �������� ����� �� ������������� � �������� �������.
function is_file( nm )
  local file = io.open(nm, 'rb')
  local res = (file ~= nil)
  if file then
    file:close()
  end
  return res
end

function cwd()
  return lfs.currentdir()
end

function chdir( path )
  return lfs.chdir(path)
end

function mkfile( filepath )
  assert(io.open(filepath, 'w')):close()
end

function rmfile( filepath )
  if is_file(filepath) then
    local ok, msg = os.remove(filepath)
    if not ok then
      stop("can't remove file <%s>: %s", filepath, msg)
    end
  end
end

--- ���������� ��������� ��� �����.
function tmpfname()
  local fname = os.tmpname()
  if os_type == 'windows' then
    fname = '.' .. fname
  end
  return fname
end

--
-- ��������� ���� ��������.
--

-- ������� ������ ���� ��� ����.
local log_fnm = cwd() .. '/temp/install_lwdg.log'
mkfile(log_fnm)

--- ���������� ��������� � ���.
function log( what )
  local f = assert(io.open(log_fnm, 'a'))
  f:write(what .. '\n')
  f:close()
end

--- ������� ��������� �� ����� � ���������� ��� � ���.
function msg( what )
  io.write(what .. '\n')
  log('# ' .. what)
end

--
-- ��������� ������.
--

--- ��������� ���������� ������� � ������� ��������� �� ������ �� �����.
function stop( ... )
  local msg = string.format(...)

  log('error: ', msg)

  io.write('\n')
  io.write('ERROR: ', msg, '\n')

  io.write('\n')
  io.write('Some sort of shit happens, installation was interrupted.\n')
  os.exit(1)
end

--- ��������� ������� ���������.
function test_exist( prog, msg )
  local args = os_type == 'windows'
                 and '--version >nul 2>nul'
                 or  '--version >/dev/null 2>/dev/null'
  if execf_unp(prog, args) ~= success_code then
    stop("can't run <%s>: %s", prog, msg)
  end
end

--- ��������� ������ ���������.
-- ��������������, ��� ��������� ������� � �������.
function test_ver( prog, ver )
  local fn = tmpfname()
  local args = os_type == 'windows'
               and '--version >'
               or  '--version 2>/dev/null >'
  if execf_unp(prog, args .. fn) ~= success_code then
    stop("can't run <%s>", prog)
  end
  
  local file = assert(io.open(fn, 'r'))
  local pver = file:read('*line')
  file:close()
  rmfile(fn)

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

--
-- ������ � ������.
--

--- �������� �������� ����� \ �� ������ /, ����� �������� ������� ������ // ����� �� ��������� /.
function norm_path( path )
  path = path:gsub('\\', '/')
  while path:match('//') do
    path = path:gsub('//', '/')
  end
  return path
end

--- ��������� ������ path ��������� ����������� ";" (����� � �������).
-- 
-- ���������� �������, ��� ���� - ������������� ������, � �������� - �������� ������.
-- �.�. "foo/bar;xxx\baz" ����� ������� ��:
-- {
--    "foo/bar" = "foo/bar",
--    "xxx/baz" = "xxx\baz"
-- }
function split( path )
  local res = {}
  for p in path:gmatch('[^;]+') do
    res[norm_path(p)] = p
  end
  return res
end

--- �������� �� ������� ������ ��������� �� ��������� �������, ������� ��������� ������ � �������.
-- ������� �������� � ������� split().
-- �.�. �������:
-- {
--    "foo/bar" = "foo/bar",
--    "xxx/baz" = "xxx\baz"
-- }
-- ����� ������� � "foo/bar;xxx\baz".
function join( tbl )
  local res = ''
  for _, v in pairs(tbl) do
    if res == '' then
      res = v
    else
      res = res .. ';' .. v
    end
  end
  return res
end

-- ��������! ����� ��������������, ��� �� ��� ������ ����� �� �������� �������
-- ����������� �������� ���������� �������� ���������.
-- ��� ������������� �������� ������� �� ���������� install ����������� devenv.
function get_home_path()
  local cwd = norm_path(cwd())
  local cwd_tbl = {}

  for s in cwd:gmatch('[^/]+') do
    table.insert(cwd_tbl, s)
  end
  
  local home = table.concat(cwd_tbl, '/', 1, #cwd_tbl - 2)
  
  if os ~= 'windows' then
    home = '/' .. home
  end
  
  return home
end

function get_devenv_repo_path()
  local cwd = norm_path(cwd())
  local cwd_tbl = {}

  for s in cwd:gmatch('[^/]+') do
    table.insert(cwd_tbl, s)
  end
  
  local home = table.concat(cwd_tbl, '/', 1, #cwd_tbl - 1)
  
  if os ~= 'windows' then
    home = '/' .. home
  end
  
  return home
end

--
-- ���������� ������
--

--- �������������� ������ �������. � ������ windows �������� ������ ����� / �� �������� \.
local function norm_cmd_name( cmd )
  if os_type == 'windows' then
    return cmd:gsub('/', '\\')
  else
    return cmd
  end
end

--- ��������� ������� cmd � ���������� ������ ������� � ���.
function execf_unp( cmd, ... )
  local cmdl = norm_cmd_name(cmd) .. ' ' .. string.format(...)
  log(cmdl)
  return os.execute(cmdl)
end

--- ������ ����� ���������� ������� execf_unp().
-- ���� ��������� ������� �� �������, �� ��������� ������ �������.
function execf( cmd, ... )
  if execf_unp(cmd, ...) ~= success_code then
    stop("can't execute <%s>", string.format(...))
  end
end

function pipe( cmd )
  local file = assert(io.popen(cmd))
  local res = file:read('*all')
  file:close()
  return res
end

--- �������� ������� ���������� ������������ ����� ����������� � ��������� ������� cmd.
-- ����� �������� �������������, ��� �� ������� ���� ��������� ������ �����������.
function cdrun( path, cmd, ... )
  local sp = cwd()
  chdir('../' .. path)
  log('cd ' .. '~/' .. path)
  local res = execf_unp(cmd, ...)
  chdir(sp)
  log('cd ' .. sp)
  if res ~= success_code then
    stop("can't run <%s> in <%s>", cmd, path)
  end
end

--- ��������� ������� � path � ������� ������� cdrun() � ��������� ��������� ������ script �� Lua.
-- ���� script �� ������, �� �� ��������� ����������� make.lua �� ���������� ����.
function lua_make( path, script )
  local cwd = cwd()
  local std_lua
  
  script = script or 'make.lua'
  
  if (os_type == 'linux' or os_type == 'osx') then
    std_lua = 'lua'
  else
    std_lua = cwd .. "/temp/standalone-lua.exe"
  end
  
  local to_null = os_type == 'windows' and ' >nul' or ' >/dev/null'
  
  cdrun(path, std_lua, script .. to_null)
end

local home = get_home_path()

function llake_make( path, name, dst )
  local arguments
  
  if os_type == 'windows' then
    arguments = '-s make build.llk 2>nul 1>nul'
  else
    arguments = 'make build.llk 2>/dev/null 1>/dev/null'
  end
  
  cdrun(path, 'llake', arguments)
  
  local src = '../' .. path .. '/' .. name
  local dst = home .. '/' .. dst
  execf("mv", "%s %s", src, dst)
end

--
-- ���������� win32
--

--- ��� ������� ��������� ������, ����������� ��� assoc/ftype
-- ��� ������� ������������ ����� ��� ������ ��-��� ������������� ��������.
function reg_ext( ext, typeid, act )
  -- damned windows understand '/' everywhere but here
  act = act:gsub('/', '\\')

  -- delete /f = force
  execf_unp('REG', 'DELETE HKCU\\Software\\Classes\\%s /f 2>nul 1>nul', ext)
  execf_unp('REG', 'DELETE HKCU\\Software\\Classes\\%s /f 2>nul 1>nul', typeid)
  -- add /ve = default parameter, /d = value
  execf('REG', 'ADD HKCU\\Software\\Classes\\%s /ve /d %s 2>nul 1>nul', ext, typeid)
  execf('REG', 'ADD HKCU\\Software\\Classes\\%s\\Shell\\Open\\command /ve /d "%s \\"%%1\\" %%*" 2>nul 1>nul', typeid, act)
  istools.win32_update_config()
end

--
-- ������ � ����������� ���������
--

function get_env( var )
  local val = os.getenv(var)
  if not val then
    stop("can't find variable <%s> in current environment", var)
  end
  return val
end

function get_user_path()
  return istools.win32_get_user_path()
end

function set_user_env( var, val )
  -- delete /f = force delete, /v = parameter
  execf_unp('REG', 'DELETE HKCU\\Environment /v %s /f 2>nul 1>nul', var)
  -- add /v = parameter, /d = value
  execf('REG', 'ADD HKCU\\Environment /v %s /d "%s" 2>nul 1>nul', var, val)
  istools.win32_update_config()
end

function del_user_env( var )
  -- delete /f = force delete, /v = parameter
  execf_unp('REG', 'DELETE HKCU\\Environment /v %s /f 2>nul 1>nul', var)
  istools.win32_update_config()
end

function set_proc_env( var, val )
  istools.win32_set_process_env(var, val)
end

function set_env( var, val )
  set_user_env(var, val)
  set_proc_env(var, val)
end

function del_env( var )
  del_user_env(var)
  set_proc_env(var, "")
end

--
-- ���� ��������� ������������ ������������
--

local cfg = nil

function get_cfg( var )
  if not cfg then
    local cfg_file = loadfile('user.cfg')
    if not cfg_file then
      stop("can't obtain user configuration, please check file <user.cfg>")
    end
    cfg = cfg_file()
  end

  if not cfg[var] then
    stop("can't find parameter <%s> in user configuration, please check file <user.cfg>", var)
  end
  return cfg[var]
end

function get_cfg_path( var ) return norm_path(get_cfg(var)) end
