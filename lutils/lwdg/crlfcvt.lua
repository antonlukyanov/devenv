--[[
  –аспознавание типа переводов строк, вывод диагностики и конвертирование.
--]]

require "libdir"
require "libcmdl"

local CR = '\013'
local LF = '\010'

function check( buf )
  if buf:find('\0') then
    return 'binary'
  end
  local cr, lf, crlf = 0, 0, 0
  local len = #buf
  local j = 1
  while j <= len do
    local ch, nch = buf:sub(j,j), (j<len) and buf:sub(j+1, j+1) or nil
    if ch == CR and nch == LF then
      crlf = crlf + 1
      j = j + 2
    elseif ch == CR then
      cr = cr + 1
      j = j + 1
    elseif ch == LF then
      lf = lf + 1
      j = j + 1
    else
      j = j + 1
    end
  end

  if crlf > 0 and lf == 0 and cr == 0 then
    return 'text:crlf'
  elseif lf > 0 and crlf == 0 and cr == 0 then
    return 'text:lf'
  elseif cr > 0 and crlf == 0 and lf == 0 then
    return 'text:cr'
  else
    if cr ~= 0 or lf ~= 0 or crlf ~= 0 then
      return 'text:mixed'
    else
      return 'text:line'
    end
  end
end

function crlf2lf( buf )
  return buf:gsub(CR..LF, LF)
end

local opt = cmdl.options()
local do_conv = false
if opt['-c'] then
  do_conv = true
end

flist = dir.collect('.', function(fn, attr)
    return attr.mode == 'file'
  end
)

for fn in pairs(flist) do
  if not fn:match('%/%.hg%/') then
    local file = io.open(fn, "rb")
    local buf = file:read('*all')
    file:close()
    local resume = check(buf)
    if resume == 'text:mixed' then
      io.write(fn, ': mixed\n')
    elseif resume == 'text:cr' then
      io.write(fn, ': cr\n')
    elseif resume == 'text:crlf' then
      io.write(fn, ': crlf\n')
      if do_conv then
        local buf2 = crlf2lf(buf)
        local file = io.open(fn, "wb")
        file:write(buf2)
        file:close()
      end
    end
  end
end
