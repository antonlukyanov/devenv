require "libswg"

lswg.open_window(640, 480, true) -- true - set client rect
lswg.clear(lswg.rgb(0, 255, 255))
lswg.setxor(true)
lx, ly = lswg.getsize()
print('lx=' .. lx, 'ly=' .. ly)

white = lswg.rgb(255, 255, 255)
blue = lswg.rgb(0, 0, 255)
red = lswg.rgb(255, 0, 0)
col1 = blue
col2 = red

tm = lswg.time()
while true do
  x1 = math.random(lx)-1
  y1 = math.random(ly)-1
  x2 = math.random(lx)-1
  y2 = math.random(ly)-1

  lswg.rectangle(x1, y1, x2, y2, white, col1)
  lswg.sleep(50)
  lswg.rectangle(x1, y1, x2, y2, white, col2)

  vk, ch = lswg.getkey()
  if vk then
    print('::', vk, ch, lswg.vk[vk])
  end
  if vk == lswg.vk.esc then
    os.exit()
  end

  x, y = lswg.getmouse()
  if x then
    print(x, y)
  end
  --print(lswg.time()-tm)
  tm = lswg.time()
end
