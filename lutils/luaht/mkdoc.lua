--[[
  Рекурсивный обработчик lht-файлов.
--]]

require "libfname"
require "luaht"
require "lfs"

if #arg > 1 then
  io.stderr:write("usage: mkdoc [lht-file-short-name]\n")
  os.exit(1)
end
start_fn = arg[1] or 'readme.lht'

local todo_tbl = {}
local ready = {}

function prepare( fn )
  local fnt = fname.split(fn)
  return fname.merge((fnt.dir and fname.compact_path(fnt.dir)) or '', fnt.name, fnt.ext)
end

-- Здесь имя файла дополняется текущей директорий, что дает полное имя файла.
-- Это гарантирует отсутствие циклов при обходе графа ссылок.
table.insert(todo_tbl, prepare(lfs.currentdir() .. '/' .. start_fn))

while #todo_tbl > 0 do
  local fn = table.remove(todo_tbl)
  local new_todo = luaht.proc(fn)
  ready[fn] = true
  io.write(fn .. '\n')

  local base = fname.split(fn).dir or ''
  for _, v in ipairs(new_todo) do
    if fname.split(v).ext == '.lht' then
      local pfn = prepare(base .. v)
      if not ready[pfn] then
        table.insert(todo_tbl, pfn)
      end
    end
  end
end
