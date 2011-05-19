--[[
  ѕолучение и форматирование svn-лога по проекту.
--]]

require "lfs"
require "libwaki"
require "libcmdl"
require "libhtml"

opts = cmdl.options()
if #arg == 1 and arg[1] == '?' then
  io.stderr:write('Usage: slog [-v] [repos]\n')
  os.exit()
end

if #arg == 1 then
  repos = arg[1]
else
  repos = os.getenv('SLOG_REPOS')
  if not repos then
    io.stderr:write("can't find env SLOG_REPOS, sorry\n")
    os.exit()
  end
end
fname = repos:gsub('://', '_'):gsub(':', '_'):gsub('/', '_'):gsub('%.', '_')
io.stderr:write('remote_address=<' .. repos .. '>\n')
io.stderr:write('local_name=<' .. fname .. '>\n\n')

cache = {}
cache_maxrev = 0
cache_fn = fname .. '.log'
if lfs.attributes(cache_fn) then
  io.stderr:write('reading cached log from <' .. cache_fn .. '>\n')
  cache = dofile(cache_fn)
  for _, v in ipairs(cache) do
    local rev = tonumber(v.rev)
    if rev > cache_maxrev then
      cache_maxrev = rev
    end
  end
else
  io.stderr:write('*** cache not found, loading from remote repository\n')
end

function get_log( from )
  local tnm = '.' .. os.tmpname()
  io.stderr:write('receiving svn log from remote server...\n')
  if os.execute(string.format('svn log -v %s -r %d:HEAD >%s', repos, from, tnm)) ~= 0 then
    io.stderr:write('*** receiving svn log from remote server failed, sorry\n')
  end

  local log = {}
  for s in io.lines(tnm) do
    if s ~= string.rep('-', 72) then
      table.insert(log, s)
    end
  end
  os.remove(tnm)
  return log
end

function perror( s )
  io.stderr:write("*** can't parse line <" .. s .. ">\n")
  os.exit()
end

function parse_log( log, start )
  local s, sn = log[1], 2
  local res = start or {}
  local num = 0
  while sn <= #log do
    local rev, author, date, time, lines = s:match('^r(%d+) | (.*) | (%S+) (%S+) .* | (%d+) lines?$')
    if not rev then perror(s) end
    local info = { rev = rev, author = author, date = date .. ', ' .. time}

    s, sn = log[sn], sn+1
    info.files = {}
    if s:match('^Changed paths:$') then
      s, sn = log[sn], sn+1
      while not s:match('^$') do
        table.insert(info.files, s:match('^%s*(.*)$'))
        s, sn = log[sn], sn+1
      end
    end
    s, sn = log[sn], sn+1

    info.comment = {}
    for j = 1, tonumber(lines) do
      if not s:match('^%s*$') then
        table.insert(info.comment, s)
      end
      s, sn = log[sn], sn+1
    end
    table.insert(res, info)
    num = num + 1
  end
  io.stderr:write(string.format('%d versions received from remote repository\n', num))
  return res
end

function aw( s ) 
  return waki.recode(s, 'aw') 
end

function export_tbl( tbl )
  io.output(fname .. '.htm')

  html.write_header()
  io.write('<table border=1>\n')
  for _, info in ipairs(tbl) do
    io.write('<tr>\n')
    io.write('<td>' .. info.rev .. '</td>\n')
    io.write(string.format("<td><b>%s</b> [%s]</td>\n", aw(info.author), aw(info.date)))
    io.write('</tr>\n')

    io.write('<tr>\n')
    io.write('<td></td>\n')
    io.write('<td>\n')
    for _, s in ipairs(info.comment) do
      io.write(aw(s) .. '<br>\n')
    end
    io.write('</td>\n')
    io.write('</tr>\n')

    if opts['-v'] then
      io.write('<tr>\n')
      io.write('<td></td>\n')
      io.write('<td><font size="-1">\n')
      for _, s in ipairs(info.files) do
        io.write('<tt>' .. aw(s) .. '</tt><br>\n')
      end
      io.write('</font></td>\n')
      io.write('</tr>\n')
    end
  end
  io.write('</table>\n')
  html.write_trailer()
end

function save_tbl( tbl )
  io.output(fname .. '.log')
  io.write('return {\n')
  for _, info in ipairs(tbl) do
    io.write('{\n')
    io.write(string.format('  rev = %q,\n', info.rev))
    io.write(string.format('  author = %q,\n', info.author))
    io.write(string.format('  date = %q,\n', info.date))

    io.write('  comment = {\n')
    for _, s in ipairs(info.comment) do
      io.write(string.format('    %q,\n', s))
    end
    io.write('  },\n')

    io.write('  files = {\n')
    for _, s in ipairs(info.files) do
      io.write(string.format('    %q,\n', s))
    end
    io.write('  },\n')
    io.write('},\n')
  end
  io.write('}\n')
end

log = get_log(cache_maxrev + 1)
tbl = parse_log(log, cache)
table.sort(tbl, function(i1, i2) return tonumber(i1.rev) > tonumber(i2.rev) end)
export_tbl(tbl)
save_tbl(tbl)
