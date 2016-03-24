-- Библиотека для доступа к параметрам репозитория исходников

require "lfs"

local function search_marker_up( marker_name )
  local cwd = lfs.currentdir()
  local prev_dir = lfs.currentdir()
  while lfs.attributes(marker_name) == nil do
    lfs.chdir('..')
    local dir = lfs.currentdir()
    if dir == prev_dir then
      break
    end
    prev_dir = dir
  end
  
  local res = false
  if lfs.attributes(marker_name) then
    res = lfs.currentdir()
  end
  
  lfs.chdir(cwd)
  
  return res
end

repo = {
  search_marker_up = search_marker_up,
}

return repo
