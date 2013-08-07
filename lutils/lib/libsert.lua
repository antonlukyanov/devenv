--[[
  Сериализация таблицы без поддержки циклических ссылок.
  В отличие от стандартной сериализации, здесь реализован
  вывод таблицы в человеко-читаемой форме.
--]]

local function indent( level, file )
  local tab_size = 2
  file:write(string.rep(' ', level * tab_size))
end

local function out_key( k, file )
  local kt = type(k)
  if kt == 'number' or kt == 'boolean' then
    file:write("[", k, "]")
  elseif kt == 'string' then
    if k:match('^[%_%a][%_%w]*$') then
      file:write(k)
    else
      file:write("[", string.format("%q", k), "]")
    end
  else
    error("cannot serialize a " .. kt .. " as a key")
  end
  file:write(" = ")
end

function serialize( t, file, level )
  if file == nil then
    file = io.stdout
  end
  if not level then level = 0 end
  if type(t) ~= 'table' then error("can't serialize a " .. type(t)) end

  indent(level, file)
  file:write("{\n")
  for k, v in pairs(t) do
    indent(level+1, file)
    out_key(k, file)
    local vt = type(v)
    if vt == "number" then
      file:write(v, ',\n')
    elseif vt == "boolean" then
      file:write(tostring(v), ',\n')
    elseif vt == "string" then
      file:write(string.format("%q", v), ',\n')
    elseif vt == 'table' then
      file:write('\n')
      serialize(v, file, level+1)
    else
      error("cannot serialize a " .. vt .. " as a value")
    end
  end
  indent(level, file)
  if level == 0 then
    file:write("}\n")
  else
    file:write("},\n")
  end
end
