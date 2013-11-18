--[[
  lrecode.lua - перекодировка текста.
  Параметры командной строки взяты из recode.exe for DOS.

  Для использования рекомендуется скомпилировать с помощью luaccc.
]]
require "libwaki"

local usage_str = [=[
lrecode 1.0 (2012.08.23). Based on recode.exe for DOS.
Usage: lrecode -xy  [input_file [output_file]]
Parameters are:
  x, y - from {w, a, k, i} where
     w - Windows cp1251,
     a - Alternative DOS cp866,
     k - Koi8-r,
     i - ISO 8859-5,
  input_file  - name of input file,   may be "-" as standard input;
  output_file - name of output file,  may be "-" as standard output.
]=]

if #arg < 1 or #arg > 3 then
  io.write(usage_str)
  return
end

local opt_str = arg[1]
if #opt_str ~= 3 or string.sub(opt_str, 1, 1) ~= '-' then
  io.write(usage_str)
  return
end

local code_from = opt_str:sub(2, 2)
local code_to   = opt_str:sub(3, 3)

local possible_codes = { ['w'] = true, ['a'] = true, ['k'] = true, ['i'] = true }
if not (possible_codes[code_from] and possible_codes[code_to]) then
  io.write(usage_str)
  return
end

local file_inp = io.stdin
local file_out = io.stdout

if #arg >= 2 and arg[2] ~= '-' then
  file_inp = assert(io.open(arg[2], 'rt'))
end

if #arg == 3 and arg[3] ~= '-' then
  file_out = assert(io.open(arg[3], 'wt'))
end

local codes = opt_str:sub(2, 3) -- без дефиса

for s in file_inp:lines() do
  local str_out = waki.recode(s, codes)
  file_out:write(str_out, '\n')
end
