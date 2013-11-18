require "libswg"

lswg.open_window()
lswg.clear(lswg.rgb(0, 255, 255))
lswg.setxor(true)
lx, ly = lswg.getsize()
print('lx=' .. lx, 'ly=' .. ly)

white = lswg.rgb(255, 255, 255)
blue = lswg.rgb(0, 0, 255)
red = lswg.rgb(255, 0, 0)
col1 = blue
col2 = red

lswg.setauto(false)
while true do
  x1 = math.random(lx)-1
  y1 = math.random(ly)-1
  x2 = math.random(lx)-1
  y2 = math.random(ly)-1

  lswg.rectangle(x1, y1, x2, y2, white, col1)
  lswg.sleep(10)
  lswg.rectangle(x1, y1, x2, y2, white, col2)

  vk = lswg.getkey()
  if vk then
    print('::', vk, lswg.vk[vk])
  end
  if vk == lswg.vk.cnt then
    lswg.settextalign("l")
    lswg.setfont("Times New Roman", 24)
    lswg.puttext(100, 100, "Test Text", blue)
    lswg.update()
  end
  if vk == lswg.vk.esc then
    os.exit()
  end
end
