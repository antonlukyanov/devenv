--[[
  Печатает сводку использования различных символов
  перевода строки в заданном файле
--]]

if #arg ~= 1 then
  io.write('Usage: lua crlfcheck.lua filename\n')
  os.exit()
end

f = assert(io.open(arg[1], "rb"))

data = f:read("*all")

set = {}
for j in data:gmatch("[\r\n]+") do
  set[j] = 1
end

for j in pairs(set) do
  _ = j:gsub("\r", "<CR>")
  sr = _:gsub("\n", "<LF>")
  io.write(sr)
end
