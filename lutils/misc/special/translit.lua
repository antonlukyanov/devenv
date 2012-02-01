--[[
  �������������� �����
  �������� ���� ������ ���� � ��������� cp1251
--]]

require "libwaki"

if #arg ~= 1 then
  io.write('Usage: lua translit.lua file\n')
  os.exit()
end

-- ������� ������������� ����������� ������� ��������������
-- �� ����������� ����������� � ��� ���� '�', '�', �������
-- �� ����������� ������� ������������ � ����� '�',
-- ������������� � ����������� �������
tr = {
  ["�"] = "a",     ["�"] = "b",     ["�"] = "v",     ["�"] = "g",
  ["�"] = "d",     ["�"] = "e",     ["�"] = "zh",    ["�"] = "z",
  ["�"] = "i",     ["�"] = "j",     ["�"] = "k",     ["�"] = "l",
  ["�"] = "m",     ["�"] = "n",     ["�"] = "o",     ["�"] = "p",
  ["�"] = "r",     ["�"] = "s",     ["�"] = "t",     ["�"] = "u",
  ["�"] = "f",     ["�"] = "h",     ["�"] = "ts",    ["�"] = "ch",
  ["�"] = "sh",    ["�"] = "shch",  ["�"] = "'",     ["�"] = "y",
  ["�"] = "'",     ["�"] = "e",     ["�"] = "yu",    ["�"] = "ya",
  ["�"] = "e",
}

file = assert(io.open(arg[1], "rb"))
data = file:read("*all")
file:close()
len = #data

for s in io.lines(arg[1]) do
  for j = 1, #s do
    ch = s:sub(j, j)
    lch = waki.lower(ch, 'win')
    if tr[lch] then
      if lch ~= ch then
        io.write(tr[lch]:upper())
      else
        io.write(tr[lch])
      end
    else
      io.write(ch)
    end
  end
  io.write('\n')
end
