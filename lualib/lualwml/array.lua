require "lualwml"

a = array.new(200)
b = array.new(10, 0.0)
c = array.new()
array.resize(a, 2000)
array.setval(b, 23)
array.resize(c, 123)
print(a, b, c)

for j = 0, #a-1 do
  a[j] = b[9]
end

print(a[#a-1])
print(array.stat(a))
