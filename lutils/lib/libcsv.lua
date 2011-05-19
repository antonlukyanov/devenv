--[[
  ������� ��� ������ � ������ � ������� CSV
--]]

local function escapeCSV( s, delim )
  s = tostring(s) -- ����� ���� �������� ����������� ������
  if s:find('[' .. delim .. '"' .. ']') then
    s = '"' .. s:gsub('"', '""') .. '"'
  end
  return s
end

--[[
  ����������� ���� ������� t, ������������������ ������ ������� �� 1,
  � ������ � ������� CSV.
  ����, ���������� ������� ��� �������, ���� ����������� � �������,
  � ������� �������������� � �������� ������, �����������.
  ��������� ������ ��������� ���������� � �������� ����������� ';'
  ������ ',' �� ������ ��������� ����� ������� ����������� �����.
--]]

local function wrapCSV( t, delim )
  delim = delim or ','
  local s = ""
  for _, p in pairs(t) do
    s = s .. delim .. escapeCSV(p, delim)
  end
  return s:sub(2) -- remove first comma
end

--[[
  ��������� ������ s �� ���� � ������������ � ��������� �������
  CSV � ���������� �������, ������������������ ������ ������� �� 1.
  ���� ���������� �������� � ����� ���� ��������� � ������� �������
  (��� ���������� ��� ������������� �������, ���� ��� ���������� � ����).
  ���� ����� ���� ������, ��������� � �������� ������� �����������.
  ������ ������� ����� ���� �������, �� ���������� ������������� �����.
  ������ ������� ������ ������� ������� �����������.
  ���� ������� ����� � ����� ������, �� ���������, ��� ����� ���
  ���� ������ ����.
  ��� ������ ������ ���������� �������, ��������� �� ������ ������� ����.
  ���� �� ������������� �������� �� ������� �������, �� ������� ������
  �� ������� ����� ����������� � ����, ������ �� ��������� ����������������.
  ��������� ������ ��������� ���������� � �������� ����������� ';'
  ������ ',' �� ������ ��������� ����� ������� ����������� �����.
--]]

local function parseCSV( s, delim )
  delim = delim or ','
  s = s .. delim -- ending comma
  local t = {} -- table to collect fields
  local fieldstart = 1
  repeat
    if s:find('^"', fieldstart) then -- quoted field
      local c
      local i = fieldstart
      repeat   -- find closing quote not followed by quote
        _, i, c = s:find('"("?)', i+1)
      until c ~= '"'
      if not i then return nil end
      local f = s:sub(fieldstart+1, i-1)
      local cpos = s:find(delim, i)
      fieldstart = cpos + 1
      table.insert(t, (f:gsub('""', '"')) .. s:sub(i+1, cpos-1))
    else -- unquoted; find next comma
      local nexti = s:find(delim, fieldstart)
      table.insert(t, s:sub(fieldstart, nexti-1))
      fieldstart = nexti + 1
    end
  until fieldstart > #s
  return t
end

csv = {
  wrap = wrapCSV,
  parse = parseCSV
}

return csv
