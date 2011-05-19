--[[
  lake, (c) ltwood
--]]

require "lfs"
require "libcmdl"
require "libfname"
require "librepo"

local copyright = 'lake: ver. 8.03, 2003 Aug, 2010 Mar, (c) ltwood'
-- 7.02: r.3130
-- 7.03: r.3131
-- 7.04: r.3139
-- 7.05: r.3145
-- 7.06: r.3146
-- 7.07: r.3181
-- 7.08: r.3183
-- 7.09: r.3194
-- 7.10: r.3202
-- 8.00: r.3203
-- 8.01: r.3313
-- 8.02: схема поиска базовой директории
-- 8.03: вывод путей для файлов-дубликатов

local devel = false

-- печать таблицы
local function pt( t )
  print('---')
  for fn, fv in pairs(t) do
    print(fn, fv)
  end
  print('---')
end

-- обработка ошибок
local function abort( msg )
  if devel then
    io.stderr:write(debug.traceback('error: ' .. msg))
  else
    io.stderr:write('error: ' .. msg .. '\n')
  end
  os.exit(1)
end

-- выполнение в защищенном окружении
local function prot_run( fname, env )
  local func = assert(loadfile(fname))
  setfenv(func, env)
  func()
  return env
end

-- получение параметров с контролем их наличия
local function get_param( pname )
  local val = lakefile[pname]
  if val ~= nil then
    return val
  else
    abort('no parameter <' .. pname .. '>')
  end
end

-- проверка наличия параметра
local function is_param( pname )
  return lakefile[pname] ~= nil
end

-- нормирование пути: тип слэшей, завершающий слэш
local function norm_dir( path )
  local is_rev = is_param('rev_slash') and get_param('rev_slash')
  local slash = (is_rev and '\\') or '/'
  local npath = string.gsub(path, '[%/%\\]', slash)
  if string.sub(npath, -1) ~= slash then
    npath = npath .. slash
  end
  local is_csens = is_param('case_sens') and get_param('case_sens')
  return (is_csens and npath) or string.lower(npath)
end

-- получение относительного пути для текущей директории
local function calc_cwd( abs_curdir )
  local basedir = get_param('basedir')
  if string.sub(abs_curdir, 1, #basedir) ~= basedir then
    io.stderr:write('curr_path='..abs_curdir..'\n')
    io.stderr:write('base_path='..basedir..'\n')
    abort('curent path should be a subpath of the base path')
  end
  return abs_curdir:sub(#basedir+1)
end

-- построчный разбор файла
local function parse( fn, prs )
  local list = {}
  for s in io.lines(fn) do
    local res = prs(s)
    if res == nil then break end
    if type(res) == 'string' then
      list[res] = true
    elseif type(res) == 'table' then
      for _, v in ipairs(res) do
        list[v] = true
      end
    else
      abort('incorrect return value from parser on file <' .. fn .. '>\n')
    end
  end
  return list
end

-- информация о файле репозитория
local function create_fileinfo( fpath, main_fl )
  local pt = fname.split(fpath)
  local abs_path = get_param('basedir') .. fpath
  local fattr = lfs.attributes(abs_path)
  if not fattr then
    return nil
  end

  local finfo = {
    dir = pt.dir,
    name = pt.name,
    ext = pt.ext or "",
    is_main = main_fl,
    time = fattr.modification,
    deplist = {},
    tasklist = {},
  }
  if get_param(finfo.ext).dep_parser then
    finfo.deplist = parse(abs_path, get_param(finfo.ext).dep_parser)
  end
  if get_param(finfo.ext).task_parser then
    finfo.tasklist = parse(abs_path, get_param(finfo.ext).task_parser)
  end
  return finfo
end

local function create_filelist( dir )
  local abs_path = get_param('basedir') .. dir

  local res = {}
  for fn in lfs.dir(abs_path) do
    res[dir .. fn] = true
  end
  return res
end

-- репозиторий исходников

local use_env = {
  type = type, tostring = tostring, tonumber = tonumber,
  print = print, error = error, assert = assert,
  pairs = pairs, ipairs = ipairs,
  table = table, string = string, io = io, os = os,
}

local function create_repos()
  local _dirlist = {}   -- список директрий для поиска исходников

  -- рекурсивная раскрутка списка директорий по файлам use_file.
  local function add_dir( dir )
    local nd = norm_dir(dir)
    if _dirlist[nd] then return end
    _dirlist[nd] = create_filelist(nd)
    if is_param('usefile_name') then
      local fn = get_param('basedir') .. nd .. get_param('usefile_name')
      if lfs.attributes(fn) then
        local res = prot_run(fn, use_env)
        for _, d in ipairs(res.use) do
          add_dir(d)
        end
      end
    end
  end

  -- инициализация списка директорий поиска
  if is_param('use_cwd') and get_param('use_cwd') then
    add_dir(start_cwd)
  end
  for _, dir in ipairs(get_param('use')) do
    add_dir(dir)
  end

  -- превращение списка имен файлов в список finfo
  local function expand_list( list, tff )
    for fn, _ in pairs(list) do
      local fi = tff(fn)
      if not fi then
        abort("can't find file <" .. fn .. ">")
      end
      list[fn] = fi
    end
  end

  local _filehash = {}  -- кэш информации о файлах
  local _notfound = {}  -- уникальная метка для ненайденных файлов
  local _notready = {}  -- уникальная метка для файлов, находящихся в процессе обработки

  -- поиск файла по краткому имени
  local function test_file( fname )
    local fr = _filehash[fname]
    if fr == _notready then
      abort('circular dependency at <' .. fname .. '>')
    end
    if fr then
      return (fr ~= _notfound and fr) or nil
    end

    _filehash[fname] = _notready
    local finfo = nil
    for d, dh in pairs(_dirlist) do
      if dh[d .. fname] then
        local fi = create_fileinfo(d .. fname)
        if fi then
          if not finfo then
            expand_list(fi.deplist, test_file)
            expand_list(fi.tasklist, test_file)
            finfo = fi
          else
            io.stderr:write('first_path=<'..finfo.dir..'>\n')
            io.stderr:write('second_path=<'..fi.dir..'>\n')
            abort('duplicate file name <' .. fname .. '>')
          end
        end
      end
    end

    _filehash[fname] = finfo or _notfound
    return finfo
  end

  return {
    is_exists = function(fn)
      return test_file(fn) ~= nil
    end,
    search = function(fn, parent) -- возвращает объект fileinfo для заданного файла
      local fi = test_file(fn)
      if not fi then
        abort("can't find file <" .. fn .. ">" .. ((parent and ' (from <' .. parent .. '>)') or ''))
      end
      return fi
    end,
  }
end

-- дерево зависимостей
local function create_deptree( rep )
  local _tasklist = {}   -- список исходников для сборки приложения
  local _dep_cl = {}     -- кэш результатов построения замыкания списка зависимостей

  local function tadd( d, s )
    for i, v in pairs(s) do
      d[i] = v
    end
  end

  local function dep_closure( fn, fi )
    if not _dep_cl[fn] then
      if get_param(fi.ext).is_nontransitive_dep then
        _dep_cl[fn] = fi.deplist
      else
        local dep = {}
        tadd(dep, fi.deplist)
        for d, _ in pairs(fi.deplist) do
          local dfi = rep.search(d, fn)
          tadd(dep, dep_closure(d, dfi))
        end
        _dep_cl[fn] = dep
      end
    end
    return _dep_cl[fn]
  end

  -- рекурсивное добавление задач
  local function add_task( fn )
    if _tasklist[fn] then return end
    local fi = rep.search(fn)
    local dep = dep_closure(fn, fi)
    _tasklist[fn] = { finfo = fi, fulldeplist = dep }
    -- добавляем все задания на сборку, требуемые файлом непосредственно
    for tfn, _ in pairs(fi.tasklist) do
      add_task(tfn)
    end
    for d, dfi in pairs(dep) do
      -- добавляем все задания на сборку, требуемые файлами-зависимостями
      for tfn, _ in pairs(dfi.tasklist) do
        add_task(tfn)
      end
      local ext_par = get_param(dfi.ext)
      -- если зависимость сама требует сборки, то добавляем задание
      if ext_par.dep2src then
        local at = ext_par.dep2src(d)
        if at then
          if ext_par.do_demand_src then
            add_task(at)
          else
            if rep.is_exists(at) then
              add_task(at)
            end
          end
        end
      end
    end
  end

  local src = get_param('start')
  add_task(src)

  local function print()
    for fn, v in pairs(_tasklist) do
      io.write(fn, ': ' )
      for d, fi in pairs(v.fulldeplist) do
        io.write(d, ' ')
      end
      io.write('\n')
    end
  end

  return {
    print = print,

    for_all = function( iter )
      for _, rec in pairs(_tasklist) do
        iter(rec.finfo, rec.fulldeplist)
      end
    end
  }
end

--
-- actions
--

-- make, build

-- подготовка списка директорий по списку зависимостей
local function mk_inc_paths( basedir, deplist )
  local inc_paths = {}
  for _, fi in pairs(deplist) do
    table.insert(inc_paths, basedir .. fi.dir)
  end
  return inc_paths
end

-- проверка обновленности объектника
local function is_updated( dst, finfo, deplist )
  local dst_attr = lfs.attributes(dst)
  if not dst_attr then
    return true
  end
  if finfo.time > dst_attr.modification then
    return true
  end
  for _, fi in pairs(deplist) do
    if fi.time > dst_attr.modification then
      return true
    end
  end
  return false
end

-- проверка обновленности исполнимого модуля
local function is_dst_updated( dst, obj_list )
  local dst_attr = lfs.attributes(dst)
  if not dst_attr then
    return true
  end
  for _, obj in ipairs(obj_list) do
    local obj_attr = lfs.attributes(obj)
    if obj_attr.modification > dst_attr.modification then
      return true
    end
  end
  return false
end

local run_param = {
  is_dry = false,
  is_verb = false
}

local function run( cmdl, msg )
  if run_param.is_verb then
    io.write(cmdl .. '\n')
  else
    if msg then io.write(msg .. '\n') end
  end
  if not run_param.is_dry then
    return (os.execute(cmdl) == 0)
  else
    return true
  end
end

local function do_make( rep, dep, do_buildall, do_strip )
  local bp = get_param('basedir')
  local obj_list = {}
  local weights = {}
  dep.for_all(
    function(fi, dl)
      if not get_param(fi.ext).src2obj then
        abort("can't find destination src2obj for tasktype <" .. fi.ext .. ">") --!!
      end
      local dst = get_param(fi.ext).src2obj(bp, fi.dir, fi.name)
      table.insert(obj_list, dst)
      weights[dst] = get_param(fi.ext).weight or 0
      local inc_paths = mk_inc_paths(bp, dl)
      if get_param(fi.ext).compile and (do_buildall or is_updated(dst, fi, dl)) then
        local cmdl, msg = get_param(fi.ext).compile(dst, fi.name, bp .. fi.dir, inc_paths)
        if not run(cmdl, msg) then
          abort('shit happens!')
        end
      end
    end
  )
  table.sort(obj_list, function(a, b) return weights[a] < weights[b] end)

  local dst = get_param('dest')
  if do_buildall or is_dst_updated(dst, obj_list) then
    local cmdl, msg = get_param('link')(dst, obj_list)
    if not run(cmdl, msg) then abort('shit happens!') end
  end
  if do_strip and is_param('strip') then
    local cmdl, msg = get_param('strip')(dst)
    if not run(cmdl, msg) then abort('shit happens!') end
  end
end

-- export

local function concat_dep( deplist )
  local res = ''
  for fn, _ in pairs(deplist) do
    res = res .. fn .. ' '
  end
  return res:sub(1, -2)
end

-- Создание standalone makefile по текущему проекту.
local function do_makefile( rep, dep )
  local mkf = io.open('export/makefile', 'wt')

  mkf:write('# This file is automatically generated by the <lake> utility\n')
  mkf:write('# ' .. copyright .. '\n\n')

  if is_param('export_preambule') then
    local stbl = get_param('export_preambule')
    for _, s in ipairs(stbl) do
      mkf:write(s, '\n')
    end
  end
  mkf:write('\n')

  local obj_list = {}
  local weights = {}
  dep.for_all(
    function(fi, dl)
      if not get_param(fi.ext).export_src2obj then
        abort("can't find destination export_src2obj for tasktype <" .. fi.ext .. ">") --!!
      end
      local dst = get_param(fi.ext).export_src2obj(fi.name)
      table.insert(obj_list, dst)
      weights[dst] = get_param(fi.ext).weight or 0
    end
  )
  table.sort(obj_list, function(a, b) return weights[a] < weights[b] end)

  local dst = get_param('dest')
  mkf:write(dst, ': ', table.concat(obj_list, ' '), '\n')
  if is_param('export_link') then
    mkf:write('\t', get_param('export_link')(dst, obj_list), '\n')
  else
    mkf:write('\t', get_param('link')(dst, obj_list), '\n')
  end
  if is_param('strip') then
    mkf:write('\t', get_param('strip')(dst), '\n')
  end
  mkf:write('\n')

  dep.for_all(
    function(fi, dl)
      if not get_param(fi.ext).export_src2obj then
        abort("can't find destination export_src2obj for tasktype <" .. fi.ext .. ">") --!!
      end
      local dst = get_param(fi.ext).export_src2obj(fi.name)
      mkf:write(dst, ': ', fi.name..fi.ext, ' ', concat_dep(dl), '\n')
      if get_param(fi.ext).export_compile then
        mkf:write('\t', get_param(fi.ext).export_compile(dst, fi.name), '\n')
      elseif get_param(fi.ext).compile then
        mkf:write('\t', get_param(fi.ext).compile(dst, fi.name, "", {}), '\n')
      end
      mkf:write('\n')
    end
  )

  mkf:close()
end

local function copy_file( dst, src )
  src_file = assert(io.open(src, 'rb'))
  dst_file = assert(io.open(dst, 'wb'))
  dst_file:write(src_file:read('*all'))
  dst_file:close()
  src_file:close()
end

local function do_export( rep, dep )
  if not lfs.mkdir('export') then
    abort("can't create export directory")
  end

  local file_list = {}
  dep.for_all(
    function(fi, dl)
      table.insert(file_list, fi)
      for _, dfi in pairs(dl) do
        table.insert(file_list, dfi)
      end
    end
  )
  local bp = get_param('basedir')
  for _, fi in ipairs(file_list) do
    copy_file('export/'..fi.name..fi.ext, bp..fi.dir..fi.name..fi.ext)
  end
end

-- helpers

local function is_stop( s )
  return s:match('^%s*%/%*%#lake:stop%*%/')
end

function get_hdr( s )
  local f = s:match('^%s*%#%s*include%s*%"%s*(.*)%s*%"')
  if f then return f else return {} end
end

function get_lib( s )
  local f = s:match('^%s*%/%*%#lake%:lib%:%s*(.*)%s*%*%/')
  if f then return get_param('lib2fname')(f) end
  local f = s:match('^%s*%/%*%#lake%:res%:%s*(.*)%s*%*%/')
  if f then return get_param('res2fname')(f) end
  return {}
end

local cc_tbl = {
  hdr_parser = function( s )
    if is_stop(s) then return nil end
    return get_hdr(s)
  end,

  lib_parser = function( s )
    if is_stop(s) then return nil end
    return get_lib(s)
  end,
}

-- rules support

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

local lake = {}

local function addpar( t )
  for n, v in pairs(t) do
    lake[n] = v
  end
end

local lake_env

local function use_rules( rules_fn, rules_mode )
  local basedir = repo.get_base_path()
  local rules_path = basedir .. '/' .. rules_fn
  lake_env.basedir = basedir
  prot_run(rules_path, lake_env)
  if type(lake_env.init_rules) == 'function' then
    lake_env.init_rules(rules_mode or {})
  end
end

lake_env = {
  type = type, tostring = tostring, tonumber = tonumber,
  print = print, error = error, assert = assert,
  pairs = pairs, ipairs = ipairs,
  table = table, string = string, io = io, os = os,

  lake = lake,
  cc = cc_tbl,

  abort = abort, run = run, subst = subst, split = fname.split,
  addpar = addpar, use_rules = use_rules,
}

-- main

local function main( action, lakefilename, options )
  run_param.is_verb = (options['-v'] ~= nil)
  run_param.is_dry = (options['-d'] ~= nil)
  local do_strip = (options['-s'] ~= nil)

  local cwd = lfs.currentdir()
  prot_run(lakefilename, lake_env)
  lakefile = lake_env.lake
  lakefile.basedir = norm_dir(get_param('basedir'))
  start_cwd = calc_cwd(norm_dir(cwd))

  if is_param('prepare') then
    get_param('prepare')(get_param('basedir'), start_cwd)
  end
  local rep = create_repos()
  local dep = create_deptree(rep)

  if action == 'pdep' then
    dep.print()
  elseif action == 'make' or action == 'build' then
    do_make(rep, dep, action == 'build', do_strip)
  elseif action == 'export' then
    do_export(rep, dep)
    do_makefile(rep, dep)
  else
    abort('unknown action <' .. action .. '>')
  end
end

local options = cmdl.options()

if #arg ~= 2 then
  io.write(copyright .. '\n')
  io.write'Usage: lua llake.lua action lakefile [-v] [-d] [-s]\n'
  io.write'Actions: pdep, make, build, export\n'
  io.write'Options:\n'
  io.write'  -v  Verbose mode\n'
  io.write'  -d  Dry run\n'
  io.write'  -s  Strip executable\n'
  os.exit(1)
end

main(arg[1], arg[2], options)

--[[
--]]
