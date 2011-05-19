--[[
  Копирование всех неверсионированных файлов из рабочей копии
  в новую директорию с сохранением структуры дерева.
--]]

require "libcmdl"
require "libfname"
require "libdir"
require "lfs"

-- завершение по ошибке
function alert( msg )
  io.stderr:write(string.format('error: %s\n', msg))
  os.exit(1)
end

-- command line

opts = cmdl.options()
do_move = false
if opts['-m'] then
  do_move = true
end
do_proc_empty = false
if opts['-e'] then
  do_proc_empty = true
end

if #arg ~= 2 then
  local use =
[[
Usage: lua cpunver.lua wc-path backup-path
  -m : move files to backup
  -e : copy empty directories
]]
  io.write(use)
  os.exit()
end

wc_path = fname.norm_path(arg[1])
bk_path = fname.norm_path(arg[2])

do
  local bk_attr = lfs.attributes(bk_path:sub(1, -2))
  if not bk_attr or bk_attr.mode ~= 'directory' or #dir.collect(bk_path) ~= 0 then
    alert('incorrect backup path')
  end 
end

-- utils

-- отрезает от пути префикс wc_path
function convert_fname( fn )
  local fn_t = fname.split(fn)
  fn_t.dir = fname.norm_path(fn_t.dir)
  if fn_t.dir then
    if fn_t.dir:sub(1, #wc_path) ~= wc_path then
      alert('internal: incorrect path: ' .. fn)
    end
    fn_t.dir = fn_t.dir:sub(#wc_path+1)
  end
  return fname.merge(fn_t.dir, fn_t.name, fn_t.ext)
end

-- создает в bk_path директорию с относительным путем dir
function mkdir( dir )
  local cdir = bk_path
  for d in dir:gmatch('[^%/]+') do
    cdir = cdir .. '/' .. d
    local da = lfs.attributes(cdir)
    if da then
      if da.mode ~= 'directory' then
        alert("internal: incorrect node at path: " .. cdir)
      end
    else
      lfs.mkdir(cdir)
    end
  end
end

-- main

local cmdl = string.format("svn status %s", wc_path)
local file = assert(io.popen(cmdl))

ftbl = {}
for s in file:lines() do
  if s:match('^%?') then
    local fn = s:match('^%?%s+(.-)$')
    table.insert(ftbl, convert_fname(fn))
  end
end

function proc_file( fn )
  local fn_t = fname.split(fn)
  io.write(fn, '\n')
  if fn_t.dir then
    mkdir(fn_t.dir)
  end
  if do_move then
    os.execute(string.format('mv "%s" "%s"', wc_path .. fn, bk_path .. fn))
  else
    os.execute(string.format('cp "%s" "%s"', wc_path .. fn, bk_path .. fn))
  end
end

function proc_dir( fn )
  io.write('* ', fn, '\n')
  if do_proc_empty then
    mkdir(fn)
  end
  for fn, fattr in dir.tree(wc_path .. fn) do
    if fattr.mode == 'file' then
      proc_file(convert_fname(fn))
    end
  end
  if do_move then
    os.execute(string.format('rm -r "%s"', wc_path .. fn))
  end
end

for _, fn in ipairs(ftbl) do
  local ft = lfs.attributes(wc_path .. fn).mode
  if ft == 'file' then
    proc_file(fn)
  elseif ft == 'directory' then
    proc_dir(fn)
  else
    alert('unknown node: ' .. ft)
  end
end
