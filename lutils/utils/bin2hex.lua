--[[
  Преобразование двоичного файла в 16-ричный дамп
--]]

if #arg ~= 1 then
  io.write('Usage: lua bin2hex.lua file\n')
  os.exit()
end

file = assert(io.open(arg[1], "rb"))
data = file:read("*all")
file:close()

function print_str( s )
  for j = 1, #s do
    if s:byte(j) > 32 and s:byte(j) < 127 then
      io.write(s:sub(j, j))
    else
      io.write('.')
    end
  end
end

len = #data

io.write(string.rep('0', 8), ' | ')
for j = 1, len do
  io.write(string.format("%02X ", data:byte(j)))

  if math.fmod(j, 8) == 0 then
    io.write('| ')
  end

  if math.fmod(j, 16) == 0 then
    print_str(data:sub(j-15, j))
    io.write('\n')
    if j ~= len then
      io.write(string.format("%08X | ", j))
    end
  end
end

-- last line padding
last = math.fmod(len, 16)
if last ~= 0 then
  if last < 8 then
    for j = 1, 8 - last do
      io.write('   ')
    end
    io.write('| ')
    for j = 1, 8 do
      io.write('   ')
    end
    io.write('| ')
  else
    for j = 1, 16 - last do
      io.write('   ')
    end
    io.write('| ')
  end
  print_str(data:sub(len-last+1, len))
  io.write('\n')
end
