--[[
  Âñòàâêà ñèìâîëà öèòèğîâàíèÿ ('>')
  â êàæäóş ñòğîêó èñõîäíîãî ôàéëà
--]]

if #arg ~= 1 then
  io.write('Usage: lua quot.lua filename\n')
  os.exit()
end

fn = arg[1]

for s in io.lines(fn) do
  io.write("> " .. s .. "\n")
end
