--[[
  Проверка поддерева файловой системы на наличие файлов-дубликатов
--]]

require "md5"
require "libdir"
require "libfname"

if #arg ~= 1 and #arg ~= 2 then
  io.write('Usage: lua dupl.lua mask [path]\n')
  os.exit()
end

local fnum = 0
list = dir.collect(
  arg[2] or '.', 
  function(fn, attr) 
    fnum = fnum + 1 
    return attr.mode == 'file' and fname.match(fn, arg[1]) 
  end 
)
io.stderr:write(fnum, ' files found\n')

filelist = {}
k = 0
for fn in pairs(list) do
  k = k + 1
  local file = io.open(fn, "rb")
  local buf = file:read('*all')
  file:close()
  if buf ~= nil then
    local sum = md5.sum(buf)
    buf = nil

    if filelist[sum] then
      io.write(fn, ' --> ', filelist[sum], '\n')
    else
      filelist[sum] = fn
    end
  end

  if math.fmod(k, 100) == 0 then
    io.stderr:write(k, ' ')
    io.stderr:flush()
  end
end
io.close()
