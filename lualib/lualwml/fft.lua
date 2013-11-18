require "lualwml"

function mkarray( a )
  local r = array.new(#a)
  for j = 0, #a-1 do
    r[j] = a[j+1]
  end
  return r
end

xr = mkarray({ 1, 2, 3, 4, 5 })
xi = mkarray({ 0, 0, 0, 0, 0 })

a, b = fft.cfft(xr, xi)
xr, xi = fft.cifft(a, b)

print(#a)
print(a)
for j = 0, #a-1 do
  print(a[j], b[j])
end

print(#xr)
print(xr)
for j = 0, #xr-1 do
  print(xr[j], xi[j])
end
