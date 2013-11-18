--[[
  ��������� ���-���� llogsrv � ��������� ����������������� ���,
  �������� ��������� � ������������ � �� "��������".

  ���������� �������� �������� ��������, ������� ������ ���������� ������,
  ����������� � ����� � ������ 'llogopt' � ������� ����������.
  � ���� ������� ��� ������� ������� �������� �������� true ��� false,
  ������������, ����� �� ��������� �������� � ������������ ���.
  ���� ��������� �� ����� �������, �� ��� ������������� ������ ������
  (������ ������� �������� ������ ������).
  ���� ��� ���������� ��������� ��� ������ �� ��� ���� ������ � �������
  ��������, �� ����� ������ ��������� � ��� ����������� ���������
  �������� ������� �������� � �������� 1.

  � ����� ������������������ ���� ������������� ��� �������, �������������
  ��� ������� ������� ���� (����� ������� �������).
  ��� ������� ������� ��������� �������� (on/off), ������ �� �������
  �������� ��� ����� default, ���� ������ ����������� � ���� �������.
--]]

logopt = {
  ['lwml:mem'] = false,
  ['lwml:dload'] = false,
  ['lwml:dump'] = false,
  ['lwml:io'] = false,

  ['llogsrv:cwd'] = true,
  ['lwml:config'] = true,
  ['lwml:console'] = true,
  ['lwml:luaconf'] = true,
  ['limcov'] = true,
  true
}

extopt = loadfile('llogopt')
if extopt then
  local opt = extopt()
  for k, v in pairs(opt) do
    logopt[k] = v
  end
end

require "libcsv"

if #arg ~= 1 then
  io.write('Usage: lua llog.lua logfile\n')
  os.exit()
end

file = arg[1]

debt = {}      -- ���� ���������� ��������� ���������
depth = 0      -- ������� ������������� ���������
ctx = {}       -- ���� ������� �������� ���������
aspects = {}   -- ������ ������������� ��������

function parse( s )
  local t = csv.parse(s)
  aspects[t[3]] = true
  return  {
    thr = t[1],
    tm = t[2],
    asp = t[3],
    msg = t[4]
  }
end

function pr_msg( msg, tm, thr, asp )
  local ind = string.rep(':   ', depth)
  io.write(ind, msg)
  if asp and asp ~= '' then
    io.write(' [' .. asp .. ']')
  end
  io.write('\n')
end

for s in io.lines(file) do
  local rec = parse(s)
  if rec.asp == '>>>' then
    table.insert(debt, rec)
    table.insert(ctx, rec)
  elseif rec.asp == '<<<' then
    local cc = table.remove(ctx)
    if #debt ~= 0 then
      table.remove(debt)
    else
      depth = depth - 1
      pr_msg('< ' .. cc.msg, rec.time, rec.thread)
    end
  else
    local asp = rec.asp
    if (logopt[asp] ~= nil and logopt[asp]) or (logopt[asp] == nil and logopt[1]) then
      for _, d in ipairs(debt) do
        pr_msg('> ' .. d.msg, d.time, d.thread)
        depth = depth + 1
      end
      debt = {}
      pr_msg(rec.msg, rec.time, rec.thread, asp)
    end
  end
end

io.write('\n--\naspects:\n')
for asp, v in pairs(aspects) do
  if asp ~= '' and asp ~= '<<<' and asp ~= '>>>' then
    local v = logopt[asp]
    local vt = (v~=nil and (v and "on" or "off") or "default")
    io.write('  ', asp, ': ', vt, '\n')
  end
end
io.write('--\n')
