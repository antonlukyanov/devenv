--[[
  ���������� �������� ���������������� awk.
--]]

local line = ""

-- ���������, ������������� �� ������ str ������� pat.
-- ���� ������� ���� ��������, �� � �������� ������ ������������
-- ������� ������, ����������� �� �������� ������.
local function is( pat, str )
  if not str then
    str = line
  end
  return (string.find(str, pat)) ~= nil
end

-- ��������� ������������ ������� �����, �������� ������ ������ �� ����,
-- ��������������� ������� pat � ������� ������� func.
-- �������  func ���������� ������� �������� ����� � ����� ������� ������.
-- � ������� ���� ���������� � �������, �� �������� ������� ���������� ������� ������.
-- ���� ������� ���� ��������, �� ������������ ������, ��������������� ���������
-- ������ �� �����, ��������� �� ������������ ��������.
local function run( func, pat )
  if not pat then
    pat = '%S+'
  end

  local ln = 1
  for s in io.lines() do
    local fl = {}
    fl[0] = s
    line = s
    local fn = 0
    for ss in string.gmatch(s, pat) do
      fn = fn + 1
      fl[fn] = ss
    end
    func(fl, ln)
    ln = ln + 1
  end
end

awk = {
  is = is,
  run = run,
}

return awk
