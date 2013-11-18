--[[
  Библиотека эмуляции функциональности awk.
--]]

local line = ""

-- Проверяет, соответствует ли строка str шаблону pat.
-- Если передан один аргумент, то в качестве строки используется
-- текущая строка, прочитанная из входного потока.
local function is( pat, str )
  if not str then
    str = line
  end
  return (string.find(str, pat)) ~= nil
end

-- Построчно обрабатывает входной поток, разбивая каждую строку на поля,
-- соответствующие шаблону pat и вызывая функцию func.
-- Функции  func передается таблица значений полей и номер текущей строки.
-- В таблице поля нумеруются с единицы, по нулевому индексу содержится входная строка.
-- Если передан один аргумент, то используется шаблон, соответствующий разбиению
-- строки на слова, состоящие из непробельных символов.
local function run( func, pat )
  if not pat then
    pat = '%S+'
  end

  local ln = 1
  for s in io.lines() do
    local fl = {}
    fl[0] = s
    line = s
    local fn = 0
    for ss in string.gmatch(s, pat) do
      fn = fn + 1
      fl[fn] = ss
    end
    func(fl, ln)
    ln = ln + 1
  end
end

awk = {
  is = is,
  run = run,
}

return awk
