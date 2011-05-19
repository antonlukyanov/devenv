--[[
  Корректный запуск IE.
  Работает только с относительными путями.
--]]

require "lfs"

local function run( fn )
  os.execute('start iexplore "' .. lfs.currentdir() .. '/' .. fn .. '"')
end

iexplorer = {
  run = run
}

return iexplorer
