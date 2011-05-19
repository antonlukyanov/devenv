--[[
  Преобразование 16-ричного дампа в двоичный файл.
  Формат должен соответствовать формату вывода программы bin2hex.lua.
--]]

if #arg ~= 2 then
  io.write('Usage: lua hex2bin.lua dump file\n')
  os.exit()
end

file = assert(io.open(arg[2], "wb"))

function ord( s, n )
  local ch = s:byte(n)
  if string.byte('0') <= ch and ch <= string.byte('9') then
    return ch - string.byte('0')
  else
    return ch - string.byte('A') + 10
  end
end

function outstr( s )
  for ns in s:gmatch('%S+') do
    local num = ord(ns, 1) * 16 + ord(ns, 2)
    -- print(ns, string.format("%x", num))
    file:write(string.char(num))
  end
end

for s in io.lines(arg[1]) do
  _, _, s1, s2 = s:find('^%x+ |([%s%x]+)|([%s%x]+)|.*$')
  outstr(s1)
  outstr(s2)
end

file:close()
