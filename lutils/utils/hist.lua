--[[
  ������ ����������� ��� ����� �����, ����������� �� ������� ������� �����.
  ���������� ��������� � ��� ������� -- � ������ ������� ��������� �����,
  �� ������ -- ����� ��� ���������� � �����.
  ���������� ��������� � ������� ����������� ������.
--]]

if #arg ~= 1 then
  io.write('Usage: lua hist.lua filename\n')
  os.exit()
end

io.input(arg[1])
hist = {}
for s in io.lines() do
  _, _, tt = s:find('(%S+)')
  num = tonumber(tt)
  if hist[num] ~= nil then
    hist[num] = hist[num] + 1
  else
    hist[num] = 1
  end
end

repeat
  max = 0
  num = -1
  for n, r in pairs(hist) do
    if r > max then
      max = r
      num = n
    end
  end
  if num ~= -1 then
    io.write(num, " ", max, "\n")
    hist[num] = nil
  end
until num == -1
