--[[
  Печать значений переменных среды.
  Отдельными группами печатаются
   - нестандартные для w2k переменные
   - наиболее важные переменные
   - элементы списка путей поиска
--]]

require "libwaki"
require "lfs"

if #arg ~= 0 then
  io.write('Usage: lua lenv.lua\n')
end

-- стандартные переменные
std = {
  "userprofile", "programfiles", "homedrive", "userdomain", "temp", "prompt",
  "windir", "processor_revision", "computername", "allusersprofile", "username",
  "tmp", "os2libpath", "os", "homepath", "processor_level", "pathext",
  "number_of_processors", "comspec", "systemroot", "appdata", "systemdrive",
  "path", "logonserver", "processor_identifier", "processor_architecture",
  "commonprogramfiles", "winbootdir",
  "sessionname",

  "vbox_install_path", 
  "farhome", "faradminmode", "farlang",
  "vs90comntools",
}

function is_std( nm )
  for _, snm in pairs(std) do
    if waki.lower(nm, 'alt') == snm then
      return true
    end
  end
  return false
end

fnm = "." .. os.tmpname() .. "tmp"
os.execute('set >' .. fnm)
file = io.open(fnm, "rt")
envv = {}
for s in file:lines() do
  _, _, var, val = s:find('^(.*)=(.*)$')
  envv[waki.lower(var, 'alt')] = val
end
file:close()
os.remove(fnm)

io.write("user:\n")

for var, val in pairs(envv) do
  if not is_std(var) then
    io.write("  " .. var .. "=" .. val .. "\n")
  end
end

imp = {
  ["computername"] = 1,
  ["username"] = 1,
  ["temp"] = 1,
  ["tmp"] = 1,
}

io.write("standard:\n")

for var, val in pairs(envv) do
  if imp[waki.lower(var, 'alt')] then
    io.write("  " .. var .. "=" .. val .. "\n")
  end
end

io.write("path:\n")

path = envv["path"]
for s in path:gmatch('[^%;]+') do
  local ss = s
  if s:sub(-1, -1) == '/' or s:sub(-1, -1) == '\\' then
    ss = s:sub(1, -2)
  end
  local ok = (lfs.attributes(ss, 'mode') == 'directory')
  io.write("  " .. (ok and '[ok] ' or '[fail] ') .. s .. "\n")
end
