--[[
  Библиотека операций с именами файлов
--]]

require "libwaki"

-- Разбирает полное имя файла на путь, имя и расширение.
-- Возвращает таблицу с полями dir, name и ext.
-- Точка включается в расширение.
-- Путь всегда завершается слэшем.
-- Работает как с прямым, так и с обратным слэшем.
-- Любой элемент может отсутствовать, в этом случае
-- на его месте возвращается nil.
local function fnsplit( path )
  local _, a, dir = path:find("^(.*[/\\])")
  a = a or 0
  local b, _, ext = path:find("(%.[^%./\\]*)$")
  b = b or 0
  local name = path:sub(a+1, b-1)
  name = ((name~="") and name) or nil
  return { dir = dir, name = name, ext = ext }
end

-- Собирает полное имя файла из таблицы t, содержащей поля dir, name и ext
-- или из переданных по отдельности пути, имени и расширения.
-- После поля dir добавляется слэш.
-- Могут отсутствовать некоторые из перечисленных полей или аргументов.
local function fnmerge( a, b, c )
  local function correct_dir( dir )
    if dir == nil or dir == '' then
      return ''
    end
    local c = string.sub(dir, -1)
    if c == '/' or c == '\\' then
      return dir
    end
    return dir .. '/'
  end
  if type(a) == "table" then
    return correct_dir(a.dir) .. (a.name or '') .. (a.ext or '')
  else
    return correct_dir(a) .. (b or '') .. (c or '')
  end
end

-- заменяет обратные слэши на прямые и добавляет отсутствующий слэш в конец
local function norm_path( path, case_sens )
  path = path:gsub('\\', '/')
  if path:sub(-1) ~= '/' then
    path = path .. '/'
  end
  return (case_sens and path) or waki.lower(path, 'win')
end

-- компактификация пути
-- удаляет из пути элементы вида '/./', '/../', '//'
-- заменяет обратные слэши на прямые
-- добавляет отсутствующий слэш в конец
function compact_path( path )
  local path = norm_path(path)

  local tbl = {}
  local is_root = false

  -- специфично обрабатываем слэш в первой позиции
  if path:sub(1,1) == '/' then
    is_root = true
    path = path:sub(2,-1)
  end

  while true do
    local elem, tail = path:match('([^/]*)(.*)')

    if elem == '.' or elem == '' then
    elseif elem == '..' then
      if tbl[#tbl] ~= '..' and #tbl > 0 then
        table.remove(tbl)
      else
        table.insert(tbl, elem)
      end
    else
      table.insert(tbl, elem)
    end

    if tail:sub(1,1) == '/' then
      tail = tail:sub(2,-1)
    end
    if tail == '' then
      break
    end
    path = tail
  end

  local tcc = (is_root and '/' or '') .. table.concat(tbl, '/')
  return tcc .. (#tbl > 0 and '/' or '')
end

-- Сопоставление имени файла fn с файловой маской re.
--[[
  Имитирует работу файловых масок, используя регулярные выражения.
  Файловая маска представляет собой подмножество файловых масок Posix
  (исключены множества символов).

  Отличия:
    1. Обрабатывает список файловых масок, разделенных символом ';' или ','.
    2. Сравнение производится без учета регистра символов
       (при приведении регистра используется кодировка OEM).
    3. Метасимвол '*' заменен на '#', метасимвол '?' -- на '@'.
       Цель замены -- избавиться от интерференции с метасимволами командного
       процессора при задании файловой маски в командной строке без кавычек.
    4. По сравнению с соглашениями DOS/Win здесь допускается присутствие
       в регулярном выражении нескольких символов '#'.

  Примеры:
    '#.#'     все файлы
    '#'       все файлы с пустым расширением
    '#.'      то же самое
    '.#'      все файлы с пустым именем
--]]

local function conv_regexp( re )
  re = re:gsub('(%W)', '%%%1')  -- экранирование метасимволов
  re = re:gsub('%%%#', '.*')  -- замена '#' на '.*'
  re = re:gsub('%%%@', '.?')  -- замена '@' на '.?'
  return '^' .. re .. '$'
end

local function fnmatch( fn, rel )
  fn = waki.lower(fn, 'win')
  rel = waki.lower(rel, 'win')
  fn_s = fnsplit(fn)
  fn_s.name = fn_s.name or ''
  fn_s.ext = fn_s.ext or '.'       -- пустое расширение даст теперь '.'
  for re in rel:gmatch('[^%;%,]+') do
    re_s = fnsplit(re)
    re_s.name = conv_regexp(re_s.name or '')
    re_s.ext = conv_regexp(re_s.ext or '.')  -- пустая маска расширения даст '.'
    if (string.find(fn_s.name, re_s.name)) == 1 and (string.find(fn_s.ext, re_s.ext)) == 1 then
      return true
    end
  end
  return false
end

fname = {
  split = fnsplit,
  merge = fnmerge,
  norm_path = norm_path,
  compact_path = compact_path,
  match = fnmatch,
}
return fname
