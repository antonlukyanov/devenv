--[[
  ѕреобразование между русскими кодировками
--]]

require "libwaki"

if #arg ~= 2 then
  io.write('Usage: lua waki.lua conv\n')
  io.write("  where 'conv' may be 'ia', 'ka', 'wa', 'ai', 'ak', 'aw', 'ik', 'wk', 'ki', 'kw', 'iw', 'wi'\n")
  io.write("  where 'i'=ISO-8859-5, 'k'=KOI8-R, 'w'=Windows-1251, 'a'=Alternative-DOS\n")
  os.exit()
end

file = assert(io.open(arg[1], "rt"))
data = file:read("*all")
file:close()

io.write(waki.recode(data, arg[2]))
