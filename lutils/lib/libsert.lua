--[[
  Сериализация таблицы без поддержки циклических ссылок.
  В отличие от стандартной сериализации, здесь реализован
  вывод таблицы в человеко-читаемой форме.
--]]

local function indent( level )
  local tab_size = 2
  io.write(string.rep(' ', level * tab_size))
end

local function out_key( k )
  if type(k) == 'number' or type(k) == 'boolean' then
    io.write("[", k, "]")
  elseif type(k) == 'string' then
    if k:match('^[%_%a][%_%w]*$') then
      io.write(k)
    else
      io.write("[", string.format("%q", k), "]")
    end
  end
  io.write(" = ")
end

function serialize( t, level )
  if not level then level = 0 end
  if type(t) ~= 'table' then error("can't serialize a " .. type(t)) end

  indent(level)
  io.write("{\n")
  for k, v in pairs(t) do
    indent(level+1)
    out_key(k)
    if type(v) == "number" then
      io.write(v, ',\n')
    elseif type(v) == "boolean" then
      io.write(tostring(v), ',\n')
    elseif type(v) == "string" then
      io.write(string.format("%q", v), ',\n')
    elseif type(v) == 'table' then
      io.write('\n')
      serialize(v, level+1)
    else
      error("cannot serialize a " .. type(o))
    end
  end
  indent(level)
  if level == 0 then
    io.write("}\n")
  else
    io.write("},\n")
  end
end
