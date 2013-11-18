--[[
  ѕечатает список файлов из заданной директории,
  удовлетвор€ющих заданной маске
--]]

require "libdir"

if #arg ~= 1 and #arg ~= 2 then
  io.write('Usage: lua ftwalk.lua mask [path]\n')
  os.exit()
end

flist = dir.collect(
  arg[2] or '.', 
  function(fn, attr) return attr.mode == 'file' and fname.match(fn, arg[1]) end 
)

for fn in pairs(flist) do
  io.write(fn, "\n")
end
