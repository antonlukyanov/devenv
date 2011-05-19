--[[
  Преобразует файл в формате CSV в таблицу в формате HTML
--]]

require "libcsv"
require "libhtml"

local empty_text = '&nbsp;'

if #arg ~= 1 and #arg ~= 2 then
  io.write('Usage: lua csv2html.lua filename [delimiter]\n')
  os.exit()
end

delim = arg[2] or ','
io.input(arg[1])

html.write_header()
io.write('<table border=1>\n')

j = 0
for s in io.lines(arg[1]) do
  j = j + 1
  t = csv.parse(s, delim)
  if not t then
    io.stderr:write('error in line ', j, '\n')
    os.exit()
  end
  io.write('<tr>')
  for _, f in ipairs(t) do
    f = ((f=="") and empty_text) or f
    io.write('<td>' .. f .. '</td>')
  end
  io.write('</tr>\n')
end

io.write('</table>\n')
html.write_trailer()
