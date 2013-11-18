require "lualwml"

bmp = vbmp.load('lena512g.bmp')

m = bmp:matrix()
bmp:save('lena512g_matr.bmp')
ns, nc = m:size()

i = matrix.new(ns, nc, 0.0)
sr, si = fft.cfft2d(m, i)

p = matrix.new(ns, nc)
for s = 0, ns-1 do
  for c = 0, nc-1 do
    local v = sr:get(s,c)^2 + si:get(s, c)^2
    p:set(s, c, math.log10(v))
  end
end
p:vbmp():save('spectrum.bmp')
min, max = p:stat()
print('pwsp: min_log=' .. min, 'max_log=' .. max)

thr = min + 0.25 * (max - min)
for s = 0, ns-1 do
  for c = 0, nc-1 do
    if p:get(s, c) < thr then
      sr:set(s, c, 0.0)
      si:set(s, c, 0.0)
      p:set(s, c, -10)
    end
  end
end
p:vbmp():save('spectrum_half.bmp')

mr, mi = fft.cifft2d(sr, si)
print('im(rev) stat:', mi:stat())
mr:vbmp():save('lena512g_rev.bmp')
