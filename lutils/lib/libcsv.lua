--[[
  ‘ункции дл€ работы с файлом в формате CSV
--]]

local function escapeCSV( s, delim )
  s = tostring(s) -- могут быть переданы нестроковые данные
  if s:find('[' .. delim .. '"' .. ']') then
    s = '"' .. s:gsub('"', '""') .. '"'
  end
  return s
end

--[[
  ѕреобразует пол€ таблицы t, проиндексированные целыми числами от 1,
  в строку в формате CSV.
  ѕол€, содержащие зап€тые или кавычки, сами заключаютс€ в кавычки,
  а кавычки присутствующие в исходной строке, удваиваютс€.
  ѕоскольку многие программы используют в качестве разделител€ ';'
  вместо ',' во втором аргументе можно указать разделитель полей.
--]]

local function wrapCSV( t, delim )
  delim = delim or ','
  local s = ""
  for _, p in pairs(t) do
    s = s .. delim .. escapeCSV(p, delim)
  end
  return s:sub(2) -- remove first comma
end

--[[
  –азбивает строку s на пол€ в соответствии с правилами формата
  CSV и возвращает таблицу, проиндексированную целыми числами от 1.
  ѕол€ отдел€ютс€ зап€тыми и могут быть заключены в двойные кавычки
  (это необходимо дл€ экранировани€ зап€тых, если они содержатс€ в поле).
  ѕоле может быть пустым, начальные и конечные пробелы сохран€ютс€.
  ¬нутри кавычек могут идти зап€тые, не €вл€ющиес€ разделител€ми полей.
  ¬нутри кавычек символ двойной кавычки удваиваетс€.
  ≈сли зап€та€ стоит в конце строки, то считаетс€, что после нее
  идет пустое поле.
  ƒл€ пустой строки получаетс€ таблица, состо€ща€ из одного пустого пол€.
  ≈сли за закрывающейс€ кавычкой не следует зап€та€, то остаток строки
  до зап€той также добавл€етс€ к полю, причем он считаетс€ неэкранированным.
  ѕоскольку многие программы используют в качестве разделител€ ';'
  вместо ',' во втором аргументе можно указать разделитель полей.
--]]

local function parseCSV( s, delim )
  delim = delim or ','
  s = s .. delim -- ending comma
  local t = {} -- table to collect fields
  local fieldstart = 1
  repeat
    if s:find('^"', fieldstart) then -- quoted field
      local c
      local i = fieldstart
      repeat   -- find closing quote not followed by quote
        _, i, c = s:find('"("?)', i+1)
      until c ~= '"'
      if not i then return nil end
      local f = s:sub(fieldstart+1, i-1)
      local cpos = s:find(delim, i)
      fieldstart = cpos + 1
      table.insert(t, (f:gsub('""', '"')) .. s:sub(i+1, cpos-1))
    else -- unquoted; find next comma
      local nexti = s:find(delim, fieldstart)
      table.insert(t, s:sub(fieldstart, nexti-1))
      fieldstart = nexti + 1
    end
  until fieldstart > #s
  return t
end

csv = {
  wrap = wrapCSV,
  parse = parseCSV
}

return csv
