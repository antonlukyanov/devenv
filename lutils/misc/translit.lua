--[[
  Транслитерация файла
  Исходный файл должен быть в кодировке cp1251
--]]

require "libwaki"

if #arg ~= 1 then
  io.write('Usage: lua translit.lua file\n')
  os.exit()
end

-- таблица соответствует стандартной таблице транслитерации
-- за исключением добавленных в нее букв 'ь', 'ъ', которые
-- по стандартной таблице пропускаются и буквы 'ё',
-- отсутствующей в стандартной таблице
tr = {
  ["а"] = "a",     ["б"] = "b",     ["в"] = "v",     ["г"] = "g",
  ["д"] = "d",     ["е"] = "e",     ["ж"] = "zh",    ["з"] = "z",
  ["и"] = "i",     ["й"] = "j",     ["к"] = "k",     ["л"] = "l",
  ["м"] = "m",     ["н"] = "n",     ["о"] = "o",     ["п"] = "p",
  ["р"] = "r",     ["с"] = "s",     ["т"] = "t",     ["у"] = "u",
  ["ф"] = "f",     ["х"] = "h",     ["ц"] = "ts",    ["ч"] = "ch",
  ["ш"] = "sh",    ["щ"] = "shch",  ["ъ"] = "'",     ["ы"] = "y",
  ["ь"] = "'",     ["э"] = "e",     ["ю"] = "yu",    ["я"] = "ya",
  ["ё"] = "e",
}

file = assert(io.open(arg[1], "rb"))
data = file:read("*all")
file:close()
len = #data

for s in io.lines(arg[1]) do
  for j = 1, #s do
    ch = s:sub(j, j)
    lch = waki.lower(ch, 'win')
    if tr[lch] then
      if lch ~= ch then
        io.write(tr[lch]:upper())
      else
        io.write(tr[lch])
      end
    else
      io.write(ch)
    end
  end
  io.write('\n')
end
