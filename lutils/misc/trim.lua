if #arg ~= 1 then
  io.stderr:write('Usage: lua trim.lua filename\n')
  os.exit(1)
end

f = io.open(arg[1], "rt")
t = {}
for s in f:lines() do
  s = s:match('^(.-)%s*$')
  table.insert(t, s)
end
f:close()

f = io.open(arg[1], "wt")
for _, s in ipairs(t) do
  f:write(s, '\n')
end
f:close()
