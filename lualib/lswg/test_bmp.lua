require "libswg"

lswg.open_window()
lx, ly = lswg.getsize()
print('lx=' .. lx, 'ly=' .. ly)

b = lswg.load('sp.bmp')
b_lx, b_ly = lswg.imgsize(b)
print(b_lx, b_ly)
s = lswg.load('gr.bmp')
print(lswg.imgsize(s))

col = lswg.rgb(0, 255, 255)
--lswg.clear(col)
lswg.fill(s)

math.randomseed(os.time());
x = math.random(lx)-1
y = math.random(ly)-1
dx = 1
dy = 1

lswg.setauto(false)
while true do
  lswg.put(b, x, y, true)
  lswg.puttext(x+25, y+5, "Test", lswg.rgb(255, 255, 255))
  lswg.update()
  lswg.sleep()
  --lswg.clear(col)
  lswg.fill(s)
  x = x + dx
  y = y + dy

  vk = lswg.getkey()
  if vk == lswg.vk.esc then
    os.exit()
  end

  if x < 0 then
    dx = math.abs(dx)
  elseif x + b_lx > lx then
    dx = -math.abs(dx)
  end
  if y < 0 then
    dy = math.abs(dy)
  elseif y + b_ly > ly then
    dy = -math.abs(dy)
  end
end
