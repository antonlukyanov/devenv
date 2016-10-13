-- argparser.lua, 2016, (c) Anton Lukyanov

local fun   = require('fun')
local str   = require('str')
local class = require('class')

local function abort(msg)
  io.stderr:write('Error: ' .. msg .. '\n')
  os.exit(1)
end

local function err(msg)
  error('Error: ' .. msg .. '\n')
end

local function throw(info)
  if type(info) == 'string' then
    info = {
      message = info
    }
  end
  error(info)
end

local function try(fun, catch_fun)
  local status, err = pcall(fun)
  if not status then
    catch_fun(err)
  end
end

--[[
ArgParser is a simple class for parsing command line options and arguments.

>> ArgParser:add_option(name, default)
Adds option with name 'name'. 'name' must be in a format '-<shor name char> --<long name string>'.
There must be at least short or long name. You can also optionally specify default value for option,
otherwise its default value will be 'nil'.

>> ArgParser:add_flag(name)
Adds option with name 'name'. 'name' must be in a format '-<shor name char> --<long name string>'.
There must be at least short or long name. Difference between flag and option is that flag does not
have a value. It can be either 'true' or 'false'.

>> ArgParser:add_arg(name, default, required)
Adds positional argument with name 'name' and optional default value 'default'. It is also possible
to specify whether argument is required or not by passing boolean value 'required'.

>> ArgParser:option(name)
Returns value for option or flag.

>> ArgParser:arg(name)
Returns value for positional argument specified by its name.

[Other public methods]:

>> ArgParser:parse(args)
Parses table of arguments. 'args' is optional. You must call this method before using getters.

Example usage:

p = ArgParser('progname', 'Long description.')
p:add_arg('arg1', nil, true)
p:help('help message 1')

p:add_arg('arg2', nil, true)
p:help('help message 2')

p:add_arg('arg3', 'arg3-default-value', false)
p:help('help message 3')

p:add_option('-t --test')
p:help('help message 4')

p:add_option('-d --test-default', 'test-default-value')
p:help('help message 5')

p:add_flag('-f --flag1')
p:help('help message 6')

p:add_flag('-g --flag2')
p:help('help message 7')

p:parse()

print(p:arg('arg1'))
print(p:arg('arg2'))
print(p:arg('arg3'))
print(p:option('test'))
print(p:option('d'))
print(p:option('flag1'))
print(p:option('flag2'))
]]
local ArgParser = class()

function ArgParser:__constructor(name, description)
  self:extend({
    args = {},
    args_required = {},
    args_names = {},
    options = {},
    options_list = {},
    parsed = false,
    name = name,
    description = description,
    last_value = nil,
  })
end

function ArgParser:get_option_names(s)
  local short
  local long
  for _, v in ipairs(fun.map(str.split(s),
                            function(v)
                              return str.strip(v)
                            end)) do
    if self:is_long_option(v) then
      long = v:sub(3)
    end
    if self:is_short_option(v) then
      short = v:sub(2)
    end
  end
  return short, long
end

function ArgParser:is_short_option(s)
  return not s:match('^%-%-') and s:match('^%-')
end

function ArgParser:is_long_option(s)
  return s:match('^%-%-')
end

--
-- Setters
--

function ArgParser:add_option(name, default, help)
  local short
  local long
  short, long = self:get_option_names(name)
  if not short and not long then
    abort('You must specify at least one name for option.')
  end

  local option = {
    value = nil,
    short = short,
    long = long,
    default = default,
    help = help,
    required = required,
    -- 'option' or 'flag'.
    type = 'option',
  }

  if short then
    if self.options[short] then
      abort('Short option ' .. short ..  ' has already been set.')
    end
    self.options[short] = option
  end

  if long then
    if self.options[long] then
      abort('Long option ' .. long ..  ' has already been set.')
    end
    self.options[long] = option
  end

  if self.options[short] or self.options[long] then
    self.last_value = option
    table.insert(self.options_list, option)
  end
end

function ArgParser:add_flag(name, help)
  local short
  local long
  short, long = self:get_option_names(name)
  if not short and not long then
    abort('You must specify at least one name for flag.')
  end

  local option = {
    value = nil,
    short = short,
    long = long,
    default = nil,
    help = help,
    -- 'option' or 'flag'.
    type = 'flag',
  }

  if short then
    if self.options[short] then
      abort('Short flag ' .. short ..  ' has already been set.')
    end
    self.options[short] = option
  end

  if long then
    if self.options[long] then
      abort('Long flag ' .. short ..  ' has already been set.')
    end
    self.options[long] = option
  end

  if self.options[short] or self.options[long] then
    self.last_value = option
    table.insert(self.options_list, option)
  end
end

function ArgParser:add_arg(name, default, required, help)
  local arg = {
    name = name,
    value = nil,
    required = required or false,
    default = default,
    help = help,
    type = 'arg',
  }
  if required then
    self.args_required[name] = true
  end
  self.args[name] = arg
  self.last_value = arg
  table.insert(self.args_names, name)
end

function ArgParser:help(help)
  if self.last_value then
    self.last_value.help = help
  end
end

--
-- Getters
--

function ArgParser:option(name)
  self:check_parsed()
  local option = self.options[name]
  if not option then
    abort('Unknown option: --' .. name)
  end
  return option.value or option.default
end

function ArgParser:arg(name)
  self:check_parsed()
  local arg = self.args[name]
  if not arg then
    abort('Unknown argument: --' .. name)
  end
  return arg.value or arg.default
end

--
-- Misc
--

function ArgParser:check_parsed()
  if not self.parsed then
    abort('You must call ArgParser:parse() first.')
  end
end

function ArgParser:parse(args, show_help)
  args = args or arg

  local function process_option(i, arg, value, type)
    local subn = type == 'long' and 3 or 2
    local option = self.options[arg:sub(subn)]

    if not option then
      throw('Unknown option: ' .. arg)
    end

    if option.type == 'flag' then
      option.value = true
      return i + 1
    else
      if i == 0 then
        local long = ''
        if option.long then
          long = ' (--' .. option.long .. ')'
        end
        throw(arg .. long .. ' is a non-flag option specified in a string of flags.')
      end
      if not value then
        throw('No value specified for option ' .. arg)
      end
      option.value = value
      return i + 2
    end
  end

  try(
    function()
      -- Parsing arguments and options.
      local i = 1
      local arg_idx = 1
      while i <= #args do
        local arg = args[i]
        if self:is_long_option(arg) then
          i = process_option(i, arg, args[i + 1], 'long')
        elseif self:is_short_option(arg) then
          if #arg == 2 then
            i = process_option(i, arg, args[i + 1], 'short')
          else
            for k = 2, #arg do
              process_option(0, '-' .. arg:sub(k, k), nil, 'short')
            end
            i = i + 1
          end
        else
          local a_name = self.args_names[arg_idx]
          local a = self.args[a_name]
          if not a then
            throw('Unknown argument: <' .. arg .. '>')
          end
          a.value = arg
          i = i + 1
          arg_idx = arg_idx + 1
        end
      end

      self.parsed = true

      -- Checking required arguments.
      for name, a in pairs(self.args) do
        if self.args_required[name] and not a.value then
          local required = str.join(', ', fun.filter(
                                            self.args_names,
                                            function(name)
                                              return self.args_required[name] == true
                                            end))
          throw('The following positional arguments are required: ' .. required)
        end
      end
    end,

    -- /catch/ --
    function(ex)
      io.stderr:write('Error: ' .. ex.message .. '\n\n')
      io.write(self:get_help())
      os.exit(1)
    end
  )
end

function ArgParser:get_help()
  local help = ''
  local function h(s)
    help = help .. s
  end
  
  local function wrap_help(s)
    local help_lines = str.split(str.wrap(s, 80), '\n')
    for i, v in ipairs(help_lines) do
      help_lines[i] = '    ' .. v
    end
    return str.join('\n', help_lines)
  end

  local prog_name = self.name
  if not prog_name then
    prog_name = arg[0]:match('[^/]+$')
  end

  h('Usage: ' .. prog_name .. ' ')
  for _, a_name in ipairs(self.args_names) do
    if not self.args[a_name].required then
      a_name = '[' .. a_name .. '] '
    else
      a_name = a_name .. ' '
    end
    h(a_name)
  end
  
  if #self.options then
    h('[options]')
  end
  
  if self.description then
    h('\n\n')
    h(self.description)
  end

  if #self.args_names then
    h('\n\n')
    h('Positional arguments:\n')
    for i, a_name in ipairs(self.args_names) do
      local arg_info = self.args[a_name]
      h('  ' .. a_name .. '\n')
      if arg_info.help then
        h(wrap_help(arg_info.help))
        h('\n')
      end
      if i ~= #self.args_names then
        h('\n')
      end
    end
  end

  if #self.options then
    if #self.args_names then
      h('\n')
    else
      h('\n\n')
    end
    h('Options:\n')
    for i, o in ipairs(self.options_list) do
      local name = ''
      if o.short then
        name = '-' .. o.short
      end
      if o.long then
        local comma = name and ', ' or ''
        name = name .. comma
        name = name .. '--' .. o.long
      end
      h('  ' .. name)
      if o.long then
        h(' <' .. string.upper(o.long) .. '>')
      else
        h(' <' .. string.upper(o.short) .. '>')
      end
      h('\n')
      if o.help then
        h(wrap_help(o.help))
        h('\n')
      end
      if i ~= #self.options_list then
        h('\n')
      end
    end
  end

  return help .. '\n'
end