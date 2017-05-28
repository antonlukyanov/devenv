-- fun.lua, 2016, (c) Anton Lukyanov

--- Functional programming. Sort of.

local fun = {}

function fun.each(tbl, f)
  for k, v in pairs(tbl) do
    f(v, k, tbl)
  end
  return tbl
end

function fun.map(tbl, f)
  new_tbl = {}
  for k, v in pairs(tbl) do
    new_tbl[k] = f(v, k, lst)
  end
  return new_tbl
end

function fun.reduce(tbl, f, acc)
  for k, v in pairs(tbl) do
    acc = f(acc, v, k, tbl)
  end
  return acc
end

function fun.keys(tbl)
  local keys = {}
  for k, _ in pairs(tbl) do
    table.insert(keys, k)
  end
  return keys
end

function fun.filter(tbl, predicate)
  local new_lst = {}
  for k, v in pairs(tbl) do
    if predicate(v, k) then
      new_lst[k] = v
    end
  end
  return new_lst
end

function fun.extend(dst, ...)
  for _, tbl in ipairs({...}) do
    for k, v in pairs(tbl) do
      dst[k] = v
    end
  end
  return dst
end

function fun.join(tbl, sep, i, j)
  return table.concat(tbl, sep or '', i, j)
end

--
-- Reinventing support for chaining. Here comes the real fun
--

local realfun = {__index = fun}

local function wrap(value)
  return setmetatable({
    __value = value,
    __realfun = true
  }, realfun)
end

setmetatable(realfun, {
  __index = function(tbl, key)
    return fun[key]
  end,
  __call = function(self, value)
    return wrap(value)
  end
})

function realfun.chain(v)
  return wrap(v)
end

function realfun:value()
  return self.__value
end
  
for fname, func in pairs(fun) do
  fun[fname] = function(obj, ...)
    if type(obj) == 'table' and obj.__realfun then
      -- Wrapping again and again is necessary because we do not want object to change itself. E.g.:
      -- 
      -- obj.__value = func(obj.__value, ...)
      -- return obj
      -- 
      -- But:
      -- local x = fun({1, 2, 3})
      -- x:reduce(...) -- x is changed
      -- x:map(...)    -- x may not contain table
      return wrap(func(obj.__value, ...))
    else
      return func(obj, ...)
    end
  end
end

fun.chain = realfun.chain
fun.value = realfun.value

return realfun