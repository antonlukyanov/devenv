--[[
  Простые обертки для функций os.execute() и io.popen()
--]]

require "libmacro"

local function mk_cmdl( args )
  local tbl = {}
  if type(args[1]) == 'table' then
    tbl = args[1]
    table.remove(args, 1)
  end
  local cmd = macro.subst(table.concat(args, ' '), tbl)
  return cmd
end

local function exec_unp( ... )
  local cmdl = mk_cmdl({...})
  io.write(cmdl .. '\n')
  return os.execute(cmdl)
end

local function exec( ... )
  local cmdl = mk_cmdl({...})
  io.write(cmdl .. '\n')
  local ret = os.execute(cmdl)
  if ret ~= 0 then
    io.write("libsys.exec: error: can't execute command\n")
    os.exit(3)
  end
end

local function pipe( ... )
  local cmdl = mk_cmdl({...})
  local file = assert(io.popen(cmdl))
  local res = file:read('*all')
  file:close()
  return res
end

sys = {
  exec_unp = exec_unp,
  exec = exec,
  pipe = pipe
}

return sys
