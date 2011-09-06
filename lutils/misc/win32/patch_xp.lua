-- Скрипт исправляет установленную windows-xp, переименовывая содержащиеся в ней 
-- утилиты find и sort, совпадающие по имени с соответствующими утилитами из msys.
--
-- Скрипт необходимо запускать с правами администратора.
-- Через некоторое время после запуска система безопасности windows
-- предложит восстановать "правильные" версии переименованных файлов.
-- В этом диалоге нужно нажать кнопку Отмена/Cancel и подтвердить
-- свое решение, нажав Да/Ok в следующем диалоге.

windir = os.getenv('windir')

function run( cmd ) 
  return os.execute(cmd:gsub('\\', '/'))
end

run('rm ' .. windir .. '\\system32\\dllcache\\find.exe')
run('rm ' .. windir .. '\\system32\\dllcache\\sort.exe')

run('mv ' .. windir .. '\\system32\\find.exe ' .. windir .. '\\system32\\find.ex_')
run('mv ' .. windir .. '\\system32\\sort.exe ' .. windir .. '\\system32\\sort.ex_')
