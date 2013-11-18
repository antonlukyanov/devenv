--[[
  Разбирает лог-файл llogsrv и формирует отформатированный лог,
  фильтруя сообщения в соответствии с их "аспектом".

  Фильтрация задается таблицей аспектов, которую должен возвращать скрипт,
  размещенный в файле с именем 'llogopt' в текущей директории.
  В этой таблице для каждого аспекта задается значение true или false,
  определяющее, будет ли сообщение выведено в генерируемый лог.
  Если сообщение не имеет аспекта, то ему соответствует пустой аспект
  (именем аспекта является пустая строка).
  Если для некоторого сообщения его аспект не был явно указан в таблице
  аспектов, то вывод такого сообщения в лог управляется значением
  элемента таблицы аспектов с индексом 1.

  В конце отформатированного лога перечисляются все аспекты, встретившиеся
  при разборе данного лога (кроме пустого аспекта).
  Для каждого аспекта выводится значение (on/off), взятое из таблицы
  аспектов или слово default, если аспект отсутствует в этой таблице.
--]]

logopt = {
  ['lwml:mem'] = false,
  ['lwml:dload'] = false,
  ['lwml:dump'] = false,
  ['lwml:io'] = false,

  ['llogsrv:cwd'] = true,
  ['lwml:config'] = true,
  ['lwml:console'] = true,
  ['lwml:luaconf'] = true,
  ['limcov'] = true,
  true
}

extopt = loadfile('llogopt')
if extopt then
  local opt = extopt()
  for k, v in pairs(opt) do
    logopt[k] = v
  end
end

require "libcsv"

if #arg ~= 1 then
  io.write('Usage: lua llog.lua logfile\n')
  os.exit()
end

file = arg[1]

debt = {}      -- стек отложенных изменений контекста
depth = 0      -- глубина напечатанного контекста
ctx = {}       -- стек полного текущего контекста
aspects = {}   -- список встретившихся аспектов

function parse( s )
  local t = csv.parse(s)
  aspects[t[3]] = true
  return  {
    thr = t[1],
    tm = t[2],
    asp = t[3],
    msg = t[4]
  }
end

function pr_msg( msg, tm, thr, asp )
  local ind = string.rep(':   ', depth)
  io.write(ind, msg)
  if asp and asp ~= '' then
    io.write(' [' .. asp .. ']')
  end
  io.write('\n')
end

for s in io.lines(file) do
  local rec = parse(s)
  if rec.asp == '>>>' then
    table.insert(debt, rec)
    table.insert(ctx, rec)
  elseif rec.asp == '<<<' then
    local cc = table.remove(ctx)
    if #debt ~= 0 then
      table.remove(debt)
    else
      depth = depth - 1
      pr_msg('< ' .. cc.msg, rec.time, rec.thread)
    end
  else
    local asp = rec.asp
    if (logopt[asp] ~= nil and logopt[asp]) or (logopt[asp] == nil and logopt[1]) then
      for _, d in ipairs(debt) do
        pr_msg('> ' .. d.msg, d.time, d.thread)
        depth = depth + 1
      end
      debt = {}
      pr_msg(rec.msg, rec.time, rec.thread, asp)
    end
  end
end

io.write('\n--\naspects:\n')
for asp, v in pairs(aspects) do
  if asp ~= '' and asp ~= '<<<' and asp ~= '>>>' then
    local v = logopt[asp]
    local vt = (v~=nil and (v and "on" or "off") or "default")
    io.write('  ', asp, ': ', vt, '\n')
  end
end
io.write('--\n')
