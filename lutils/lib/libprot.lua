--[[
  Выполнение файла в защищенном окружении
--]]

local function run( fname, exp )
  local func = assert(loadfile(fname))        -- загружаем файл как функцию
  local env = { }                             -- создаем таблицу-окружение
  if exp then                                 -- экспортируем функции из списка экспорта
    for f_nm, f_fn in pairs(exp) do
      env[f_nm] = f_fn
    end
  end
  setmetatable(env, {__index = _G})           -- даем из нее доступ к стандартным библиотекам
  setfenv(func, env)                          -- назначаем ее как окружение для функции
  func()                                      -- выполняем функцию
  return env
end

prot = {
 run = run
}

return prot
