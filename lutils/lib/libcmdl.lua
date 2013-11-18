--[[
  Получение опций командной строки.
  Возвращает таблицу с опциями, удаляя их из командной строки.
  Для опции '-tval' запись в таблице имеет вид ['-t'] = 'val'.
--]]

local function options()
  local opt = {}
  local j = 1
  while j <= #arg do
    if arg[j]:match('^%-%a') then
      opt[arg[j]:sub(1, 2)] = arg[j]:sub(3)
      table.remove(arg, j)
    else
      j = j + 1
    end
  end
  return opt
end

cmdl = {
  options = options
}

return cmdl
