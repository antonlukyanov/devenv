--[[
  Поиск файла по набору ключевых слов.
  Ключевые слова ищутся по отдельности и число вхождений
  интерпретируется как релевантность файла.
  Поиск ключевых слов производится в имени файла и его описании.
--]]

require "libwaki"
require "libdir"
require "libfname"

if #arg ~= 1 and #arg ~= 2 then
  io.write('Usage: lua lsearch.lua keywords [path]\n')
  os.exit()
end

keywords = arg[1]
path = arg[2] or '.'
mask = "#.#"

kwlist = {}
for kw in keywords:gmatch('%S+') do
  table.insert(kwlist, kw)
end

list = dir.collect(path, function(fn, attr)
    return fname.match(fn, mask)
  end
)

function up( s ) return waki.upper(s, 'w') end

function calc_rel( txt )
  local rel = 0
  for _, kw in ipairs(kwlist) do
    if up(txt):match(up(kw)) then
      rel = rel + 1
    end
  end
  return rel
end

res = {}
name_rel, desc_rel = 0, 0

function add_rec( fn, rel )
  if rel == 0 then return end
  local idx = res[up(fn)]
  if idx then
    res[idx].rel = res[idx].rel + rel
  else
    table.insert(res, { fn = fn, rel = rel })
    res[up(fn)] = #res
  end
end

function parse_descr( dfn )
  local path = fname.split(dfn).dir
  for s in io.lines(dfn) do
    local name, desc
    if s:match('^%"') then
      name, desc = s:match('^%"(.*)%"%s+(.*)$')
    else
      name, desc = s:match('^(%S*)%s+(.*)$')
    end
    local rel = calc_rel(waki.recode(desc, 'aw'))
    desc_rel = desc_rel + rel
    add_rec(path .. name, rel)
  end
end

for fn in pairs(list) do
  local fnt = fname.split(fn)
  if up((fnt.name or '') .. (fnt.ext or '')) == up('descript.ion') then
    parse_descr(fn)
  end
  if fn ~= '.' then
    local rel = calc_rel(fnt.name or fnt.ext)
    add_rec(fn, rel)
    name_rel = name_rel + rel
  end
end

table.sort(res, function(a, b) return a.rel > b.rel end)

function wa( s ) return waki.recode(s, 'wa') end

for j = 1, #res do
  io.write(res[j].rel, ': ', wa(res[j].fn), '\n')
end

io.write('::: rel_name=', name_rel, ' rel_desc=', desc_rel, '\n')
