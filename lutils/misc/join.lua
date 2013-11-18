--[[
  �������������� ������, ���������� �� �������, ����������� ������� ��������
  � �����, � ������� ������ ����� ������������ ����� ���� ������� ������
  ������������ � �������� ��� ���������� �������, ��������� offline
  �� ����� � HTML-����� � ��� ������� �������� ������ � MSWord
  ������ ������ ������� ���������.
--]]

if #arg ~= 1 and #arg ~=2 then
  io.write('Usage: lua join.lua filename [pref]\n')
  os.exit()
end

pref = arg[2] or ""

line_buf = ""

function emit_buf()
  if #line_buf > 0 then
    io.write(pref .. line_buf .. "\n\n")
  end
  line_buf = ""
end

io.input(arg[1])
for s in io.lines() do
  _, _, ss = s:find('^%s*(.*)%s*$')
  if #ss == 0 then
    emit_buf()
  else
    for tj in ss:gmatch('%S+') do
      if #line_buf == 0 then
        line_buf = tj
      else
        line_buf = line_buf .. " " .. tj
      end
    end
  end
end
emit_buf()
