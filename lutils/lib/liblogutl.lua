-- some usefull functions for log file analysis

-- ������ � ���� ����� ������
local function write_text( fn, t )
  local file = io.open(fn, 'wt')
  file:write(t)
  file:close()
end

-- ������ � ���� ipairs-�������
function write_tbl( fn, t )
  local file = io.open(fn, 'wt')
  for _, v in ipairs(t) do
    file:write(v, '\n')
  end
  file:close()
end

-- ��������� �����
function printf( arg1, ... )
  if type(arg1) == 'string' then
    io.write(string.format(arg1, ...))
  else
    io.write(arg1, string.format(...))
  end
end

-- ���������� ������� � �������� ��������� ������
function exec(...)
  local cmdl = string.format(...)
  print(cmdl)
  os.execute(cmdl)
end

-- ��������� �������� ��������� ��������� (������ 'parname=dddd.ddd')
function get_par( s, nm )
  local v = s:match(nm .. '=([%d%.e%-]+)')
  return tonumber(v)
end

-- ������ ������� ����������� �� �������� ipairs-�������
function tbl_stat( t )
  local min, max, mid = t[1], t[1], t[1]
  for _, v in ipairs(t) do
    if v < min then min = v end
    if v > max then max = v end
    mid = mid + v
  end
  mid = mid / #t
  for _, v in ipairs(t) do
    var = var + (v - mid)^2
  end
  var = math.sqrt(var / #t)
  return { min = min, max = max, mid = md, var = var }
end

logutl = {
  write_text = write_text,
  write_tbl = write_tbl,
  printf = printf,
  exec = exec,
  get_par = get_par,
  tbl_stat = tbl_stat,
}
