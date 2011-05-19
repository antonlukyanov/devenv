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
  local res = lfs.currentdir()
  lfs.chdir(cwd)
  return res
end

local repo_marker = 'lake_marker'

local function get_base_path()
  return search_marker_up(repo_marker)
end

function get_global_ver()
  local home = lfs.currentdir()

  local base = get_base_path()
  lfs.chdir(base)
  local rev = io.popen('svnversion.exe'):read('*l')
  rev = rev:gsub('%:', '%_')

  lfs.chdir(home)
  return rev
end

repo = {
  get_base_path = get_base_path,
  get_global_ver = get_global_ver,
}

return lang
