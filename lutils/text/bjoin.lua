--[[
  Преобразование текста, состоящего из абзацев, начинающихся с отступов,
  в текст, в котором каждый абзац представляет собой одну длинную строку
--]]

if #arg ~= 1 and #arg ~=2 then
  io.write('Usage: lua bjoin.lua filename [pref]\n')
  os.exit()
end

pref = arg[2] or ""

local line_buf = ""

function emit_buf( nbv )
  if #line_buf > 0 then
    io.write(pref .. line_buf .. "\n")
  end
  line_buf = nbv
end

io.input(arg[1])
for s in io.lines() do
  _, _, ss = s:find('^%s*(.*)%s*$')
  if s:sub(1, 1) == ' ' then
    emit_buf(ss)
  else
    line_buf = line_buf .. ' ' .. s
  end
end
