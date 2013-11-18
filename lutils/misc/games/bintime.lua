--[[
  ������� ������� ��������� ����� � �������� �������.
  ���� ����������� <lj user="avva">.
  ���������� ��� ��������� ;))
--]]

function num2bin( n ) -- �������������� ����� � �������� �������������
  local res = ""
  while n > 0 do
    res = tostring(math.fmod(n, 2)) .. res
    n = math.floor(n/2)
  end
  return res
end

tm1 = os.time()
while true do
  tm2 = os.time()
  if tm2 ~= tm1 then
    io.write(num2bin(tm2), '\n')
    tm1 = tm2
  end
end
