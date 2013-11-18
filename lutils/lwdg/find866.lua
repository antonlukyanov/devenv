--[[
  ѕоиск в исходниках русско€зычного текста в dos-кодировке
--]]

require "libwaki"
require "libdir"

mask = '#.cc;#.h;#.eh;#.lua;#.awk;#.pas;#.cmd;#.bat;#.txt'
path = '.'

local win, win_cap = {}, {}
for j = 192, 223 do win[j], win_cap[j] = true, true end
for j = 224, 255 do win[j] = true end
win[168], win_cap[168] = true, true
win[184] = true

local dos, dos_cap = {}, {}
for j = 128, 159 do dos[j], dos_cap[j] = true, true end
for j = 160, 239 do dos[j] = true end
dos[240], dos_cap[240] = true, true
dos[241] = true

function test( buf )
  local nt, nw, nwc, nd, ndc = 0, 0, 0, 0, 0
  local n_w_non_d = 0
  for j = 1, #buf do
    local chr = buf:byte(j)
    if chr > 127 then nt = nt + 1 end
    if win[chr] then nw = nw + 1 end
    if win_cap[chr] then nwc = nwc + 1 end
    if dos[chr] then nd = nd + 1 end
    if dos_cap[chr] then ndc = ndc + 1 end
    if win[chr] and not dos[chr] then n_w_non_d = n_w_non_d + 1 end
  end

  if nt ~= 0 then
    if nt > nw then return true end -- есть не-win-символы
    -- все символы совместимы с win-кодировкой
    if nd ~= 0 and n_w_non_d == 0 then return true end
    -- здесь потенциально могут считатьс€ подозрительными файлы,
    -- в которых использованы только символы из пересечени€ win и dos кодировок
  end

  return false
end

flist = dir.collect(path, function(fn, attr)
    return attr.mode == 'file' and fname.match(fn, mask)
  end
)

for fn in pairs(flist) do
  local file = io.open(fn, "rb")
  local buf = file:read('*all')
  if test(buf) then
    io.write(fn, '\n')
  end
  file:close()
end
