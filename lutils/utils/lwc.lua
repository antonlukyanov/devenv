--[[
  —читает суммарное число строк в файлах, расположенных в подкаталогах
  директории dir, удовлетвор€ющих файловой маске mask.
--]]

require "libdir"

if #arg ~= 1 and #arg ~= 2 then
  io.write('Usage: lua lwc.lua mask [path]\n')
  os.exit()
end

list = dir.collect(arg[2] or '.', function(fn, attr)
    return attr.mode == 'file' and fname.match(fn, arg[1])
  end
)

file_num = 0
line_num = 0

for fn in pairs(list) do
  file_num = file_num + 1
  for s in io.lines(fn) do
    line_num = line_num + 1
  end
end

io.write(line_num, " lines in ", file_num, " files found\n")
