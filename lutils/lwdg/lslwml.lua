--[[
  Вывод сводной информации по файлам библиотеки lwml
--]]

require "libdir"

if #arg ~= 1 and #arg ~= 2 then
  io.write('Usage: lua lslwml.lua action [path]\n')
  io.write('Actions: create, remove\n')
  os.exit()
end
action = arg[1]
path = arg[2] or '.'

local hdr_num = 0
hlist = dir.collect(path, function(fn, attr)
    hdr_num = hdr_num + 1
    return attr.mode == 'file' and fname.match(fn, "#.h")
  end
)
alllist = dir.collect(path, function(fn, attr)
    return attr.mode == 'file' and fname.match(fn, "#.h;#.cc")
  end
)

--functions

function is_doc( fpath )
  flag = false
  local file = io.open(fpath, "rt")
  for s in file:lines() do
    if s:find("lwml, %(c%) ltwood") then
      flag = true
      break
    end
  end
  file:close(file)
  return flag
end

function grep( fpath, mask, lfile )
  local file = io.open(fpath, "rt")
  local ln = 0
  for s in file:lines() do
    ln = ln + 1
    if s:find(mask) then
      lfile:write(fpath, ":", ln, ": ", s, "\n")
    end
  end
  file:close()
end

function create()
  -- documentation
  nd_num = 0
  ndfile = io.open("no_doc.lst", "wt")
  for fn in pairs(hlist) do
    if not is_doc(fn) then
      ndfile:write(fn, "\n")
      nd_num = nd_num + 1
    end
  end
  ndfile:close()
  io.write('see file <no_doc.lst>\n')
  io.write(hdr_num, " headers found\n")
  io.write(nd_num, " undocumented headers found\n")

  -- hacks
  hacks = io.open("hacks.lst", "wt")
  mask = "%/%/%!%!"
  for fn in pairs(alllist) do
    grep(fn, mask, hacks)
  end
  hacks:close()
  io.write('see file <hacks.lst>\n')

  -- defines
  defs = io.open("defs.lst", "wt")
  mask = "%#define%s+[^%_]"
  for fn in pairs(alllist) do
    grep(fn, mask, defs)
  end
  defs:close()
  io.write('see file <defs.lst>\n')

  -- modules
  mods = io.open("modules.i", "wt")
  for fn in pairs(hlist) do
    sfn = fn:gsub(".*%/", "")
    mods:write('#include "', sfn, '"\n')
  end
  mods:write("// ", hdr_num, " files found\n")
  mods:close()
  io.write('see file <modules.i>\n')
end

function remove()
  os.remove(path .. '/' .. "no_doc.lst")
  os.remove(path .. '/' .. "hacks.lst")
  os.remove(path .. '/' .. "defs.lst")
  os.remove(path .. '/' .. "modules.i")
end

if action == 'create' then
  create()
elseif action == 'remove' then
  remove()
else
  error"unknown action, may be 'create' or 'remove'"
end
