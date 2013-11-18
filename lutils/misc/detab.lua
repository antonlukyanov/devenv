if #arg ~= 2 then
  io.stderr:write('Usage: lua detab.lua tabsize filename\n')
  os.exit(1)
end
tabsize = tonumber(arg[1])
filename = arg[2]

function proc_line( s )
  local res = ""
  local col = 0
  for j = 1, #s do
    local ch = s:sub(j,j)
    if ch == '\t' then
      repeat
        res = res .. ' '
        col = col + 1
      until col % tabsize == 0
    else
      res = res .. ch
      col = col + 1
    end
  end
  return res
end

f = io.open(filename, "rt")
t = {}
for s in f:lines() do
  table.insert(t, proc_line(s))
end
f:close()

f = io.open(filename, "wt")
for _, s in ipairs(t) do
  f:write(s, '\n')
end
f:close()
