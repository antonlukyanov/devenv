--[[
  Заменяет все вхождения регулярного выражения re
  на строку, заданную в параметре repl во всех файлах
  заданного поддерева, удовлетворяющих маске.
--]]

require "libdir"
require "libcmdl"

opts = cmdl.options()

if #arg ~= 3 and #arg ~= 4 then
  local use =
[[
Usage: lua lsed.lua [-e] [-n] pattern replacement filemask [path]
  -e : process escaped symbols in pattern and replacement
  -n : process files line-by-line (whole file substitution by default)
]]
  io.write(use)
  os.exit()
end

pat = arg[1]
repl = arg[2]
mask = arg[3]
path = arg[4] or '.'

line_mode = false

local function expand_escaped( str )
  -- экранировать кавычки, кои есть внутри строки
  local s = string.gsub(str, '"', '\\"')
  -- подставить экранированные символы внутри строки (\n etc)
  s =  loadstring('return "' .. s .. '"')()
  return s
end

if opts['-e'] then
  pat = expand_escaped(pat)
  repl = expand_escaped(repl)
end

if opts['-n'] then
  line_mode = true
end

list = dir.collect(path, function(fn, attr)
    return attr.mode == 'file' and fname.match(fn, mask)
  end
)

-- замена построчно
function sed_lines( fn, pat, repl )
  local inf = io.open(fn, 'rt')
  local data = {}
  for s in inf:lines() do
    table.insert(data, s)
  end
  inf:close()

  local r = 0
  for i = 1, #data do
    local res, count = data[i]:gsub(pat, repl)
    if count > 0 then
      data[i] = res
    end
    r = r + count
  end

  -- Запись файла только если были замены.
  if r > 0 then
    local outf = io.open(fn, 'wt')
    for _, s in ipairs(data) do
      outf:write(s, '\n')
    end
    outf:close()
  end

  return r
end

-- замена во всем файле целиком
function sed_file( fn, pat, repl )
  local inf = io.open(fn, 'rt')
  local data = inf:read('*all')
  inf:close()

  local res, count = data:gsub(pat, repl)
  if count > 0 then
    local outf = io.open(fn, 'wt')
    outf:write(res)
    outf:close()
  end
  return count
end

function sed( fn, pat, repl )
  local r = 0
  if line_mode then
    r = sed_lines(fn, pat, repl)
  else
    r = sed_file(fn, pat, repl)
  end
  return r
end

changed_count = 0
files_count = 0
for fn in pairs(list) do
  local count = sed(fn, pat, repl)
  if count > 0 then changed_count = changed_count + 1 end
  files_count = files_count + 1
  io.stdout:write(fn, ' ', count, '\n')
end
io.stdout:write(string.format('Changed %d of %d files.\n', changed_count, files_count))
