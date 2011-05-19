--[[
  �������� ����� ���������� ������������.
--]]

if #arg ~= 1 then
  io.write('Usage: lua mkrcs.lua prjname\n')
  os.exit()
end
name = arg[1]

io.output(name .. '.lua')

io.write[==[
require "librcs"

local data = {

-- type requests here:


}

--[[ Template:
{
  type = "TYPE", date = "2007.mm.dd", from = "NAME", 
  -- to = "NAME",
  content = "WHAT_TODO",
  state = "STATE", 
  -- comment = "STATE_CMT"
},
--]]

--[[ Comments:
  NAME = name or 'customer'
  TYPE = 'request', 'bug', 'decision'
  STATE = 'active', 'done', 'frozen', 'transfered'

  ���� <comment> ����������� ������ ��� STATE = 'frozen' or 'transfered'

  ����� ��������� 'frozen':
    STATE = 'request'        ����� �� ����������
    STATE = 'bug'            ���������� ����
    STATE = 'decision'       ???

  ������ ��������� ����������:
    ����������� ���������� (��������� �� ����� ������)
    ��������� ���� ������ (�������� 'bug' -> 'decision')
    ��������� ��������
--]]

]==]

io.write(string.format('rcs(data, "__%s", arg[1])\n', name))
