--[[
  Строит гистограмму для вещественных чисел, извлекаемых из файла.
  Результаты выводятся в виде скрипта программы GNUPlot.
--]]

function minmax( d )
  min, max = d[1], d[1]
  for j = 2, #d do
    if d[j] > max then max = d[j] end
    if d[j] < min then min = d[j] end
  end
  return min, max
end

function val2idx( x, ax, bx, len )
  local idx = math.floor(len * (x - ax) / (bx - ax))
  return ((idx == len) and len) or idx + 1
end

function idx2val( idx, ax, bx, len )
  local st = ( bx - ax ) / len
  return ax + (idx-1) * st, ax + idx * st, ax + (idx-0.5) * st
end

-- main

if #arg ~= 1 and #arg ~= 2 then
  io.stderr:write('Usage: lua hist.lua filename [num]\n')
  os.exit()
end

num = (arg[2] and tonumber(arg[2])) or 10
io.stderr:write('hist_len='..num..'\n')

file = io.open(arg[1], 'rt')
idx = 0
data = {}
sum = 0.0
while true do
  local x = file:read('*number')
  if not x then break end
  idx = idx + 1
  data[idx] = x
  sum = sum + x
end
io.stderr:write('data_len='..idx..'\n')
io.stderr:write('mid='..sum/idx..'\n')

min, max = minmax(data)
io.stderr:write('min='..min..'\n')
io.stderr:write('max='..max..'\n')

hist = {}
for j = 1, num do hist[j] = 0 end

for j = 1, #data do
  local idx = val2idx(data[j], min, max, num)
  hist[idx] = hist[idx] + 1
end

io.write('set grid\n')
io.write('unset key\n')
io.write('set xrange [', min, ':', max, ']\n')
io.write('plot "-" with linespoints\n')

for j = 1, #hist do
  local va, vb, vc = idx2val(j, min, max, num)
  io.write(vc, ' ', hist[j], '\n')
end
io.write('e\n')
