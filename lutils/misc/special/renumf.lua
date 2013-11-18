--[[
  Перименование группы файлов
  Новое имя получается из префикса и номера
  Задаются префикс и стартовый номер
--]]

require "lfs"
require "libfname"

if #arg ~= 1 and #arg ~= 2 then
  io.write('Usage: lua renumf.lua pref [num]\n')
  os.exit()
end

pref = arg[1]
num = arg[2] or 1

for fn in lfs.dir(".") do
  if lfs.attributes(fn).mode == 'file' then
    fnt = fname.split(fn)
    nname = pref .. string.format("%04d", num)
    os.execute("ren " .. fn .. ' ' .. fname.merge(fnt.dir, nname, fnt.ext))
    -- print(fn, nfn)
    num = num + 1
  end
end
