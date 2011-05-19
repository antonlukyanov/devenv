--[[
  �������� ��������������� �������� ����������������.
--]]

-- ���������������� ��� ��������-����.
-- � ������ s �������� ��� ��������� ${name} �� t["name"].
-- ��� �������������� ������ ������ ����������� ����������.

local function subst( s, t )
  local function fn( x )
    local nm = x:sub(2, -2)
    local res = assert(t[nm], "can't find name <" .. nm .. "> in lookup table")
    return res
  end

  local num
  repeat
    s, num = s:gsub("$(%b{})", fn)
  until num == 0
  return s
end

-- ���������������� ��� ��������-�������

-- � ������ s ������������ ����� ������ ���� \cmd{arg}.
-- ����� ��� ������ ������� ������������ ����� � ������� ctx.
-- ���������� ������� � ������� ��������� �������.
-- ���� � ������� ������� �������, �� ��� ���������� � ���������� arg.
-- ��� ������� ������ ���������� ������, �� ������� ����� �������� �������.
-- ������������ �������� �������� nil ���������� ��� ������ ������.
-- ������������� ������� ����� ���������� ���� ������������� ��������� (boolean).
-- ���� ��������� �������� ���� ������������� ���������, �� ������������ ��������
-- �������� �� �������������� ����������.
-- ���� � ������� ������� ������, �� ��� �������� ����� �������.
-- ��� ���� �����������, ��� �������� ������, ����� ������������ ������.
-- � ���������� ��������� ����������� ������ ����������� ����������� ���������.
-- ������� pref_proc ����������� �� ���� �������, ��� �� ���������� ������,
-- ����� �����, ���������� � ���������� ���������� �������, ���������
-- ���� ������������� ���������.

local function func( s, ctx, pref_proc )
  local pref, cmd, arg, postf = s:match('^(.-)$(%w+)(%b{})(.*)$')
  if pref then
    pref = (pref_proc and pref_proc(pref)) or pref
    local arg = arg:sub(2, -2)
    local act = assert(ctx[cmd], "can't find command <\\" .. cmd .. "> in lookup table")
    if type(act) == 'function' then
      cmd, is_done = act(arg)
      cmd = cmd or ''
      if not is_done then
        cmd = func(cmd, ctx, pref_proc)
      end
    else
      if arg ~= '' then
        error("incorrect argument for string substitution")
      end
      cmd = func(act, ctx, pref_proc)
    end
    return pref .. cmd .. func(postf, ctx, pref_proc)
  else
    return (pref_proc and pref_proc(s)) or s
  end
end

macro = {
  subst = subst,
  func = func,
}

return macro
