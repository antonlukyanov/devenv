--[[
  Формирует список файлов текущего поддерева, содержащих тестовые функции.
  Использует соглашения о юнит-тестах, принятые в lwml и описанные
  в комментариях файла 'utils/utest.h'.
--]]

require "libdir"

if #arg ~= 1 and #arg ~= 2 then
  io.write('Usage: lua mkutest.lua action [path]\n')
  io.write('Actions: create, remove\n')
  os.exit()
end
action = arg[1]
dir = arg[2] or '.'

function proc_file( fpath, fname )
  local file = io.open(fpath, "rt")
  for s in file:lines() do
    res, _, nm = s:find('^%s*bool%s+(utest_.+)%(')
    if res then
      func_num = func_num + 1
      tft:write('  {', nm, ', "', nm, '()", "', fname, '"},\n')
    end
  end
  file:close()
end

function create()
  tft = io.open("tft.i", "wt")   -- test functions table
  thl = io.open("thl.i", "wt")   -- test headers list

  list = dir.collect(dir, function(fn, attr)
      return attr.mode == 'file' and fname.match(fn, "*.t")
    end
  )

  file_num = 0
  func_num = 0

  tft:write("// Test function table\n")
  tft:write("// No hands, automatically generated!\n\n")
  thl:write("// Test header list\n")
  thl:write("// No hands, automatically generated!\n\n")

  for fpath in pairs(list) do
    file_num = file_num + 1
    fname = fpath:gsub(".*%/", "")
    thl:write('#include "', fname, '" // ', fpath)
    proc_file(fpath, fname)
  end

  io.write(file_num, " test files found\n")
  io.write(func_num, " test functions found\n")
end

function remove()
  os.remove(dir .. '/' .. "tft.i")
  os.remove(dir .. '/' .. "thl.i")
end

if action == 'create' then
  create()
elseif action == 'remove' then
  remove()
else
  error"unknown action, may be 'create' or 'remove'"
end
