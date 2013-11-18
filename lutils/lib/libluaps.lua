--[[
  (c) ltwood, 2004, Sep (awk version)
  2004, Dec, port to Lua
  Библиотека функций для рисования в формате PostScript
--]]

local function _mm2pt( mm )
  return 72.0 * (mm / 25.4)
end

local _w_pt, _h_pt, _x1, _y1, _x2, _y2

local function header( w, h, fh )
  _w_pt = _mm2pt(w)
  _h_pt = _mm2pt(h)
  _x1, _y1 = 0, 0
  _x2 = w
  _y2 = h
  io.write("%!PS-Adobe-2.0 EPSF-2.0\n")
  io.write("%%Creator: luaps, (c) ltwood\n")
  io.write("%%Pages: 0 0\n")
  io.write("%%BoundingBox: 0.0 0.0 ", _w_pt, " ", _h_pt, "\n")
  io.write("%%EndComments\n");
  io.write("/Times-Roman findfont ", _mm2pt(fh), " scalefont setfont\n")
  io.write("0 0 translate\n")
end

local function trailer()
  io.write("showpage\n")
  io.write("%%Trailer\n")
end

local function viewport( x1, x2, y1, y2 )
  _x1 = x1
  _x2 = x2
  _y1 = y1
  _y2 = y2
end

local function _scale( x, a, b, c, d )
  return c + (d-c) * (x-a)/(b-a)
end

local function _x( x )
  return _scale(x, _x1, _x2, 0, _w_pt)
end

local function _y( y )
  return _scale(y, _y1, _y2, 0, _h_pt)
end

local function width( w )
  io.write(_mm2pt(w), " setlinewidth\n")
end

local function gray( g )
  io.write(g, " setgray\n")
end

local function fcirc( x, y, r )
  io.write(_x(x), " ", _y(y), " ", _mm2pt(r), " 0 360 newpath arc fill\n")
end

local function circ( x, y, r )
  io.write(_x(x), " ", _y(y), " ", _mm2pt(r), " 0 360 newpath arc stroke\n")
end

local function line( x1, y1, x2, y2 )
  io.write("newpath ", _x(x1), " ", _y(y1), " moveto ", _x(x2), " ", _y(y2), " lineto stroke\n")
end

-- рисование пути
-- coords = {{x1, y1}, {x2, y2}, ...}
local function path( coords )
  local n = #coords
  io.write("newpath ", _x(coords[1][1]), " ", _y(coords[1][2]), " moveto ")
  for i = 2, n do
    io.write(_x(coords[i][1]), " ", _y(coords[i][2]), " lineto ")
  end
  io.write("stroke\n")
end

local function frect( x1, y1, x2, y2 )
  io.write("newpath ",
    _x(x1), " ", _y(y1), " moveto ",
    _x(x2), " ", _y(y1), " lineto ",
    _x(x2), " ", _y(y2), " lineto ",
    _x(x1), " ", _y(y2), " lineto ",
    _x(x1), " ", _y(y1), " lineto fill\n")
end

local function rect( x1, y1, x2, y2 )
  io.write("newpath ",
    _x(x1), " ", _y(y1), " moveto ",
    _x(x2), " ", _y(y1), " lineto ",
    _x(x2), " ", _y(y2), " lineto ",
    _x(x1), " ", _y(y2), " lineto ",
    _x(x1), " ", _y(y1), " lineto stroke\n")
end

local function puts( x, y, s )
  local s1 = s:gsub("%(", "\\(")
  local s2 = s1:gsub("%)", "\\)")
  io.write(_x(x), " ", _y(y), " moveto ", "("..s..")", " show stroke\n")
end

local function grid( x, dx, nx, y, dy, ny, _j )
  for _j = 0, nx do
    line(x + _j*dx, y, x + _j*dx, y + ny*dy)
  end
  for _j = 0, ny do
    line(x, y + _j*dy, x + nx*dx, y + _j*dy)
  end
end

luaps = {
  put_header = header,
  put_trailer = trailer,
  set_viewport = viewport,
  set_linewidth = width,
  set_gray = gray,
  fcirc = fcirc,
  circ = circ,
  line = line,
  path = path,
  frect = frect,
  rect = rect,
  puts = puts,
  draw_grid = grid
}

return luaps
