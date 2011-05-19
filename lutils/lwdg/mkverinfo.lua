-- Создает файл с информацией о версии

local pipe = assert(io.popen('svnversion .'))
local ver = pipe:read('*line')
pipe:close()
local file = io.open('revision.svn','wt')
file:write('// This is automatically generated file -- do not edit!\n\n')
file:write('#define SVN_VER "', ver,'"\n')
file:close()
