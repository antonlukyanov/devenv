--[[
  Исправляет файлы формата PostScript под GSView 2.7
--]]

if #arg ~= 1 then
  io.write('Usage: lua psfixup.lua filename\n')
  os.exit()
end

do_print = true
io.input(arg[1])
for s in io.lines() do
  if s:find('^%%%%BeginPaperSize') then
    do_print = false
  elseif s:find('^%%%%EndPaperSize') then
    do_print = true
  else
    if do_print then
      io.write(s, '\n')
    end
  end
end

