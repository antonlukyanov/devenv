-- ���������� ��������� ��������� �������� ��������.

require "lfs"
require "libsys"
require "libfname"
require "librepo"

-- ��������� ����, ��������� �� ���������� ����������� ������������ ������ �������� '/'
-- � ������� � ������� ���������� ��� ������������� ����������, ���������� � ����.
local function xmkdir( path )
  local home = lfs.currentdir()
  for sd in path:gmatch('[^%/]+') do
    lfs.mkdir(sd)
    lfs.chdir(sd)
  end
  lfs.chdir(home)
end

-- ������������ ���� ������������ ����� ����������� � ����������.
local function mkpath( path )
  local base = repo.get_base_path()
  return fname.norm_path(base) .. '/' .. path
end

-- ������������ ������ prj_dir � ���������� exp_dir.
-- ���������� ������� �������� ������������ ����� �����������,
-- ���������� ���������� -- �� �������.
local function export_project( prj_dir, exp_dir )
  local home = lfs.currentdir()

  io.write('\n*** export <' .. prj_dir .. '>\n')
  lfs.chdir(mkpath(prj_dir))
  sys.exec('llake export build.llk')
  lfs.chdir('export')
  sys.exec('mv * ' .. fname.norm_path(home) .. '/' .. exp_dir)
  lfs.chdir('..')
  lfs.rmdir('export')

  lfs.chdir(home)
end

-- �������� ������ prj_dir.
local function make_project( prj_dir )
  local home = lfs.currentdir()

  io.write('\n*** make <' .. prj_dir .. '>\n')
  lfs.chdir(mkpath(prj_dir))
  sys.exec('llake make build.llk -s')

  lfs.chdir(home)
end

-- ����������� �����.
-- ���� � ��������� ����� �������� ������������ ����� �����������.
-- �������� dst ������ ������ ���������� ����������.
-- ���� �� ����� �������� new_name, �� ��� ����� ������� �� src.
local function copy( src, dst, new_name )
  if not new_name then
    local sfnt = fname.split(src)
    new_name = sfnt.name .. sfnt.ext
  end

  local sf = assert(io.open(mkpath(src), 'rb'))
  local data = sf:read('*a')
  sf:close()
  local df = assert(io.open(dst .. '/' .. new_name, 'wb'))
  df:write(data)
  df:close()
end

-- ��������� ����������� ���������������� -- ������ '${}' ���������� '@{}'.
local function xsubst( s, t )
  local function fn( x )
    local nm = x:sub(2, -2)
    assert(t[nm] ~= nil, "can't find name <" .. nm .. "> in lookup table")
    return tostring(t[nm])
  end

  local num
  repeat
    s, num = s:gsub("@(%b{})", fn)
  until num == 0
  return s
end

-- �������� ���� ������������, ��������� ���������������� (���� �������� ������� tbl).
-- ���� � ��������� ����� �������� ������������ ����� �����������.
-- �������� dst ������ ���� � ��� ����� ����������.
local function create_config( src, dst, tbl )
  local sf = assert(io.open(mkpath(src), 'rt'))
  local text = sf:read('*all')
  sf:close()
  if tbl then
    text = xsubst(text, tbl)
  end
  text = text:gsub('%-%-BEGIN%-REMOVE%-ME.-%-%-END%-REMOVE%-ME', '')
  local df = assert(io.open(dst, 'wt'))
  df:write(text)
  df:close()
end

export = {
  xmkdir = xmkdir,
  mkpath = mkpath,
  export_project = export_project,
  make_project = make_project,
  copy = copy,
  create_config = create_config,
}

return export
