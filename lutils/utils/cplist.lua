--[[
  Копирует в текущую директорию все файлы, полные имена
  которых перечислены в строках заданного файла-аргумента.
--]]

if #arg ~= 1 then
  io.write('Usage: lua cplist.lua filename\n')
  os.exit()
end

function cp( fn )
  os.execute('copy "' .. fn .. '" >nul')
end

fn = arg[1]
for nm in io.lines(fn) do
  cp(nm)
end
