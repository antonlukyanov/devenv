--[[
  ���������� ����� � ���������� ���������
--]]

local function run( fname, exp )
  local func = assert(loadfile(fname))        -- ��������� ���� ��� �������
  local env = { }                             -- ������� �������-���������
  if exp then                                 -- ������������ ������� �� ������ ��������
    for f_nm, f_fn in pairs(exp) do
      env[f_nm] = f_fn
    end
  end
  setmetatable(env, {__index = _G})           -- ���� �� ��� ������ � ����������� �����������
  setfenv(func, env)                          -- ��������� �� ��� ��������� ��� �������
  func()                                      -- ��������� �������
  return env
end

prot = {
 run = run
}

return prot
