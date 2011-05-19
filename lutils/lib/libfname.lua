--[[
  ���������� �������� � ������� ������
--]]

require "libwaki"

-- ��������� ������ ��� ����� �� ����, ��� � ����������.
-- ���������� ������� � ������ dir, name � ext.
-- ����� ���������� � ����������.
-- ���� ������ ����������� ������.
-- �������� ��� � ������, ��� � � �������� ������.
-- ����� ������� ����� �������������, � ���� ������
-- �� ��� ����� ������������ nil.
local function fnsplit( path )
  local _, a, dir = path:find("^(.*[/\\])")
  a = a or 0
  local b, _, ext = path:find("(%.[^%./\\]*)$")
  b = b or 0
  local name = path:sub(a+1, b-1)
  name = ((name~="") and name) or nil
  return { dir = dir, name = name, ext = ext }
end

-- �������� ������ ��� ����� �� ������� t, ���������� ���� dir, name � ext
-- ��� �� ���������� �� ����������� ����, ����� � ����������.
-- ����� ���� dir ����������� ����.
-- ����� ������������� ��������� �� ������������� ����� ��� ����������.
local function fnmerge( a, b, c )
  local function correct_dir( dir )
    if dir == nil or dir == '' then
      return ''
    end
    local c = string.sub(dir, -1)
    if c == '/' or c == '\\' then
      return dir
    end
    return dir .. '/'
  end
  if type(a) == "table" then
    return correct_dir(a.dir) .. (a.name or '') .. (a.ext or '')
  else
    return correct_dir(a) .. (b or '') .. (c or '')
  end
end

-- �������� �������� ����� �� ������ � ��������� ������������� ���� � �����
local function norm_path( path, case_sens )
  path = path:gsub('\\', '/')
  if path:sub(-1) ~= '/' then
    path = path .. '/'
  end
  return (case_sens and path) or waki.lower(path, 'win')
end

-- ��������������� ����
-- ������� �� ���� �������� ���� '/./', '/../', '//'
-- �������� �������� ����� �� ������
-- ��������� ������������� ���� � �����
function compact_path( path )
  local path = norm_path(path)

  local tbl = {}
  local is_root = false

  -- ���������� ������������ ���� � ������ �������
  if path:sub(1,1) == '/' then
    is_root = true
    path = path:sub(2,-1)
  end

  while true do
    local elem, tail = path:match('([^/]*)(.*)')

    if elem == '.' or elem == '' then
    elseif elem == '..' then
      if tbl[#tbl] ~= '..' and #tbl > 0 then
        table.remove(tbl)
      else
        table.insert(tbl, elem)
      end
    else
      table.insert(tbl, elem)
    end

    if tail:sub(1,1) == '/' then
      tail = tail:sub(2,-1)
    end
    if tail == '' then
      break
    end
    path = tail
  end

  local tcc = (is_root and '/' or '') .. table.concat(tbl, '/')
  return tcc .. (#tbl > 0 and '/' or '')
end

-- ������������� ����� ����� fn � �������� ������ re.
--[[
  ��������� ������ �������� �����, ��������� ���������� ���������.
  �������� ����� ������������ ����� ������������ �������� ����� Posix
  (��������� ��������� ��������).

  �������:
    1. ������������ ������ �������� �����, ����������� �������� ';' ��� ','.
    2. ��������� ������������ ��� ����� �������� ��������
       (��� ���������� �������� ������������ ��������� OEM).
    3. ���������� '*' ������� �� '#', ���������� '?' -- �� '@'.
       ���� ������ -- ���������� �� ������������� � ������������� ����������
       ���������� ��� ������� �������� ����� � ��������� ������ ��� �������.
    4. �� ��������� � ������������ DOS/Win ����� ����������� �����������
       � ���������� ��������� ���������� �������� '#'.

  �������:
    '#.#'     ��� �����
    '#'       ��� ����� � ������ �����������
    '#.'      �� �� �����
    '.#'      ��� ����� � ������ ������
--]]

local function conv_regexp( re )
  re = re:gsub('(%W)', '%%%1')  -- ������������� ������������
  re = re:gsub('%%%#', '.*')  -- ������ '#' �� '.*'
  re = re:gsub('%%%@', '.?')  -- ������ '@' �� '.?'
  return '^' .. re .. '$'
end

local function fnmatch( fn, rel )
  fn = waki.lower(fn, 'win')
  rel = waki.lower(rel, 'win')
  fn_s = fnsplit(fn)
  fn_s.name = fn_s.name or ''
  fn_s.ext = fn_s.ext or '.'       -- ������ ���������� ���� ������ '.'
  for re in rel:gmatch('[^%;%,]+') do
    re_s = fnsplit(re)
    re_s.name = conv_regexp(re_s.name or '')
    re_s.ext = conv_regexp(re_s.ext or '.')  -- ������ ����� ���������� ���� '.'
    if (string.find(fn_s.name, re_s.name)) == 1 and (string.find(fn_s.ext, re_s.ext)) == 1 then
      return true
    end
  end
  return false
end

fname = {
  split = fnsplit,
  merge = fnmerge,
  norm_path = norm_path,
  compact_path = compact_path,
  match = fnmatch,
}
return fname
