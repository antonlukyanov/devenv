--- Результат выполнения команды uname для определения используемой ОС.
local uname_val = string.lower(
    assert(io.popen('uname')):read('*l')
  )

--- Возвращает "имя" операционной системы.
-- 
-- Возвращает linux для Debian/Ubuntu, osx для Mac OSX, mingw для Windows с использованием MinGW.
local function get_os_type()
  if uname_val:match('linux') then
    return 'linux'
  elseif uname_val:match('darwin') then
    return 'osx'
  elseif uname_val:match('mingw') then
    return 'windows'
  else
    stop("unknown name of operating system")
  end
end

--- Возвращает значение для сравнения результата работы функции os.execute().
local function get_success_code()
  local code
  if os == 'mingw' then
    code = 0
  else
    code = true
  end
  return code
end

platform = {
  uname = uname_val,
  os_type = get_os_type(),
  get_os_type = get_os_type,
  get_success_code = get_success_code,
}

return platform
