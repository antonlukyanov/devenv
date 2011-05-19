--[=[

  ver. 1.02, 2005.01.08

  -- �������� ����� ������ ������ ��� ������, ���������� �� �����

  ver. 1.03, 2005.01.09

  -- ������ ��������� ����������
  -- ������� ��������� ������ � �����������

  ver. 1.04, 2006.06.05

  -- ���������� ������ ����� ���������� ������
  -- ��������� ��������� � ����

  ver. 1.05, 2008.08.11

  -- ��������� ����������� ������������� ��������-������ � ������� mimeTeX (������� .tex)

  ver. 1.06, 2008.09.09

  -- �������� ��������� ��������� ��������
  -- ������ ������� ������������ ������ HTML ('!')
  -- ������ ������� �������� ������� ������ ('///')
  -- ������ ����������� ������� '.-'
  -- ������� clear ������������� � end
  -- ������ ������� hline
  -- ��������� ������� note
  -- ��������� ��������� ������� TeX � inline-������ (������ $$$...$$$)
  -- �������� ��������� ������� tex (������ ��� ���������� outline-�������).

  ver. 1.07, 2009.01.16

  -- ��������� ��������� ������ �� ��������� ���������
  -- ���������� � ������������� � �������� ������ � ������� ������� ������������� ������ ������������

  ver. 1.08, 2009.12.02

  -- ��������� ��������������� ������ �� lht-����� � ������ �� htm-�����
  -- ������� ��������� ��� ������ �� ��������� ���������

  ver. 1.09, 2010.09.18 [r.4352]

  -- ��� �������������� ����������� ������� ����� �������������� �������� �� �����, ����� �������� ����� � CSS
  -- � ������� code ������ ������������� ������ (����� ������������ CSS)
  -- ���������� ��������� ����� (�������� ��������� �� ������ ��� �������� ������� .note, ������ �������� ��� body)
  -- � �������� .cite � .epi �������� ��������, ����������� ������ ���������

  ver. 1.10, 2010.09.20

  -- ������ ������� .www
  -- ������ ��� ��������� ����������� ������������������ {{{ }}}
  -- � ���������� ������������������� {{{ }}} � [[[ ]]] ���������� ������� ������ ������

  ver. 1.11, 2010.09.20

  -- ��� ������ ��������� ��������� ��������, ���������� � html

  ver. 1.12, 2010.09.21

  -- � ����������� ������� ��������� ������� �� ������� � �����
  -- �������� ����� ���� � ����������

--]=]

require "libwaki"
require "libfname"

-- ������������ ���������

local dst_ext = '.htm'

local charset = 'windows-1251'
local copyleft = "automatically generated by luaht, (c) ltwood, 2004--2010"
local footer = string.format('<p><hr><center><font size=1 color=#cccccc>%s</font></center>', copyleft)

-- ��������� �������

local line_number = 0            -- ����� �������������� ������

function alert( msg )   -- ���������� �� ������
  io.stderr:write(string.format('error in line %d: %s\n', line_number, msg))
  os.exit(1)
end

local outfile = nil

local function printf(fmt, ...)  -- ��������� ����� ������
  return outfile:write(string.format(fmt, ...)..'\n')
end

-- base64 support for inline tex
-- http://lua-users.org/wiki/BaseSixtyFour
-- http://en.wikipedia.org/wiki/Base64
--
-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2
--
-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
--
-- encoding
function base64_enc( data )
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
-- end of base64 support

-- mimeTeX support

local inline_tex = false
local tex_idx = 0
local tex_expr = ''

function new_tex() tex_expr = '' end
function add_tex( expr )
  if tex_expr == '' then
    tex_expr = expr
  else
    tex_expr = tex_expr .. '\n' .. expr
  end
end

local function proc_tex( expr )
  if not expr then expr = tex_expr:gsub('\n', ' ') end

  if inline_tex then
    local img_name = '.' .. os.tmpname() .. 'tmp'
    os.execute(string.format('mimetex.exe -e %s "%s"', img_name, expr))
    local file = io.open(img_name, 'rb')
    local data = base64_enc(file:read('*all'))
    file:close()
    os.remove(img_name)
    return string.format('<img src="data:image/gif;base64,%s">', data)
  else
    tex_idx = tex_idx + 1
    local img_name = string.format('mime_%04d.gif', tex_idx)
    os.execute(string.format('mimetex.exe -e %s "%s"', img_name, expr))
    return string.format('<img src="%s">', img_name)
  end
end

-- multiarg support

function parse_arg( arg, delim, def_val )
  local arg1, arg2 = arg, def_val
  local pos = arg:find(delim, 1, true)
  if pos then
    arg1 = arg:sub(1, pos-1)
    arg2 = arg:sub(pos+2, -1)
  end
  return arg1, arg2
end

-- reference support

function proc_www( arg )
  local ref, text = parse_arg(arg, '}{', '[extref]')
  return string.format('<a href="http://%s">%s</a>', ref, text)
end

local ref_tbl = {}

function proc_ref( arg )
  local ref, text = parse_arg(arg, '][', '[ref]')
  table.insert(ref_tbl, ref)
  local reft = fname.split(ref)
  if reft.ext == '.lht' then
    ref = fname.merge(reft.dir, reft.name, dst_ext)
  end
  return string.format('<a href="%s">%s</a>', ref, text)
end

-- ���� ������.
-- �������� ���������� ������� � ��������, ����������� ��� ����������
-- �������� ��������� ����.
-- ������������� �������� ����� ������, ���������� ������������� ���, � ��� ���.

local stack = { n = 0 }

function stack:push( nm, tg, act )
  self.n = self.n + 1
  self[self.n] = { name = nm, tag = tg, action = act, lnum = line_number }
end

function stack:pop()
  if self.n == 0 then
    alert"stack empty"
  end
  local val = self[self.n]
  self[self.n] = nil
  self.n = self.n - 1
  if val.action then
    val.action()
  end
  return val.tag
end

function stack:test()
  if self.n ~= 0 then
    for j = 1, self.n do
      io.stderr:write(string.format("note: end of <%s> (line %d) expected\n", tostring(self[j].name), self[j].lnum))
    end
    alert'command stack not empty!'
  end
end

-- ��������� �������

local do_wait_par = true      -- �������� ������ ���������

--[[
  �� ������ ������ ���������� ����� �������� ������ ������ (������� set_par()).
  � ������ �������� ������ ������ ������ ����������� <p> � ���������� ���������
  �������� (����� ������� test_par() � ������� proc_str()).
  ��� �� �������� ������� img ������� ������ ��������� �������� ������.
  ��������� ������� (�������� ���������) ������������� �������� ����� �������� ������.
  �������, ������������� ��� � ������� �� ���� ���-�����������, ������
  ���������� ��������� �������� ������ (������� clear_par()).
  �������-����������� (cmd_end()) ������ �������� ��������� ��������.
--]]

local function test_par()
  if do_wait_par then
    printf'<p>'
    do_wait_par = false
  end
end

local function set_par()
  do_wait_par = true
end

local function clear_par()
  do_wait_par = false
end

local is_code = false

-- �����������

local function subs_symb( s )
  -- ������� ����� �������� ����� ��������!
  s = s:gsub("%&", "&amp;")                                     -- &
  if not is_code then
    s = s:gsub("%<%<%<", "&laquo;");                            -- <<<
    s = s:gsub("%>%>%>", "&raquo;");                            -- >>>
  end
  s = s:gsub("%<", "&lt;")                                      -- <
  s = s:gsub("%>", "&gt;")                                      -- >
  if not is_code then
    s = s:gsub("%-%-%-", "&nbsp;&mdash;&nbsp;")                 -- ---
    s = s:gsub("%_%_%_(.-)%_%_%_", "<i>%1</i>")                 -- ___
    s = s:gsub("%*%*%*(.-)%*%*%*", "<b>%1</b>")                 -- ***
    s = s:gsub("%~%~%~(.-)%~%~%~", "<code>%1</code>")           -- ~~~
    s = s:gsub("%#%#%#(.-)%#%#%#", "<strike>%1</strike>")       -- ###
    s = s:gsub("%$%$%$(.-)%$%$%$", proc_tex)                    -- $$$
    s = s:gsub("%[%[%[(.-)%]%]%]", proc_ref)                    -- [[[ref]]]
    s = s:gsub("%{%{%{(.-)%}%}%}", proc_www)                    -- {{{url}}}
  end
  return s
end

-- �������

local function cmd_hdr_templ( text, level )
  printf('<h%d>%s</h%d>', level, subs_symb(text), level)
  set_par()
end

cmd_title = function(arg) cmd_hdr_templ(arg, 1) end
cmd_sect  = function(arg) cmd_hdr_templ(arg, 2) end
cmd_subs  = function(arg) cmd_hdr_templ(arg, 3) end
cmd_para  = function(arg) cmd_hdr_templ(arg, 4) end

function cmd_enum()
  printf'<ol>'
  clear_par()
  stack:push('enum', '</ol>')
end

function cmd_list()
  printf'<ul>'
  clear_par()
  stack:push('list', '</ul>')
end

function cmd_item()
  printf'<li>'
  clear_par()
end

function cmd_defl()
  printf'<dl>'
  clear_par()
  stack:push('defl', '</dl>')
end

function cmd_def( term )
  printf('<dt>%s', subs_symb(term))
  printf'<dd>'
  clear_par()
end

function cmd_note()
  printf'<blockquote class="note">'
  clear_par()
  stack:push('note', '</blockquote>')
end

function cmd_cite( author )
  printf'<blockquote class="cite">'
  clear_par()
  if author then
    stack:push('cite', '<br>//&nbsp;' .. author .. '</blockquote>')
  else
    stack:push('cite', '</blockquote>')
  end
end

function cmd_sic()
  printf'<blockquote class="sic">'
  clear_par()
  stack:push('sic', '</blockquote>')
end

function cmd_epi( author )
  printf'<blockquote class="epi">'
  clear_par()
  if author then
    stack:push('epi', '<br>//&nbsp;' .. author .. '</blockquote>')
  else
    stack:push('epi', '</blockquote>')
  end
end

function cmd_code()
  printf'<pre class="code">'
  clear_par()
  is_code = true;
  stack:push('code', '</pre>', function() is_code = false end)
end

function cmd_img( file )
  test_par()
  printf('<img src="%s">', file)
end

function cmd_fig( file )
  printf('<p><center><img src="%s"></center>', file)
  printf'<center><b><i>'
  clear_par()
  stack:push('fig', '</i></b></center>')
end

function cmd_end()
  local fin = stack:pop()
  if fin and fin ~= '' then
    printf("%s", fin)
  end
  set_par()
end

function cmd_tex()
  clear_par()
  is_tex = true;
  new_tex()
  stack:push('tex', '', function() printf("<p>%s", proc_tex()); is_tex = false end)
end

-- ��������� �������.
-- � ����� ������� ����� ����������� ������� 'cmd_'
-- � ������������ ������� ������ ���������� �������.
-- ��� ������� ������ ����������� ������ � ������� �����������.

local function proc_cmd( cmdl )
  if cmdl:match("^%.%s*$") then
    cmd_end()
    return
  end

  -- ��������� ������� � ��������� ������� '\'
  cmdl = "cmd_" .. cmdl:gsub('\\', '\\\\')
  local cmd = loadstring(cmdl)
  if cmd then
    cmd()
  else
    cmd = loadstring(cmdl .. "()")
    if cmd then
      cmd()
    else
      alert("can't call command <" .. cmdl .. ">")
    end
  end
end

-- ��������� ���������� �����

local function proc_str( str )
  test_par()
  printf("%s", subs_symb(str))
end

local function proc_empty_str()
  set_par()
end

-- ������ ������� '�����' ������

-- ������ .code ��������� ���������� ������ �� '..' � ������ �������
-- � ������� ������������, �� ������������ ������ ��������.
-- � ���������� ������ �������������� ������� ������, ������ ������,
-- �������, ����������� � todo-�����������.
-- ������� ������� ����� �����, ������� ���� �� ������ � �������.

local function proc_line( line )
  -- ����������� ��������� ������ .code
  if is_code then
    if line:sub(1, 2) == '..' then
      cmd_end()
    else
      printf("%s", subs_symb(line))
    end
    return
  end

  -- ����������� ��������� ������ .tex
  if is_tex then
    if line:sub(1, 2) == '..' then
      cmd_end()
    else
      add_tex(line)
    end
    return
  end

  -- ���������� �����
  line = line:match("^%s*(.*)$") -- ���������� ������� �������
  if line == "" then
    proc_empty_str()            -- �������� ������������ ������ ������
  else
    local ch = line:sub(1, 1)
    if ch == "." then           -- �� ����� ������������ �������
      proc_cmd(line:sub(2))
    elseif ch == "#" then       -- ���������� �����������
      -- �� �������� ������ todo-������������
      if line:sub(2, 2) == "!" then
        io.stderr:write(waki.recode(line, 'wa') .. '\n')
      end
    else                        -- ������� ���������� ������
      proc_str(line)
    end
  end
end

-- ��������� � ��������

local style = [[
  body {
    background-color: #e7e9dc;
    font-family: arial;
    margin-left: 3%; margin-right: 3%;
    text-align: justify;
    line-height: 125%;
  }
  h1 { color: #4e4f43; }
  h2 { color: #4e4f43; }
  h3 { color: #4e4f43; }
  h4 { color: #4e4f43; }
  code {
    font-size: 125%;
  }
  blockquote.sic {
    background-color: #dddddd;
    border: 1px dashed #aaaaaa;
    padding: 3px;
    font-weight: bold;
    font-size: 90%;
    line-height: 120%;
  }
  blockquote.note {
    background-color: #dddddd;
    border: 1px dashed #aaaaaa;
    padding: 3px;
    font-size: 90%;
    line-height: 120%;
  }
  blockquote.cite {
    background-color: #dddddd;
    border: 1px dashed #aaaaaa;
    padding: 3px;
    font-style: italic;
    font-size: 90%;
    line-height: 120%;
  }
  blockquote.epi {
    margin-left: 50%;
    margin-right: 0%;
    border: 1px dashed #aaaaaa;
    padding: 3px;
    background-color: #dddddd;
    font-style: italic;
    font-weight: bold;
    font-size: 90%;
    line-height: 120%;
  }
  pre.code {
    background-color: #dddddd;
    border: 1px dashed #aaaaaa;
    padding: 3px;
    font-size: 90%;
    line-height: 120%;
  }
]]

local function print_header( fn )
  local id = fn .. '-' .. os.date('%Y.%m.%d-%H:%M:%S')
  printf'<html>'
  printf'<!-- automatically generated by luaht, (c) ltwood, 2004--2010 -->'
  printf'<head>'
  printf('<meta http-equiv="Content-Type" content="text/html; charset=%s">', charset)
  printf('<title>%s</title>', id)
  printf'</head>'

  printf('<style type="text/css">')
  printf('%s</style>', style)

  printf('<body>')
end

local function print_footer()
  printf("%s", footer)
  printf'</body>'
  printf'</html>'
end

-- ������������� �����������

local function generate_html( src, inline )
  inline_tex = inline
  local fnt = fname.split(src)
  local dst = fname.merge(fnt.dir, fnt.name, dst_ext)

  ref_tbl = {}
  outfile = assert(io.open(dst, "wt"))
  print_header(src)
  line_number = 1
  for s in io.lines(src) do
    proc_line(s)
    line_number = line_number + 1
  end
  print_footer()
  stack:test()
  return ref_tbl
end

luaht = {
  proc = generate_html
}

-- main

if not package.loaded['luaht'] then
  require "libcmdl"
  local opt = cmdl.options()

  -- ������ ���� ���� �������� - ��� �����
  if #arg ~= 1 then
    io.stderr:write("html generator, ver 1.12, (c) ltwood\n")
    io.stderr:write("usage: luaht [-i] lht-file-name\n")
    os.exit(1)
  end
  generate_html(arg[1], opt['-i'])
else
  return luaht
end
