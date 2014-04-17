require "libdir"
require "libfname"
require "lfs"

local lake_cmd = 'make'
local lake_fname = 'build.llk'

local fnum = 0

local function collect_hg()
  local res = {}
  for fn, fattr in dir.tree(".") do
    local fnt = fname.split(fn)
    if fattr.mode == 'directory' and fnt.ext == '.hg' then
      table.insert(res, fnt.dir)
    end
  end
  return res
end

list = collect_hg()

local cwd = lfs.currentdir()

local out_list = {}
for _, path in pairs(list) do
  lfs.chdir(path)
  local res = os.execute("hg out >nul")
  out_list[path] = res
  lfs.chdir(cwd)
end

for path, res in pairs(out_list) do
  if res == 0 then
    io.write(path, ": push needed\n")
  elseif res == 255 then
    io.write(path, ": authentication problems\n")
  end
end
