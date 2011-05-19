require "lswg"

local function rgb( r, g, b )
  return (b * 256 + g) * 256 + r
end

lswg.rgb = rgb

local vk_tbl = {
  esc = 27,
  left = 37,
  right = 39,
  down = 40,
  up = 38,
  home = 36,
  ['end'] = 35,
  pgdn = 34,
  pgup = 33,
  cnt = 12,
  enter = 13,
  space = 32,
  ctrl = 17,
  shift = 16,
  plus = 107,
  minus = 109,
}

lswg.vk = {}
for nm, vk in pairs(vk_tbl) do
  lswg.vk[nm] = vk
  lswg.vk[vk] = nm
end
