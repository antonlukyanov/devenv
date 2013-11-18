--[[
  �������������� �������� ���������.
--]]

function unit( nm ) module(nm, package.seeall) end

unit("lang")

-- simple formatting

function writef( file, fmt, ... )
  file:write(string.format(fmt, ...))
end

function printf( fmt, ... )
  io.write(string.format(fmt, ...), '\n')
end

-- checks uses of undeclared global variables
-- All global variables must be 'declared' through a regular assignment
-- (even assigning nil will do) in a main chunk before being used
-- anywhere or assigned to inside a function.

function set_strict()
  local mt = getmetatable(_G)
  if mt == nil then
    mt = {}
    setmetatable(_G, mt)
  end

  _G.declare = function( name, initval )
    rawset(_G, name, initval or false)
  end
  mt.__newindex = function( t, n, v )
    error("attempt to write to undeclared variable " .. n, 2)
  end
  mt.__index = function( t, n )
    error("attempt to read undeclared variable " .. n, 2)
  end
end

-- Pattern: Stored Expressions

local function storer_call(self, ...)
  self.__index = { n = select('#', ...), ... }
  return ...
end

function mk_storer()
  local self = { __call = storer_call }
  return setmetatable(self, self)
end

-- simple regexp helpers

-- ������������ ��� ����������� ������� � ������ ������
-- ����� �������, ����� ���������� ������� ����� ������.
function quot_search( s )
  return (s:gsub("(%W)", "%%%1"))
end

-- ������������ ��� ����������� ������� � ������ ������
-- ����� �������, ����� ����������� ������������ ������
-- ��� ����������� ������������� �������� �����������.
function quot_replace( s )
  return (s:gsub("%%", "%%%%"))
end

-- dofile() inside the protected environment

function dofile_prot( fname, exp )
  local func = assert(loadfile(fname))        -- ��������� ���� ��� �������
  local env = { }                             -- ������� �������-���������
  if exp then                                 -- ������������ ������� �� ������ ��������
    for f_nm, f_fn in pairs(exp) do
      env[f_nm] = f_fn
    end
  end
  setmetatable(env, {__index = _G})           -- ���� �� ��� ������ � ����������� �����������
  setfenv(func, env)                          -- ��������� �� ��� ��������� ��� �������
  func()                                      -- ��������� �������
  return env
end
