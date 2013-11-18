--[[
  Функции-утилиты для тестирования
--]]

local verbose = false  -- флаг диагностики для успешно пройденных тестов

-- test engine

local test_name = nil

local function ___test_fn( fn )
  test_name = fn
end

local fail_num = 0

local function __( res, name )
  if name == nil then
    name = test_name
  else
    name = test_name .. '#' .. name
  end
  if res then
    if verbose then
      print(name .. ': Ok')
    end
  else
    print(name .. ': fail')
    fail_num = fail_num + 1
  end
end

local function __t( res, tbl, name )
  local is_ok = true
  for j, v in pairs(res) do
    if tbl[j] ~= v then
      is_ok = false
    end
  end

  for j, v in pairs(tbl) do
    if res[j] ~= v then
      is_ok = false
    end
  end

  __(is_ok, name)
end

local function ___sum()
  if verbose then
    print("--")
  end
  if fail_num == 0 then
    print("Ok")
  else
    print("Fail")
  end
end

local function ptbl( t )
  for j, v in pairs(t) do
    print('<'..j..'>', '<'..v..'>')
  end
end

__t = {
  test_fn = ___test_fn,
  __ = __,
  __t = __t,
  sum = ___sum,
  ptbl = ptbl
}

return __t
