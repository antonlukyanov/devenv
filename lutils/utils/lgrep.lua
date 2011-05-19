--[[
  ѕоиск регул€рного выражени€ во всех файлах
  заданного поддерева, удовлетвор€ющих маске.
--]]

require "libwaki"
require "libdir"
require "libcmdl"

opts = cmdl.options()

if #arg ~= 2 and #arg ~= 3 then
  local use =
[[
Usage: lua lgrep.lua [-e] pattern mask [path]
  -e : process escaped symbols in pattern
]]
  io.write(use)
  os.exit()
end

patt = arg[1]
mask = arg[2]
path = arg[3] or '.'

local function expand_escaped( str )
  -- экранировать кавычки, кои есть внутри строки
  local s = string.gsub(str, '"', '\\"')
  -- подставить экранированные символы внутри строки (\t etc)
  s =  loadstring('return "' .. s .. '"')()
  return s
end

if opts['-e'] then
  patt = expand_escaped(patt)
end

flist = dir.collect(path, function(fn, attr)
    return attr.mode == 'file' and fname.match(fn, mask)
  end
)

function grep( fpath, patt )
  local file = io.open(fpath, "rt")
  local ln = 0
  for s in file:lines() do
    ln = ln + 1
    if s:find(patt) then
      io.write(fpath, ":", ln, ": ", waki.recode(s, 'wa'), "\n")
    end
  end
  file:close()
end

for fn in pairs(flist) do
  grep(fn, patt)
end
