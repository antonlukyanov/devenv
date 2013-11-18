--[[
  Перевод числа в римскую запись
--]]

if #arg == 0 then
  io.write('Usage: lua roma.lua numbers...\n')
  os.exit()
end

digits = {
  { val = 1000, rep = "M" },
  { val = 900, rep = "CM" }, { val = 500, rep = "D" }, 
  { val = 400, rep = "CD" }, { val = 100, rep = "C" },
  { val = 90, rep = "XC" }, { val = 50, rep = "L" }, 
  { val = 40, rep = "XL" }, { val = 10, rep = "X" },
  { val = 9, rep = "IX" }, { val = 5, rep = "V" },
  { val = 4, rep = "IV" }, { val = 1, rep = "I" },
}

function roma( x )
  local pos = 1
  local res = ""
  while x >= 1 do
    dig = digits[pos]
    pos = pos + 1
    while dig.val <= x do
      res = res .. dig.rep
      x = x - dig.val
    end
  end
  return res
end

for j = 1, #arg do
  num = tonumber(arg[j])
  io.write(num, ': ')
  if num < 0 or math.mod(num, 1) ~= 0 then 
    io.write('error\n')
  else
    io.write(roma(num), '\n')
  end
end
