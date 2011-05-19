--[[
  ���������� ���������� �� Lua � exe-���� (��������� �� lua.dll).

  ���������� ����� ������������ ���� ��� ����������� ����������, 
  ���� ��� ������ � ������� ������� ����������.
  ��� ������������� � �������� ������ �������������� ������� luacc,
  ���������� ������� compile().

  ���� ����� ������������� ��� ������� ���������� �������� ������ �.�. 
  �� ������� (����������� require) �� �� �������� � ���� lua-������,
  �� ���������� exe-���� ����������� ����������� � �� ������� ��� ������ �������
  ����������� �����-���� ����������.
  � ��������� ������ �� ��������� ��� ���������� �������� ����� ����� ����������� 
  ��������������� �� ����� ���������� �.�. ��� ��������� ������� exe-�����
  ��� ��������� ������ ����� �������������� � ������� ���������� ��� ����, 
  ����������� � lua_path.

  ���� � ���� ���������� ������������ �������� ������� ��������� (lfs � �.�.),
  �� ��� �������� ����� ������������� � exe-������ �.�. ��������������� ����������
  ������ ����� �������������� � ������� ��� �������� ������� exe-�����.

  ��������������, ��� ����������� gcc � luac, � ����� ���������� liblua51.a � 
  ��������������� ������������ ����� ��������� ����������� � �������, 
  �� ������� ������������ ����������.
--]]

function cc( dst, src )
  home = os.getenv('LWDG_HOME')
  local compiler = string.format(
    "g++ -DLUA_BUILD_AS_DLL -L%s -I%s -o %s %s -llua51", 
    home..'/lib', home..'/include', dst, src
  )
  os.execute(compiler)
  os.execute('strip ' .. dst)
end

require "luacc_driver"
require "libfname"
require "libcmdl"

local function write_bin( file, data )
  for j = 1, #data do
    local code = data:byte(j)
    file:write(string.format("0x%02X, ", code))
    if math.fmod(j, 16) == 0 then
      file:write('\n')
    end
  end
end

local function write_chunk( file, name, data )
  file:write('static const char luacc_' .. name .. '[] = {\n')
  write_bin(file, data)
  file:write('};\n\n');
end

local function proc_lua( fnm, do_strip )
  local luac_fn = '.' .. os.tmpname()
  os.execute('luac -o ' .. luac_fn .. ((do_strip and ' -s ') or ' ') .. fnm)
  local luac_file = io.open(luac_fn, 'rb')
  local luac_data = luac_file:read('*all')
  luac_file:close()
  os.remove(luac_fn)
  return luac_data
end

local function get_base_name( nm )
  return fname.split(nm).name
end

local module_tbl_hdr = [[
struct require_tbl_type {
  const char* m_name;
  const char* m_code;
  const int m_size;
};

struct require_tbl_type require_tbl[] = {
]]

local function compile( do_strip, dst, ... )
  local src = { ... }

  local c_fn = '.' .. os.tmpname() .. '.cc'
  local c_file = io.open(c_fn, 'wt')

  c_file:write'// precompiled bytecode\n\n'
  for j = 1, #src do
    local fnm = src[j]
    local cd = proc_lua(fnm, do_strip)
    write_chunk(c_file, get_base_name(fnm), cd)
  end

  c_file:write'// module table\n\n'
  c_file:write(module_tbl_hdr)

  for j = 1, #src do
    local nm = get_base_name(src[j])
    c_file:write(string.format('  {"%s", luacc_%s, sizeof(luacc_%s)},\n', nm, nm, nm))
  end
  c_file:write(string.format('  {0, 0, 0},\n', nm, nm, nm))
  c_file:write('};\n\n');

  c_file:write'// luacc driver\n\n'
  c_file:write(luacc_driver);
  c_file:close()

  cc(dst, c_fn)
  os.remove(c_fn)
end

luacc = {
  compile = compile
}

-- main

if not package.loaded['luacc'] then
  opt = cmdl.options()
  do_strip = opt['-s']

  if #arg < 2 then
    io.write('Usage: lua luacc.lua [-s] dstfile mainfile [srcfiles...]\n')
    os.exit()
  end

  compile(do_strip, unpack(arg))
else
  return luacc
end
