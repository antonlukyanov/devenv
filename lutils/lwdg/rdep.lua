--[[
  Recursive dependency resolver
--]]

std_modules = {
  "kernel32.dll", "ntdll.dll", "msvcrt.dll",
  "oleaut32.dll", "comdlg32.dll", "comctl32.dll", "shlwapi.dll", 
  "shell32.dll", "ole32.dll", "rpcrt4.dll", "advapi32.dll", 
  "gdi32.dll", "user32.dll",
  "ws2help.dll", "ws2_32.dll", "wsock32.dll", "winmm.dll",
  "dciman32.dll", "ddraw.dll", "glu32.dll", "opengl32.dll",
}

for _, v in ipairs(std_modules) do
  std_modules[v] = true
end

if #arg ~= 1 then
  io.write('Usage: lua rdep.lua executable-file-name\n')
  os.exit()
end
fname = arg[1]

local function pipe_tbl( cmdl )
  local file = assert(io.popen(cmdl))
  local res = {}
  for s in file:lines() do
    local fn
    if s:match("^%s*Not found%:") then
      fn = s:match("^%s*Not found%:%s*(%S+)%s*"):lower()
    else
      fn = s:match("%s*(%S+)%s*"):lower()
    end
    if not std_modules[fn] then
      table.insert(res, fn)
    end
  end
  file:close()
  return res
end

function is_ok( fn )
  return io.open(fn, 'rb') ~= nil
end

function depends( base )
  local dep_lst = pipe_tbl("depends " .. base)
  for _, fn in ipairs(dep_lst) do
    if not is_ok(fn) then
      io.write(fn, ' (', base, ')\n')
    end
  end
  for _, fn in ipairs(dep_lst) do
    if fn ~= base and is_ok(fn) then
      depends(fn)
    end
  end
end

depends(fname)
