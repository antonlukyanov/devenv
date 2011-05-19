--[[
  ������������� ������� preinstall.sh, ����������� ��������� ������� ����������.

  ������ ������ (mk_preinstall.lua) �������� ������ � ��������� ������������� ������� ���������.
  �� ������� ��������� ���� ������ �� ����� ����������� �������� ���������.
  �� ����� ����������� ������� ������������ ������ preinstall.sh, ������������� � �����������.
--]]

tpu_path = '../lwutils/third-party'         -- from /lwboot
lua_path = '$TPU/lua51/src'                 -- from /lwboot

lua_modules = dofile('../../lwutils/third-party/lua-addons/setup/lua_modules.lua') -- from here

file = assert(io.open('../preinstall.sh', 'wt'))

file:write('# Automatically generated by tools/mk_preinstall.lua, no hands!\n\n')
file:write("echo Building installation environment...\n")
file:write('TPU=', tpu_path, '\n')
file:write('patch --output=$TPU/lua51/src/linit_istools.c $TPU/lua51/src/linit.c $TPU/lua-addons/misc/lua-istools.diff\n')
file:write('cp $TPU/lua-addons/misc/istools.c $TPU/lua51/src\n')
file:write('/mingw/bin/g++ -O2 -Wall -otemp/standalone-lua.exe \\\n')
file:write('  ' .. lua_path .. '/istools.c \\\n')
for j, fn in ipairs(lua_modules) do
  if fn == 'linit' then
    fn = 'linit_istools'
  end
  file:write('  ' .. lua_path .. '/' .. fn .. '.c \\\n')
end
file:write('  ' .. lua_path .. '/lua.c\n')
file:write('/mingw/bin/strip temp/standalone-lua.exe\n')
file:write('rm $TPU/lua51/src/istools.c $TPU/lua51/src/linit_istools.c\n')

file:close()
