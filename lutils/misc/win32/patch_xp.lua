-- ������ ���������� ������������� windows-xp, �������������� ������������ � ��� 
-- ������� find � sort, ����������� �� ����� � ���������������� ��������� �� msys.
--
-- ������ ���������� ��������� � ������� ��������������.
-- ����� ��������� ����� ����� ������� ������� ������������ windows
-- ��������� ������������ "����������" ������ ��������������� ������.
-- � ���� ������� ����� ������ ������ ������/Cancel � �����������
-- ���� �������, ����� ��/Ok � ��������� �������.

windir = os.getenv('windir')

function run( cmd ) 
  return os.execute(cmd:gsub('\\', '/'))
end

run('rm ' .. windir .. '\\system32\\dllcache\\find.exe')
run('rm ' .. windir .. '\\system32\\dllcache\\sort.exe')

run('mv ' .. windir .. '\\system32\\find.exe ' .. windir .. '\\system32\\find.ex_')
run('mv ' .. windir .. '\\system32\\sort.exe ' .. windir .. '\\system32\\sort.ex_')
