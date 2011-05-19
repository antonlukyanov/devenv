require "libdir"
require "libfname"
require "lfs"

local lake_cmd = 'make'
local lake_fname = 'build.llk'

local fnum = 0
list = dir.collect(
  '.', 
  function(fn, attr) 
    local fnt = fname.split(fn)
    local res = attr.mode == 'file' and fnt.name == 'build' and fnt.ext == '.llk'
    if res then fnum = fnum + 1 end
    return res
  end 
)

local cwd = lfs.currentdir()
local log_fn = cwd .. '/lakitall.log'

local file = io.open(log_fn, 'wt')
file:close()

fnum, ok_num = 0, 0
for fn, fa in pairs(list) do
  local fnt = fname.split(fn)
  io.write(fnt.dir, '\n')
  lfs.chdir(cwd)
  lfs.chdir(fnt.dir)

  local file = io.open(log_fn, 'at')
  file:write(fnt.dir, '\n')
  file:write(string.rep('-', 80), '\n')
  file:close()
  
  local res = os.execute(string.format('llake %s %s 1>>%s 2>&1', lake_cmd, lake_fname, log_fn))
  fnum = fnum + 1
  if res == 0 then ok_num = ok_num + 1 end

  local file = io.open(log_fn, 'at')
  file:write(string.rep('-', 80), '\n')
  file:write((res == 0) and 'ok' or 'fail', '\n')
  file:write('\n')
  file:close()
end

if ok_num == fnum then
  io.write('\nall is ok\n')
else
  io.write(string.format('\nsome (%d/%d) shit happens\n', fnum-ok_num, fnum))
end
