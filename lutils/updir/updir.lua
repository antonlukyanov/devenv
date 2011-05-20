require "libcmdl"

opt = cmdl.options()

-- изменяем путь поиска бинарных библиотек
if not opt['-s'] then
  local interp = arg[0] -- верно только для скомпилированной версии
  interp = string.gsub(interp, '\\', '/')
  local path = interp:match('^(.*)/[^/]+%.[^/]+$')
  package.cpath = path .. '/?.dll'
end

require "libcsv"
require "libdir"
require "lfs"

function s_error( ... )
  local t = {...}
  local msg = ""
  for j, v in ipairs(t) do
    msg = msg .. v
  end
  io.stderr:write('*** ' .. msg .. '\n')
  os.exit(1)
end

function s_assert( val, msg )
  if val then
    return val
  else
    s_error(msg)
  end
end

local case_insens = true
if opt['-i'] then
  local v = tonumber(opt['-i'])
  if not v or (v ~= 0 and v ~= 1)then
    s_error('incorrect value for option -iNNN')
  end
  case_insens = (v ~= 0)
end
local case_sens = not case_insens

local copy_block_size = 8*1024*1024
if opt['-b'] then
  copy_block_size = tonumber(opt['-b'])
  if not copy_block_size or copy_block_size <= 0 then
    s_error('incorrect value for option -bNNN')
  end
  copy_block_size = math.floor(copy_block_size * 1024)
end

local sec_prec = 2
if opt['-p'] then
  sec_prec = tonumber(opt['-p'])
  if not sec_prec or sec_prec < 0 then
    s_error('incorrect value for option -pNNN')
  end
end

local dst_sens = true
if opt['-d'] then
  local v = tonumber(opt['-d'])
  if not v or (v ~= 0 and v ~= 1) then
    s_error('incorrect value for option -dNNN')
  end
  dst_sens = (v ~= 0)
end

local is_dst = os.date('*t').isdst
local dst_delta_t = ((dst_sens and is_dst) and 3600) or 0

usage = [[
updir: ver. 5.23, 1999 Jul, 2010 Dec, (c) ltwood

usage: lua updir.lua [-pNNN] [-iNNN] command prefix path

  -pNNN                  set time precision to NNN
  -iNNN                  set case insensitive flag to NNN (0/1)
  -dNNN                  set DST filesystem sentitivity to NNN (0/1)
  -s                     use system paths for shared library
  -bNNN                  set copy block size to NNN kb

    NTFS   is DST-sensitive filesystem
    FAT-xx is DST-insensitive filesystem
    DST = daylight saving time

  save                   DISK -> tree
  report                 tree, DISK -> report
  pack                   tree, DISK -> archive
  checkout               pack & save
  unpack                 archive -> DISK
  checkin                unpack & report
  extract                unpack file <path> from archive <prefix>_archive

  report = { {diff, type, name, size}, ... }
    diff = { {diff, type, name, time, attr, size, pos}, ... }
    tree = { {type, name, time, attr, size}, ... }
]]

--[[
  Version history:
    5.0    первая версия на lua
    5.01   независимость от регистра в именах файлов
    5.02   вывод размеров в diff-файл и упорядочение diff-файла по размеру
    5.03   работа с аттрибутами и 2-секундная точность при сравнении
    5.04   полная поддержка аттрибутов файлов
    5.05   bugfix'ы и изменения в диагностике
    5.06   сделана перекодировка имен файлов при выводе диагностики
    5.07   исправлена ошибка в функции вывода диагностических сообщений
    5.08   переход на использование библиотеки libdir вместо lib_tree
    5.09   поиск dll только в домашней директрии updir
    5.10   переход на использование расширений вместо суффиксов для файлов backup;
           добавлено переименование файлов diff и archive при операции commit;
           поддержана настройка параметров опциями командной строки
    5.11   исправлена ошибка, приводившая к невозможности операции checkin
           для файлов нулевой длины.
    5.12   bugfix: daylight saving time bug fixed
    5.13   Добавлена опция для управления чувствительностью файловой системы к DST.
    5.14   bugfix in bugfix: добавлена забытая коррекция времени при установке времени
           модификации файла; исправлена ошибка в обработке опции '-d'.
    5.15   добавлена опция -s, отключающая изменение пути поиска библиотек
    5.16   bugfix: загрузка библиотеки lfs производилась до смены пути поиска библиотек
    5.17   bugfix: libdir тоже загружает lfs, его тоже надо загружать после смены путей поиска
    5.18   поддержано поблочное чтение/запись больших файлов -- теперь они не читаются в память целиком
    5.19   добавлена поддержка прогресс-индикатора для операций упаковки и распаковки архива
           теперь при упаковке/распаковке архива и при выводе отчета вычисляется и выводится суммарный размер архива
           сообщения об ошибках теперь выводятся в файл <id>_log
    5.20   теперь прогресс-индикатор обновляется в процессе упаковки/распаковки файла
    5.21   упорядочена обработка ошибок -- фатальных и протоколируемых
    5.22   реализован вывод счетчика файлов в процессе сканирования файловой системы
    5.23   псевдографический прогресс-индикатор заменен на вывод процентов
--]]

if #arg ~= 3 then
  io.stderr:write(usage .. '\n')
  io.stderr:write("  current option values:\n")
  io.stderr:write("    case insensitive is " .. (case_insens and '<on>' or '<off>') .. '\n')
  io.stderr:write("    time precision is "..tostring(sec_prec) .. ' sec\n')
  io.stderr:write("    DST filesystem sensitivity is ".. (dst_sens and '<on>' or '<off>') .. '\n')
  io.stderr:write("    copy block size is "..tostring(math.floor(copy_block_size/1024)) .. ' kb\n')
  os.exit()
end

cmd = arg[1]
id = arg[2]
base_path = arg[3]

-- убираем завершающий слэш, если он задан
if string.sub(base_path, -1) == '/' or string.sub(base_path, -1) == '\\' then
  base_path = string.sub(base_path, 1, -2)
end

tree_fn = id .. '_tree'
report_fn = id .. '_report'
diff_fn = id .. '_diff'
archive_fn = id .. '_archive'
extract_fn = id .. '_extracted'
perror_fn = id .. '_log'

-- utils

function fnc( fn )
  return waki.recode(fn, 'wa')
end

function create_backup( fname )
  local attr = lfs.attributes(fname)
  if attr ~= nil and attr.mode == 'file' then
    local bak = fname .. '.bak'
    if lfs.attributes(bak) then
      s_assert(os.remove(bak), "can't remove old backup <" .. fnc(bak) .. ">")
    end
    s_assert(os.rename(fname, bak), "can't rename file <" .. fnc(fname) .. ">")
  end
end

local perror_count = 0
local perror_file = nil;

function perror( ... )
  if not perror_file then
    perror_file = io.open(perror_fn, 'wt');
  end
  local t = {...}
  local msg = ""
  for j, v in ipairs(t) do
    msg = msg .. v
  end
  perror_file:write("*** " .. msg .. "\n")
  perror_file:flush()
  perror_count = perror_count + 1
end

function flystr()
  local len = 0

  function out( s )
    if len > 0 then
      io.stderr:write(string.rep('\008', len))
      io.stderr:write(string.rep(' ', len))
      io.stderr:write(string.rep('\008', len))
    end
    io.stderr:write(s)
    len = #s
  end

  return {
    out = out,
  }
end

function progress( len )
  local scr = flystr()
  local last = 0

  local function up( st )
    local str = string.format("%.0f%%", 100 * st/len)
    if str ~= last then
      scr.out(str)
      last = str
    end
  end

  local function done()
    scr.out('')
    scr.out('Ok')
    scr = nil
    io.stderr:write('\n')
  end

  local function s_assert( val, msg )
    if val then
      return val
    else
      scr.out('')
      scr.out('error!')
      scr = nil
      io.stderr:write('\n')
      s_error(msg)
    end
  end

  return {
    up = up,
    done = done,
    s_assert = s_assert,
  }
end

-- tree
-- tree = { {name, type, time, size, attr}, ... }

function conv_type( tp )
  if tp == 'directory' then
    return 'fold'
  else
    return tp
  end
end

function tree_create( path )
  io.stderr:write('scanning file system: ')

  local flist = {}
  local num = 0
  local fs = flystr()
  for fn, fattr in dir.tree(path) do
    flist[fn] = fattr
    num = num + 1
    if math.mod(num, 1000) == 0 then
      fs.out(tostring(num))
    end
  end
  fs.out(tostring(num))
  io.stderr:write('\n')

  local plen = #path
  local ftbl = {}
  for fn, attr in pairs(flist) do
    local rfnm = string.sub(fn, plen+1)
    local rfnm_idx = rfnm
    if not case_sens then
      rfnm_idx = waki.lower(rfnm, "win")
    end
    ftbl[rfnm_idx] = {
      type = conv_type(attr.mode), name = rfnm,
      time = attr.modification - dst_delta_t, attr = attr.win32attr, size = attr.size
    }
  end
  flist = nil
  return ftbl
end

function tree_save( filelist, fname )
  -- emit('saving tree...')
  create_backup(fname)
  local file = s_assert(io.open(fname, 'w'), "can't create file <" .. fnc(fname) .. ">")
  for _, ft in pairs(filelist) do
    file:write(csv.wrap({ft.type, ft.name, ft.time, ft.attr, ft.size})..'\n')
  end
  file:close()
end

function tree_read( fname )
  -- emit('reading tree...')
  local file = s_assert(io.open(fname, 'r'), "can't open file <" .. fnc(fname) .. ">")
  local ftbl = {}
  for s in file:lines() do
    local t = csv.parse(s)
    local rfnm = t[2]
    local rfnm_idx = rfnm
    if not case_sens then
      rfnm_idx = waki.lower(rfnm, "win")
    end
    ftbl[rfnm_idx] = { type = t[1], name = rfnm, time = tonumber(t[3]), attr = t[4], size = tonumber(t[5]) }
  end
  file:close()
  return ftbl
end

-- diff
-- diff = { {diff, type, name, time, size, attr}, ... }

function diff_create( fl1, fl2 )
  -- emit('comparing trees...')
  local diff = {}
  for fn1, ft1 in pairs(fl1) do
    local ft2 = fl2[fn1]
    if ft2 == nil then
      table.insert(diff,
        {diff = 'deleted', type = ft1.type, name = ft1.name, time = ft1.time, attr = ft1.attr, size = ft1.size}
      )
    else
      if ft1.type == 'file' then
        if ft2.time > ft1.time + sec_prec then
          table.insert(diff,
            {diff = 'updated', type = 'file', name = ft2.name, time = ft2.time, attr = ft2.attr, size = ft2.size}
          )
        elseif ft1.time > ft2.time + sec_prec then
          table.insert(diff,
            {diff = 'downdated', type = 'file', name = ft2.name, time = ft2.time, attr = ft2.attr, size = ft2.size}
          )
        end
      end
    end
  end

  for fn2, ft2 in pairs(fl2) do
    local ft1 = fl1[fn2]
    if ft1 == nil then
      table.insert(diff,
        {diff = 'created', type = ft2.type, name = ft2.name, time = ft2.time, attr = ft2.attr, size = ft2.size}
      )
    end
  end

  return diff
end

function diff_save( filelist, fname, ext )
  if ext then
    -- emit('saving diff...')
  else
    -- emit('saving report...')
  end
  create_backup(fname)
  table.sort(filelist,
    function(ft1, ft2)
      local sz1 = ft1.size or 0
      local sz2 = ft2.size or 0
      return sz1 > sz2
    end
  )
  local file = s_assert(io.open(fname, 'w'), "can't create file <" .. fnc(fname) .. ">")
  for _, ft in pairs(filelist) do
    if ext then
      file:write(csv.wrap({ft.diff, ft.type, ft.name, ft.time, ft.attr, ft.size, ft.pos})..'\n')
    else
      file:write(csv.wrap({ft.diff, ft.type, ft.name, ft.size})..'\n')
    end
  end
  file:close()
end

function diff_read( fname )
  -- emit('reading diff...')
  local file = s_assert(io.open(fname, 'r'), "can't open file <" .. fnc(fname) .. ">")
  local ftbl = {}
  for s in file:lines() do
    local t = csv.parse(s)
    table.insert(ftbl, {diff=t[1], type=t[2], name=t[3], time=t[4], attr=t[5], size=t[6], pos=t[7] })
  end
  file:close()
  return ftbl
end

function diff_size( diff )
  local size = 0
  for _, ft in ipairs(diff) do
    if ft.type == 'file' and ft.diff ~= 'deleted' then
      size = size + ft.size
    end
  end
  return size
end

-- pack

function pack_file( dst, fpath, fname, state, p )
  local src = io.open(fpath .. fname, 'rb')
  if not src then
    perror("can't read file <", fname, ">")
    return state
  end

  local data
  repeat
    data = src:read(copy_block_size)
    if data then
      p.s_assert(dst:write(data), "can't write data to archive")
      state = state + #data
      p.up(state)
    end
  until data == nil
  data = nil

  src:close()
  return state
end

function diff_pack( diff, fname, arc_fname )
  local size = diff_size(diff)
  io.stderr:write(string.format('packing updated files (%.2f mb): ', size/1024/1024))
  create_backup(fname)
  create_backup(arc_fname)
  local arc = s_assert(io.open(arc_fname, 'wb'), "can't create file <" .. fnc(arc_fname) .. ">")
  local p = progress(size)
  local state = 0
  for _, ft in pairs(diff) do
    if ft.type == 'file' and ft.diff ~= 'deleted' then
      local pos = arc:seek()
      state = pack_file(arc, base_path, ft.name, state, p)
      ft.pos = pos
    end
  end
  p.done()
  arc:close();
  diff_save(diff, fname, true)
end

-- unpack

function unpack_file(arc, fpath, fname, pos, len, time, state, p)
  local file = io.open(fpath .. fname, 'wb')
  if not file then
    perror("can't rewrite file <", fname, ">")
    return state + len
  end

  local loc_s_assert = s_assert
  if state then
    loc_s_assert = p.s_assert
  end

  len = tonumber(len)
  if len > 0 then
    loc_s_assert(arc:seek('set', pos), "can't seek position in archive")
    while len > 0 do
      local toread = math.min(len, copy_block_size)
      local data = loc_s_assert(arc:read(toread), "can't read file from archive")
      file:write(data)
      if state then
        state = state + #data
        p.up(state)
      end
      len = len - toread
    end
  else
    file:write('')
  end
  file:close()

  local tm = time + dst_delta_t
  loc_s_assert(lfs.touch(fpath .. fname, tm, tm), "can't set time for file <" .. fnc(fname) .. ">")
  return state
end

function path_weight( ft )
  local _, w = string.gsub(ft.name, '[%/%\\]', '/')
  if ft.diff == 'deleted' and ft.type == 'file' then
    return 1000000
  elseif ft.diff == 'deleted' and ft.type == 'fold' then
    return 2000000 + (1000 - w)
  elseif ft.diff == 'created' and ft.type == 'fold' then
    return 3000000 + w
  else -- created and updated files
    return 4000000
  end
end

function set_attrib( fname, attrib )
  attrib = attrib or ''
  if lfs.get_win32attr then
    local w32attr = lfs.set_win32attr(fname, attrib)
    if not w32attr then
      perror("can't set file attribs for <", fname, ">")
    end
  end
end

function diff_unpack()
  local diff = diff_read(diff_fn)
  local size = diff_size(diff)
  io.stderr:write(string.format('unpacking archive (%.2f mb): ', size/1024/1024))
  table.sort(diff, function(ft1, ft2) return path_weight(ft1) < path_weight(ft2) end)
  local arc = s_assert(io.open(archive_fn, 'rb'), "can't open file <" .. fnc(archive_fn) .. ">")
  local p = progress(size)
  local state = 0
  for _, ft in ipairs(diff) do
    if ft.type == 'file' and ft.diff ~= 'deleted' then
      if ft.diff ~= 'created' then
        set_attrib(base_path .. ft.name)
      end
      state = unpack_file(arc, base_path, ft.name, ft.pos, ft.size, ft.time, state, p)
      set_attrib(base_path .. ft.name, ft.attr)
    elseif ft.type == 'file' and ft.diff == 'deleted' then
      set_attrib(base_path .. ft.name)
      if not os.remove(base_path .. ft.name) then
        perror("can't remove file <", ft.name, ">")
      end
    elseif ft.type == 'fold' and ft.diff == 'deleted' then
      set_attrib(base_path .. ft.name)
      if not lfs.rmdir(base_path .. ft.name) then
        perror("can't remove directory <", ft.name, ">")
      end
    elseif ft.type == 'fold' and ft.diff == 'created' then
      if not lfs.mkdir(base_path .. ft.name) then
        perror("can't create directory <", ft.name, ">")
      end
      set_attrib(base_path .. ft.name, ft.attr)
    else
      perror('skipped: ' .. string.format("%s %s %s", ft.diff, ft.type, ft.name))
    end
  end
  p.done()
  arc:close();

  create_backup(archive_fn)
  create_backup(diff_fn)
end

function extract( fname )
  if not fname then
    s_error('no file name, sorry...')
  end
  local fn = fname
  if not case_sens then
    fn = waki.lower(fname, "win")
  end

  local diff = diff_read(diff_fn)
  local fft = {}
  local found = false
  for _, ft in ipairs(diff) do
    local nm = ft.name
    if not case_sens then
      nm = waki.lower(nm, "win")
    end
    if nm == fn then
      fft = ft
      found = true
    end
  end

  if not found then
    s_error('no file <' .. fnc(fname) .. '> in archive')
  else
    if fft.type ~= 'file' then
      s_error('node <' .. fnc(fname) .. '> is not a file')
    else
      if fft.diff == 'deleted' then
        s_error('file <' .. fnc(fname) .. "> was deleted, can't extract it, sorry...")
      else
        -- emit('unpacking file...')
        local arc = s_assert(io.open(archive_fn, 'rb'), "can't open file <" .. fnc(archive_fn) .. ">")
        unpack_file(arc, './', extract_fn, fft.pos, fft.size, fft.time)
        arc:close();
      end
    end
  end
end

-- operations

function report()
  local sv = tree_read(tree_fn)
  local fs = tree_create(base_path)
  local diff = diff_create(sv, fs)
  if #diff > 0 then
    diff_save(diff, report_fn)
    local size = diff_size(diff)
    io.stderr:write(string.format('%d change(s) found (%.2f mb), report created\n', #diff, size/1024/1024))
  else
    io.stderr:write('no changes, report creating skipped\n')
  end
end

function pack()
  local sv = tree_read(tree_fn)
  local fs = tree_create(base_path)
  local diff = diff_create(sv, fs)
  diff_pack(diff, diff_fn, archive_fn)
  return fs
end

-- main

if cmd == 'save' then
  local fs = tree_create(base_path)
  tree_save(fs, tree_fn)
elseif cmd == 'report' then
  report()
elseif cmd == 'pack' then
  pack()
elseif cmd == 'checkout' then
  local fs = pack()
  tree_save(fs, tree_fn)
elseif cmd == 'unpack' then
  diff_unpack()
elseif cmd == 'checkin' then
  diff_unpack()
  report()
elseif cmd == 'extract' then
  extract(base_path)
else
  s_error('unknown command <' .. cmd .. '>')
end

if perror_count > 0 then
  io.stderr:write(perror_count .. ' error(s), see file ' .. perror_fn .. ' for details\n')
end
