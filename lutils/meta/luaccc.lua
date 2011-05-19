--[[
  Умный компилятор исходников на Lua в exe-файл.

  Автомагически строит список используемых модулей, отыскивая их
  в соответствии со стандартными правилами поиска, и использует luacc 
  для построения исполнимого файла.

  Дополнительно поддерживается возможность принудительной линковки
  модулей с помощью управляющего комментария вида --#, в котором
  (без пробела после символа '#') может идти обычная директива require().
  Эта возможность полезна для утилит, самостоятельно выполняющих lua-скрипты,
  которым могут потребоваться внешние модули.
  Прилинковав необходимые модули принудительно, можно избавиться от необходимости
  иметь их в виде отдельных файлов.
--]]

require "libfname"
require "libcmdl"
require "luacc"

do_strip = cmdl.options()['-s']

if #arg ~= 1 then
  io.write('Usage: lua luaccc.lua [-s] filename\n')
  os.exit()
end

mname = arg[1]

lua_path = os.getenv('lua_path');
path_tbl = {}
for s in lua_path:gmatch('[^%;]+') do
  table.insert(path_tbl, s)
end

function find_file( fn )
  if io.open(fn, 'rt') then
    return fn
  end
  for _, path in ipairs(path_tbl) do
    local ffn = path:gsub('%?', fn)
    if io.open(ffn, 'rt') then
      return ffn
    end
  end
  return nil
end

function parse( fn )
  local res = {}
  for s in io.lines(fn) do
    local _, _, fn2 = s:find('%s*require%s*%(?%s*[%"%\']([%_%w]+)[%"%\']%s*%)?')
    if fn2 then
      res[fn2] = true
    end
    local _, _, fn2 = s:find('%-%-%#require%s*%(?%s*[%"%\']([%_%w]+)[%"%\']%s*%)?')
    if fn2 then
      res[fn2] = true
    end
  end
  return res
end

function proc( tbl, fname )
  local fname_tbl = parse(fname)
  for fn in pairs(fname_tbl) do
    local ffn = find_file(fn)
    if ffn then
      tbl[ffn] = fn
      proc(tbl, ffn)
    else
      io.write('module ' .. fn .. ' not found, skipped\n')
    end
  end
end

tbl = {}
proc(tbl, mname)

src = { mname }
for ffn, fn in pairs(tbl) do
  io.write('module ' .. fn .. ' found at ' .. ffn .. '\n')
  table.insert(src, ffn)
end
exe = fname.split(mname).name .. '.exe'

luacc.compile(do_strip, exe, unpack(src))
