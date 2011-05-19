--[[
  �������� ����������� ����������� � ������� ������� svnsync (��� ������� � svnadmin).

  ����� ��������� ������ ��������� ������ URL �������� ����������� ('-b'),
  ��� ������������, �� ����� �������� ������������ �������������� ('-u') � ��� ������ ('-p').
  �� ��������� ������������ �������������� ����������� � ������� ������� 'svn://2x.ru/svn'
  �� ����� ������������ 'sync' � ������������� ����������� �������.

  ������� ��������� � ������������� ������� ����������.
  ����� '-f' ���������� ������ �������������� �����������.
  � ���� ������ � ��� ����������-������� ������������� ���� � ����� �� ������ �������� �������.
  �� ��������� ������������ ������������ �������������� � ��� ����������-�������
  ��������� � ������ �����������.
  ��� ������������� ������������� ������� ������� ������������ ����� '-i'.

  � ���������� hooks ������������� ������������� �������-����, ��������������
  ��������� ������ � ������� ������ ������������ 'sync'.
--]]

require "libsys"
require "lfs"
require "libcmdl"

local base_url = 'svn://2x.ru/svn'
local username = 'sync'
local userpass = 'dveXOu4'
local cwd = lfs.currentdir()

local opt = cmdl.options()
if #arg ~= 1 then
  io.write('Usage: lua lsvnsync.lua repo-name [-bBASE_URL] [-uUSER_NAME] [-pUSER_PASS] [-f] [-i]\n')
  os.exit()
end
rname = arg[1]

if opt['-b'] then base_url = opt['-b'] end
if opt['-u'] then username = opt['-u'] end
if opt['-p'] then userpass = opt['-p'] end

local mname = rname
if opt['-f'] then
  mname = mname .. '-' .. os.date('%Y_%m_%d-%H_%M_%S')
end
local mpath = string.gsub(cwd .. '/' .. mname, '\\', '/')
local repos = base_url .. '/' .. rname

local mirror_url = 'file:///' .. mpath

-- hooks

pre_revprop_change = [[
@echo off
set USER=%3
if -%USER%==-sync exit 0
echo Only the user 'sync' user may change revision properties >&2
exit 1
]]

start_commit = [[
@echo off
set USER=%2
if -%USER%==-sync exit 0
echo Only the user 'sync' user may commit new revisions >&2
exit 1
]]

function save_str( fn, str )
  local f = assert(io.open(fn, 'wt'))
  f:write(str)
  f:close()
end

-- main

local auth = string.format("--no-auth-cache --source-username %s --source-password %s --sync-username sync", username, userpass)
if opt['-f'] or opt['-i'] then
  sys.exec('svnadmin create', mpath)
  save_str(mpath..'/hooks/pre-revprop-change.bat', pre_revprop_change)
  save_str(mpath..'/hooks/start-commit.bat', start_commit)
  sys.exec('svnsync initialize', auth, mirror_url, repos)
end
sys.exec('svnsync synchronize', auth, mirror_url)
