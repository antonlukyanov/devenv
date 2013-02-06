-- installation support tools

-- обработка ошибок

function stop( ... )
  local msg = string.format(...)
  io.write('\n')
  io.write('error: ', msg, '\n')

  io.write('\n')
  io.write('something is wrong, installation was interrupted, press <Enter>\n')
  io.read('*l')
  os.exit(1)
end

-- работа с путями

function norm_path( path )
  path = path:gsub('\\', '/'):lower()
  while path:match('//') do
    path = path:gsub('//', '/')
  end
  return path
end

function split( path )
  local res = {}
  for p in path:gmatch('[^%;]+') do
    res[norm_path(p)] = p
  end
  return res
end

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

function calc_home()
  local cwd = norm_path(istools.cwd())
  local cwd_tbl = {}
  for s in cwd:gmatch('[^%/]+') do
    table.insert(cwd_tbl, s)
  end
  return table.concat(cwd_tbl, '/', 1, #cwd_tbl - 2)
end

-- поддержка лога операций

local log_fnm = istools.cwd() .. '/temp/install_lwdg.log'
assert(io.open(log_fnm, 'wt')):close()

function log( what )
  local f = assert(io.open(log_fnm, 'at'))
  f:write(what .. '\n')
  f:close()
end

function msg( what )
  io.write(what .. '\n')
  log('# ' .. what)
end

function exec( what )
  log(what)
  return os.execute(what)
end

-- файловая система

function is_file( nm )
  local file = io.open(nm, 'rb')
  local res = (file ~= nil)
  if file then
    file:close()
  end
  return res
end

-- выполнение команд

function execf_unp( ... )
  return exec(string.format(...))
end

function execf( ... )
  if execf_unp(...) ~= 0 then
    stop("can't execute <%s>", string.format(...))
  end
end

function cdrun(path, command)
  local sp = istools.cwd()
  istools.chdir('../' .. path)
  log('cd ' .. '../' .. path)
  local res = exec(command)
  istools.chdir(sp)
  log('cd ' .. norm_path(sp))
  if res ~= 0 then
    stop("can't run <%s> at <%s>", command, path)
  end
end

function lua_make( path, script )
  local cwd = istools.cwd()
  std_lua = cwd .. "/temp/standalone-lua.exe"
  script = script or 'make.lua'
  cdrun(path, std_lua .. ' ' .. script .. ' >nul')
end

-- ассоциации win32

-- эта функция выполняет задачи, недоступные для assoc/ftype -- она успешно
-- регистрирует новый тип файлов из-под ограниченного эккаунта
function reg_ext( ext, typeid, act )
  -- damned windows understand '/' everywhere but here
  act = act:gsub('/', '\\')

  -- delete /f = force
  execf_unp('REG DELETE HKCU\\Software\\Classes\\%s /f 2>nul 1>nul', ext)
  execf_unp('REG DELETE HKCU\\Software\\Classes\\%s /f 2>nul 1>nul', typeid)
  -- add /ve = default parameter, /d = value
  execf('REG ADD HKCU\\Software\\Classes\\%s /ve /d %s 2>nul 1>nul', ext, typeid)
  execf('REG ADD HKCU\\Software\\Classes\\%s\\Shell\\Open\\command /ve /d "%s \\"%%1\\" %%*" 2>nul 1>nul', typeid, act)
  istools.win32_update_config()
end

-- работа с переменными окружения

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
  execf_unp('REG DELETE HKCU\\Environment /v %s /f 2>nul 1>nul', var)
  -- add /v = parameter, /d = value
  execf('REG ADD HKCU\\Environment /v %s /d "%s" 2>nul 1>nul', var, val)
  istools.win32_update_config()
end

function del_user_env( var )
  -- delete /f = force delete, /v = parameter
  execf_unp('REG DELETE HKCU\\Environment /v %s /f 2>nul 1>nul', var)
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

-- файл локальной конфигурации пользователя

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
    stop('cant find parameter <%s> in user configuration, please check file <user.cfg>', var)
  end
  return cfg[var]
end

function get_cfg_path( var ) return norm_path(get_cfg(var)) end
