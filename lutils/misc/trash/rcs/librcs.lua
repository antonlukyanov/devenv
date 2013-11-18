-- ������� ���������� ������������
-- (c) ltwood, 2006

require "libhtml"

--[[
  ���� �������� ���������� �������� ������� ����������
  � �������� ������� rcs(), ��������� �� ��� ������� � ��� �������.

  ������� ���������� ������������ ����� ������ (�������� �������) ����������.
  ������ ���������� ������������ ����� ������� �� ���������� ������:

    type       -- ��� ������
    date       -- ���� ��������� ������ � ������� YYYY.MM.DD
    from       -- �������� ������ (��� ��� ����� 'customer')
    to       * -- ������� ������ (���)
    content    -- ���������� ������
    state      -- ��������� ������
    comment  * -- ����������� � ��������� ������

  ���������� �������� �������������� ����.

  ���������� ���� �������:

    request    -- ������ �� ����������������
    bug        -- ������ �� �������
    decision   -- ��������� ������� (������ ���� -- ����������� ���)

  ���������� ��������� ������:

    active     -- �������
    done       -- ��������� (���������� ���������)
    frozen     -- ������ ���������� (���������� �������� ������������)
    transfered -- ������ ���������� (������������ � ���� ��� ��������� ������ �������)

  ��� ������������ � ������������ ������� ����������� (comment) ����������.
  �� ������ �������� ������� ��������� ��� ��������.

  ����� ��������� ���������:
    -- ��������� ���� �������� ��� ����������� ����������.
    -- ���������� ���������� �������� ����� �� ����.
    -- ��������� ���������� ������� ���������, �� ���� �� ����������.

  �������� ������ ����� ��������� � ���������� ����������� ����������
  (��� ���� ��� ������ ����������� �� ����� ������ ������),
  ��� ��������� ���� ������ (�������� ����� ��� ������������ � ���� -- decision),
  ��� ��������� �������� ������ (������ � ������ ������� �� �������).
--]]

-- data validator

local field_set = {
  type=1, date=1, from=1, to=1, content=1, state=1, comment=1
}
local req_fields = {
  "type", "date", "from", "content", "state"
}
local type_set = {
  request=1, bug=1, decision=1
}
local state_set = {
  active=1, done=1, frozen=1, transfered=1
}
local req_comment_state_set = {
  frozen=1, transfered=1
}

local function validate( data )
  for _, r in ipairs(data) do
    -- �������� ������������ ���� �����
    for f, v in pairs(r) do
      if field_set[f] == nil then
        error('unknown field: ' .. f)
      end
    end

    -- �������� ������� ������������ �����
    for _, rf in ipairs(req_fields) do
      if r[rf] == nil then
        error('field expected: ' .. rf)
      end
    end

    -- �������� ������������ ���� ������
    if type_set[r.type] == nil then
      error('unknown record type: ' .. r.type)
    end

    -- �������� ������������ ��������� ������
    if state_set[r.state] == nil then
      error('unknown record state: ' .. r.state)
    end

    -- �������� ������� ����������� ��� ��������� ��������� ������
    if req_comment_state_set[r.state] ~= nil and r.comment == nil then
      error('comment expected for state: ' .. r.state)
    end
  end
end

-- html generator

local html_fields = {
  "type", "date", "from", "to", "content", "state", "comment"
}

local titles = {
  type = "Type", 
  date = "Date", 
  from = "From", 
  to = "To", 
  content = "Content", 
  state = "State",
  comment = "Comment", 
}

local function mkhtml( data, fname, mode )
  io.output(fname)

  html.write_header()
  io.write('<table border=1 width=100%>\n')

  io.write('<tr>')
  for _, f in ipairs(html_fields) do
    io.write('<td><b>' .. titles[f] .. '</b></td>')
  end
  io.write('</tr>\n')

  for _, r in ipairs(data) do
    if (mode == 'all') or (not mode and r.state=='active') then
      io.write('<tr>')
      for _, f in ipairs(html_fields) do
        local ss = (r[f] and tostring(r[f])) or '&nbsp;'
        io.write('<td>' .. ss .. '</td>')
      end
      io.write('</tr>\n')
    end
  end

  io.write('</table>\n')
  html.write_trailer()
end

-- export

function rcs( data, pname, mode )
  validate(data)
  mkhtml(data, pname .. '.htm', mode)
end
