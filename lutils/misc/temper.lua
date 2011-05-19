--[[
  Преобразование температуры между
  градусами Цельсия и градусами Фаренгейта
--]]

if #arg ~= 2 then
  io.write('Usage: lua temper.lua conv temperature\n')
  io.write("conv:\n")
  io.write("  CF  - Celsius to Fahrenheit\n")
  io.write("  FC  - Fahrenheit to Celsius\n")
  os.exit()
end

t = tonumber(arg[2])

if arg[1]:upper() == 'CF' then
  io.write(t * 9/5 + 32, '\n')
elseif arg[1]:upper() == 'FC' then
  io.write((t-32) * 5/9, '\n')
else
  error('unknown conversion')
end