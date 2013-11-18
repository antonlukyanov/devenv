--[[
  Скрипт для запуска утилиты wget
  -------------------------------
    -t0 бесконечные попытки
    -i  брать список из файла
    -r  рекрсивно
    -l0 глубина рекурсии
    -k  преобразование ссылок в локальные
    -np не подниматься вверх
    -c  с докачкой
--]]

if #arg ~= 2 then
  io.write("Usage: lua tp.lua action URL\n")
  io.write("action:\n")
  io.write("  file - download one files\n")
  io.write("  list - download list of files\n")
  io.write("  tree - download whole subtree\n")
  os.exit()
end

if arg[1] == "file" then
  -- бесконечно + докачка
  os.execute("wget -t0 -c " .. arg[2])
elseif arg[1] == "list" then
  -- бесконечно + докачка + список из файла
  os.execute("wget -t0 -c -i " .. arg[2])
elseif arg[1] == "tree" then
  os.execute("wget -t0 -r -l0 -k -np " .. arg[2])
else
  io.write("error: unknown action")
end
