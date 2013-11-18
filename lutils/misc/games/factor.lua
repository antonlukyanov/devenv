--[[
  Факторизация чисел на простые сомножители
--]]

if #arg == 0 then
  io.write('Usage: lua factor.lua numbers...\n')
  os.exit()
end

function factor( x )
  local d = 2
  local xx = x
  local res = {}
  while d * d <= x do
    local k = 0
    while math.fmod(xx, d) == 0 do
      xx = math.floor(xx / d)
      table.insert(res, d)
      k = k + 1
    end
    d = d + ((d==2 and 1) or 2)
  end
  if xx > 1 then
     table.insert(res, xx)
  end
  return res
end

for j = 1, #arg do
  x = tonumber(arg[j])
  io.write(x, ": ")
  if x <= 1 or math.mod(x, 1) ~= 0.0 then
    io.write("error\n")
  else
    list = factor(x)
    for _, j in ipairs(list) do
      io.write(j, " ")
    end
    io.write("\n")
  end
end
