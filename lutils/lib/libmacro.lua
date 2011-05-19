--[[
  Наиболее употребительные варианты макроподстановки.
--]]

-- Макроподстановка для макросов-имен.
-- В строке s заменяет все вхождения ${name} на t["name"].
-- Для результирующей строки замена выполняется рекурсивно.

local function subst( s, t )
  local function fn( x )
    local nm = x:sub(2, -2)
    local res = assert(t[nm], "can't find name <" .. nm .. "> in lookup table")
    return res
  end

  local num
  repeat
    s, num = s:gsub("$(%b{})", fn)
  until num == 0
  return s
end

-- Макроподстановка для макросов-функций

-- В строке s производится поиск команд вида \cmd{arg}.
-- Затем для каждой команды производится поиск в таблице ctx.
-- Отсутствие команды в таблице считается ошибкой.
-- Если в таблице нашлась функция, то она вызывается с аргументом arg.
-- Эта функция должна возвратить строку, на которую будет заменена команда.
-- Возвращаемое функцией значение nil трактуется как пустая строка.
-- Дополнительно функция может возвратить флаг завершенности обработки (boolean).
-- Если возвращен истинный флаг завершенности обработки, то возвращаемое функцией
-- значение не обрабатывается рекурсивно.
-- Если в таблице нашлась строка, то она замещает собой команду.
-- При этом проверяется, что аргумент пустой, иначе генерируется ошибка.
-- К результату строковой подстановки всегда применяется рекурсивная обработка.
-- Функция pref_proc применяется ко всем строкам, уже не содержащим команд,
-- кроме строк, полученных в результате выполнения команды, вернувшей
-- флаг завершенности обработки.

local function func( s, ctx, pref_proc )
  local pref, cmd, arg, postf = s:match('^(.-)$(%w+)(%b{})(.*)$')
  if pref then
    pref = (pref_proc and pref_proc(pref)) or pref
    local arg = arg:sub(2, -2)
    local act = assert(ctx[cmd], "can't find command <\\" .. cmd .. "> in lookup table")
    if type(act) == 'function' then
      cmd, is_done = act(arg)
      cmd = cmd or ''
      if not is_done then
        cmd = func(cmd, ctx, pref_proc)
      end
    else
      if arg ~= '' then
        error("incorrect argument for string substitution")
      end
      cmd = func(act, ctx, pref_proc)
    end
    return pref .. cmd .. func(postf, ctx, pref_proc)
  else
    return (pref_proc and pref_proc(s)) or s
  end
end

macro = {
  subst = subst,
  func = func,
}

return macro
