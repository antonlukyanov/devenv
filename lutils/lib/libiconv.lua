require "luaiconv"

function iconvert( to, from, text )
  local cd = iconv.new(to, from)
  assert(cd, "iconv: failed to create a converter object.")
  local ostr, err = cd:iconv(text)

  if err == iconv.ERROR_INCOMPLETE then
    error("iconv: incomplete input")
  elseif err == iconv.ERROR_INVALID then
    error("iconv: invalid input")
  elseif err == iconv.ERROR_NO_MEMORY then
    error("iconv: failed to allocate memory")
  elseif err == iconv.ERROR_UNKNOWN then
    error("iconv: unknown error")
  end

  return ostr
end
