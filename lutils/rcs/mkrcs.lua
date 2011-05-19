--[[
  —оздание файла управлени€ требовани€ми.
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

  ѕоле <comment> об€зательно только при STATE = 'frozen' or 'transfered'

  —мысл состо€ни€ 'frozen':
    STATE = 'request'        отказ от требовани€
    STATE = 'bug'            отсутствие бага
    STATE = 'decision'       ???

  —лучаи трансфера требовани€:
    детализаци€ требовани€ (разбиение на более мелкие)
    изменение типа записи (например 'bug' -> 'decision')
    изменение адресата
--]]

]==]

io.write(string.format('rcs(data, "__%s", arg[1])\n', name))
