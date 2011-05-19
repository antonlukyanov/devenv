--[[
  Проверка дампа памяти на утечки
--]]

if #arg ~= 1 then
  io.write('Usage: lua memleak.lua memdump\n')
  os.exit()
end

tot = 0
line_num = 0
tbl = {}

function proc_alloc( n, p, sz )
  if tbl[p] then
    io.write(line_num, ': alloc#', n, ' returns used memory - strange error\n')
  end
  tbl[p] = { size = sz, where = "alloc#" .. n }
  tot = tot + sz
end

function proc_dealloc( n, p )
  if tonumber(p) ~= 0 then
    if tbl[p] == nil then
      io.write(line_num, ': free#', n, ' for unknown memory block\n')
    else
      sz = tbl[p].size
      tbl[p] = nil
      tot = tot - sz
    end
  end
end

function proc_realloc( n, p1, p2, sz )
  if tonumber(p1) ~= 0 then
    if tbl[p1] == nil then
      io.write(line_num, ': realloc#', n, ' for unknown memory block\n')
    else
      old_sz = tbl[p1].size
      tbl[p1] = nil
      tot = tot - old_sz
    end
  end
  if tbl[p2] then
    io.write(line_num, ': realloc#', n, ' returns used memory - strange error\n')
  end
  tbl[p2] = { size = sz, where = "realloc#" .. n }
  tot = tot + sz
end

file = io.open(arg[1], "rt")
for s in file:lines() do
  line_num = line_num + 1
  _, _, action, counter, ptr, add1, add2 = s:find('(%S+) (%S+) (%S+) (%S+) (%S+)')

  if action == "+" then
    size = add1
    proc_alloc(counter, ptr, size)
  elseif action == "-" then
    proc_dealloc(counter, ptr)
  elseif action == "*" then
    new_ptr = add1
    size = add2
    proc_realloc(counter, ptr, new_ptr, size);
  else
    io.write(line_num, ": incorrect action in line\n")
  end
end
file:close()

if tot == 0 then
  io.write("no errors\n")
else
  io.write("errors: ", tot, " bytes\n")
end
for p, v in pairs(tbl) do
  io.write(p, " ", v.size, " ", v.where, "\n")
end
