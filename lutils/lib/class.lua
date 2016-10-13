-- class.lua, 2016, (c) Anton Lukyanov

--- Methods for emulating work with classes.

local class = function(parent)
  local cl = {}

  -- cl itself is a metatable.
  cl.__index = cl

  -- Dummy method.
  cl.__constructor = function()
  end

  -- Creates new empty table and sets cl as its metatable
  cl.__factory = function()
    local o = {}
    setmetatable(o, cl)
    return o
  end

  -- The same as above but also calls __constructor() of newly created object.
  cl.new = function(...)
    local o = cl.__factory()
    o.__constructor(...)
    return o
  end

  -- Convenience method for extending class properties.
  cl.extend = function(self, ...)
    for _, tbl in ipairs({...}) do
      for k, v in pairs(tbl) do
        self[k] = v
      end
    end
  end

  if parent then
    setmetatable(cl, {
      __index = parent
    })
  end

  -- Return new table which points to 'cl' table.
  return setmetatable({}, {
    __call = function(...)
      return cl.new(...)
    end,
    __index = cl,
    __newindex = cl,
    __metatable = cl,
  })
end

return class
