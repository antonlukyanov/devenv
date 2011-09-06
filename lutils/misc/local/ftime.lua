--[[
  Печатает список файлов из заданной директории,
  в порядке возрастания возраста последней модификации.
--]]

require "libdir"
require "librexp"

if #arg < 2 then
  io.write('Usage: lua ftime.lua num path [exclude...]\n')
  os.exit()
end

excl = {}
for j = 3, #arg do
  table.insert(excl, rexp.qsearch(arg[j]))
end

function is_good( fn )
  for _, re in ipairs(excl) do
    if fn:match(re) then
      return false
    end
  end
  return true
end

time = os.time()
num = tonumber(arg[1])
path = arg[2] or '.'
flist = dir.collect(path, function(fn, attr) return attr.mode == 'file' and )

fl = {}
for fn, attr in pairs(flist) do
  if not attr.modification then
    io.stderr:write("can't get mtime for <", fn, '>\n')
  end
  if is_good(fn) then
    table.insert(fl, { fn = fn, tm = time - attr.modification})
  end
end

table.sort(fl, function(a, b) return a.tm < b.tm end)

function extract( num, div )
  local res = math.floor(num / div)
  if res < 0 then
    res = 0
  end
  local new = num - div * res
  return res, new
end

function ctime( tm )
  local lm = 60
  local lh = 60 * lm
  local ld = 24 * lh
  local lw = 7 * ld

  local nw, nd, nh, nm, ns
  nw, tm = extract(tm, lw)
  nd, tm = extract(tm, ld)
  nh, tm = extract(tm, lh)
  nm, tm = extract(tm, lm)
  ns = math.floor(tm)

  if nw ~= 0 then 
    return nw .. ' w ' .. nd .. ' d'
  elseif nd ~= 0 then 
    return nd .. ' d ' .. nh .. ' h'
  elseif nh ~= 0 then 
    return nh .. ' h ' .. nm .. ' m'
  elseif nm ~= 0 then 
    return nm .. ' m ' .. ns .. ' s'
  else
    return ns .. ' s'
  end
end

if num <= 0 or num > #fl then
  num = #fl
end

for j = 1, num do
  tm = ctime(fl[j].tm)
  io.write(tm, string.rep(' ', 20-#tm), fl[j].fn, '\n')
end
