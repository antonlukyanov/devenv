--[[
  ���������� ������ � �������������� ��������� ������ �������� ������ � ����� �����.
  ������� ������������ ������ � ������� ������, ��������� ��� ���������������
  ��������� ������ �����.
--]]

if #arg ~= 2 then
  io.write('Usage: lua crlffixup.lua infile outfile\n')
  os.exit()
end

local inp = assert(io.open(arg[1], "rb"))
local out = assert(io.open(arg[2], "wb"))

local data = inp:read("*all")
data = data:gsub("[\r\n]+", "\r\n")
out:write(data)

assert(out:close())
