--[[
  Функция-итератор по файлам, содержащимся в поддиректориях
  заданного поддерева файловой системы.
  Дополнительно реализована функция, формирующая список
  файлов поддерева, отобранных функцией-селектором.
--]]

require "lfs"
require "libfname"

local function ldir( path )
  local i, s = lfs.dir(path)
  return s
end

local function tree( path )
  path = path:gsub('\\', '/')
  if string.sub(path, -1) == "/" then
    path = string.sub(path, 1, -2)
  end

  local dir_iter = { ldir(path) }
  local dir_path = { path }

  return function()
    repeat 
      local entry = dir_iter[#dir_iter]:next()
      if entry then 
        if entry ~= "." and entry ~= ".." then 
          local fnm = table.concat(dir_path, "/").."/"..entry
          local attr = lfs.attributes(fnm)
          if lfs.get_win32attr then
            attr.win32attr = lfs.get_win32attr(fnm)
          end
          if attr.mode == "directory" then 
            table.insert(dir_path, entry)
            table.insert(dir_iter, ldir(fnm))
          end
          return fnm, attr
        end
      else
        dir_iter[#dir_iter]:close()
        table.remove(dir_iter)
        table.remove(dir_path)
      end
    until #dir_iter == 0
  end
end

local function collect( path, sel )
  local res = {}
  for fn, fattr in tree(path) do
    if not sel or sel(fn, fattr) then
      res[fn] = fattr
    end
  end
  return res
end

dir = {
  tree = tree,
  collect = collect
}

return dir
