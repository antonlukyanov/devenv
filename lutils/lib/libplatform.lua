--- ��������� ���������� ������� uname ��� ����������� ������������ ��.
local uname_val = string.lower(
    assert(io.popen('uname')):read('*l')
  )

--- ���������� "���" ������������ �������.
-- 
-- ���������� linux ��� Debian/Ubuntu, osx ��� Mac OSX, mingw ��� Windows � �������������� MinGW.
local function get_os_type()
  if uname_val:match('linux') then
    return 'linux'
  elseif uname_val:match('darwin') then
    return 'osx'
  elseif uname_val:match('mingw') then
    return 'windows'
  else
    stop("unknown name of operating system")
  end
end

--- ���������� �������� ��� ��������� ���������� ������ ������� os.execute().
local function get_success_code()
  local code
  if os == 'mingw' then
    code = 0
  else
    code = true
  end
  return code
end

platform = {
  uname = uname_val,
  os_type = get_os_type(),
  get_os_type = get_os_type,
  get_success_code = get_success_code,
}

return platform
