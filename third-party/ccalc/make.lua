require "libsys"
require "libplatform"

__ = sys.exec

home = os.getenv('LWDG_HOME')

if platform.os_type ~= 'windows' then
  local dst = 'ccalc'
else
  local dst = 'ccalc.exe'
end

__('g++ -static -Wno-write-strings -o ' .. dst .. ' ccalc.cpp')
__('strip ' .. dst)
__('mv ' .. dst ..  ' ' .. home .. '/utils')
