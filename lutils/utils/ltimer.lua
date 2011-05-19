--[[
  ¬ыполн€ет команду и выводит врем€ ее выполнени€.
--]]

if #arg < 1 then
  io.write('Usage: lua ltimer.lua command ...\n')
  os.exit()
end

cmd = arg[1]
for j = 2, #arg do
  cmd = cmd .. ' ' .. arg[j]
end

io.write('>' .. cmd .. '\n')
t1 = os.clock()
os.execute(cmd)
t2 = os.clock()

dt = t2-t1
dtm = math.floor(dt / 60)
dts = math.fmod(dt, 60)

io.write('ltimer: ', dt, ' (', dtm, "'", dts, '")\n')
