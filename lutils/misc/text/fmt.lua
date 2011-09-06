--[[
  Форматирование текста в строки из ~WIDTH символов.
  Длинные строки усекаются до заданной длины, короткие
  сливаются, идущие подряд пробелы удаляются.
  Разделителями абзацев считаются пустые строки.
--]]

if #arg ~= 1 and #arg ~= 2 then
  io.write('Usage: lua fmt.lua filename [width]\n')
  os.exit()
end

io.input(arg[1])
width = tonumber(arg[2] or 78)

line_buf = ""

function prset( v )
  if #line_buf > 0 then
    io.write(line_buf, "\n")
    line_buf = v
  end
end

function add( w )
  if #line_buf + 1 + #w > width then
    prset(w)
  else
    if #line_buf == 0 then
      line_buf = w
    else
      line_buf = line_buf .. " " .. w
    end
  end
end

for s in io.lines() do
  _, _, ss = s:find('^%s*(.*)%s*$')
  if #ss == 0 then
    prset("")
    io.write("\n")
  else
    for w in ss:gmatch('%S+') do
      add(w)
    end
  end
end
prset("")
