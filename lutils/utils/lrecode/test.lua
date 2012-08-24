--[[
Тестирует lrecode.lua на наборе файлов с одинаковым текстом в разных колировках.
]]

local fmt = string.format

-- Прочитать текстовый файл целиком как string.
function read_all_file( fn )
  local f = assert(io.open(fn, 'rt'))
  local s = f:read('*a')
  f:close()
  return s
end

local cp_marks = { 'w', 'a', 'k', 'i' }

local total_ok = true

local cmd_fmt = 'lua lrecode.lua -%s%s text_%s.txt -'
for _, from in ipairs(cp_marks) do
  for _, to in ipairs(cp_marks) do
    local cmd_str = fmt(cmd_fmt, from, to, from)
    local file = assert( io.popen(cmd_str, 'r') )
    local text_actual = file:read('*a')
    file:close()
    file = nil

    local text_expected = read_all_file(fmt('text_%s.txt', to))
    local ok = text_expected == text_actual
    total_ok = total_ok and ok
    print( fmt('Test %s%s %s', from, to, ok and 'OK.' or 'FAILED') )
  end
end

os.exit(total_ok and 0 or 1)
