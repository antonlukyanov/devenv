--[[
  Генерация html -- простые утилиты.
--]]

local function write_header( charset )
  charset = charset or 'windows-1251'

  io.write('<html>\n')
  io.write('<head>\n')
  io.write(string.format('<meta http-equiv="Content-Type" content="text/html; charset=%s">\n', charset))
  io.write('</head>\n')
  io.write('<body>\n')
end

local function write_trailer()
  io.write('</body>\n')
  io.write('</html>\n')
end

html = {
  write_header = write_header,
  write_trailer = write_trailer,
}

return html
