--[[
  Сериализация таблицы без поддержки циклических ссылок.
  Используется внутренний текстовый формат представления.
--]]

--[[
  Описание формата:
    1. Представление таблицы начинается со строки '{' и заканчивается строкой '}'.
    2. Каждый элемент таблицы представляется ключевой строкой вида '[KV',
       где K и V - первые символы типа ключа и значения соответственно.
       Ключом могут быть число ('n'), булевское значение ('b') и строка ('s'),
       значением может быть также таблица ('t').
       Вслед за ключевой строкой идет строка, представляющая ключ
       и строка, представляющая значение.
       Если значение имеет табличный тип, то вслед за значением ключа
       идет обычное представление таблицы.
    3. Булевские значения представляются строками 'true' и 'false'.
       В строках сохраняются все печатные символы из набора ASCII-7 кроме символа '\'.
       Все остальные символы представлены в виде '\ddd', где 'ddd' - десятичный код символа.
--]]

-- serializer

local function quot_char( c )
  local b = c:byte()
  return (b > 32 and b < 127 and c ~= '\\') and c or string.format("\\%03d", b)
end

local function quot_str( s )
  return (s:gsub('.', quot_char))
end

local function get_type_char( v )
  local t = type(v)
  if t == "number" or t == "boolean" or t == "string" or t == "table" then
    return t:sub(1,1)
  else
    error('incorrect type of value: ' .. t)
  end
end

local function out_key( k, v, file )
  file:write('[', get_type_char(k), get_type_char(v), '\n')

  local kt = type(k)
  if kt == "number" then
    file:write(k, '\n')
  elseif kt == "boolean" then
    file:write(tostring(k), '\n')
  elseif kt == "string" then
    file:write(quot_str(k), '\n')
  else
    error("cannot serialize a " .. kt .. " as a key")
  end
end

function save_table( file, t )
  if file == nil then file = io.stdout end
  if type(t) ~= 'table' then error("can't serialize a " .. type(t)) end

  file:write('{\n')
  for k, v in pairs(t) do
    out_key(k, v, file)

    local vt = type(v)
    if vt == "number" then
      file:write(v, '\n')
    elseif vt == "boolean" then
      file:write(tostring(v), '\n')
    elseif vt == "string" then
      file:write(quot_str(v), '\n')
    elseif vt == 'table' then
      save_table(file, v)
    else
      error("cannot serialize a " .. type(v) .. " as a value")
    end
  end
  file:write('}\n')
end

-- deserializer

local line_num = 0
local function get_line( file )
  line_num = line_num + 1
  return file:read('*l')
end
local function ds_error( msg )
  error(msg .. ' at line ' .. tostring(line_num))
end

local function decode_key_str( kcode )
  if kcode:sub(1,1) ~= '[' or #kcode ~= 3 then
    ds_error('incorrect key string')
  end
  return kcode:sub(2,2), kcode:sub(3,3)
end

local function str2bool( str )
  if str:sub(1,4) == 'true' then
    return true
  elseif str:sub(1,5) == 'false' then
    return false
  else
    ds_error('incorrect boolean value')
  end
end

local function dequot_char( s )
  return string.char(tonumber(s))
end

local function dequot_str( s )
  return (s:gsub('\\(%d%d%d)', dequot_char))
end

function load_table( file )
  local res = {}

  if get_line(file) ~= '{' then
    ds_error('incorrect marker of table')
  end

  while true do
    local kcode = get_line(file)
    if kcode == '}' then break end
    local t1, t2 = decode_key_str(kcode)

    local kval
    local kstr = get_line(file)
    if t1 == 'n' then
      kval = tonumber(kstr)
    elseif t1 == 'b' then
      kval = str2bool(kstr)
    elseif t1 == 's' then
      kval = dequot_str(kstr)
    else
      ds_error('incorrect type of key')
    end

    local vval
    if t2 == 'n' then
      vval = tonumber(get_line(file))
    elseif t2 == 'b' then
      vval = str2bool(get_line(file))
    elseif t2 == 's' then
      vval = dequot_str(get_line(file))
    elseif t2 == 't' then
      vval = load_table(file)
    else
      ds_error('incorrect type of value')
    end

    res[kval] = vval
  end
  
  return res
end
