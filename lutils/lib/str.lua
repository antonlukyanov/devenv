-- str.lua, 2016, (c) Anton Lukyanov

--- Additional string methods

local str = {}

function str.split(s, separator)
  separator = separator or ' '
  if type(separator) ~= 'string' then
    err('Separator must be a string.')
  end

  local parts = {}
  local pos = 1
  while true do
    local b, e = s:find(separator, pos)
    if not b then
      table.insert(parts, s:sub(pos))
      break
    end
    table.insert(parts, s:sub(pos, b - 1))
    pos = e + 1
  end

  return parts
end

function str.join(separator, list, i, j)
  return table.concat(list, separator, i, j)
end

function str.strip(s, chars, left, right)
  if type(s) ~= 'string' then
    err("Argument 's' must be a string.")
  end
  
  if left == nil then
    left = true
  end
  if right == nil then
    right = true
  end
  
  chars = chars or '%s\n\r\t'
  chars = '[' .. chars .. ']+'
  if left then
    s = s:gsub('^' .. chars, '')
  end
  if right then
    s = s:gsub(chars .. '$', '')
  end
  
  return s
end

function str.lstrip(s, chars)
  return str.strip(s, chars, true)
end

function str.rstrip(s, chars)
  return str.strip(s, chars, false, true)
end

function str.at(s, i)
  return s:sub(i, i)
end

function str.wrap(s, width)
  if not width then
    throw("You must specify 'width' value.")
  end
  
  -- Resulting string.
  local result = ''  
  
  local function add(v)
    result = result .. v
  end
  
  local function invisible(c)
    return c:match('[%s\n\t]')
  end

  -- Next word from s.
  local word = ''
  -- Number of characters in current line.
  local chars_n = 0

  for i = 1, #s do
    local c = str.at(s, i)
    if invisible(c) then
      while #word > 0 do        
        local avail = width - chars_n
        
        -- We can insert the whole word into the current line.
        if chars_n == 0 and avail >= #word or avail >= #word + 1 then
          -- We don't want spaces at the beginning of a new line.
          if chars_n ~= 0 then
            add(' ')
            chars_n = chars_n + 1
          end
          add(word)
          chars_n = chars_n + #word
          word = ''
        -- We cannot insert the whole word into the line.
        elseif #word >= width then
          -- At least space (if it is beginning of a line) + one char from word.
          if chars_n == 0 and avail >= 1 then
            local head = word:sub(1, chars_n == 0 and avail or avail-1)
            if chars_n ~= 0 then
              add(' ')
              chars_n = chars_n + 1
            end
            add(head)
            chars_n = chars_n + #head
            word = word:sub(avail+1)
          -- We cannot split the word and we start a new line.
          else
            add('\n')
            chars_n = 0
          end
        -- We can insert the current word into the next line.        
        else
          add('\n')
          chars_n = 0
        end
        
        if chars_n == width and #s ~= i then
          add('\n')
          chars_n = 0
        end
      end
    else
      word = word .. c
    end
  end
  
  return result
end

return str