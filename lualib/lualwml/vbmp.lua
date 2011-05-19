require "lualwml"

im = vbmp.new()
print(im)

im = vbmp.load("test.jpg")
print(im)
im:save("copy.bmp")
