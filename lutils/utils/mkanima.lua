require "libmacro"

--[[
  ѕо файлу, содержащему список имен файлов с изображени€ми (по одному в строке),
  генерирует html, показывающий анимированное изображение средствами JavaScript.
--]]

params = {
  start_delay = 100,
  max_delay = 4000,
  min_delay = 1,
  mul = math.sqrt(2),
}

templ = [[
<SCRIPT>
delay = ${delay}
img_num = ${img_num}
max_delay = ${max_delay}
min_delay = ${min_delay}
mul = ${mul}

names = new Array()
${names}

// Preload animation images
theImages = new Array()
for( i = 0; i < img_num; i++ ){
  theImages[i] = new Image()
  theImages[i].src = names[i]
}

cur_idx = 0

function animate() {
  document.animation.src = theImages[cur_idx].src
  cur_idx++   
  if( cur_idx > img_num-1 ) {
    cur_idx = 0
  }
}

function slower() {
  delay *= mul
  if( delay > max_delay ) delay = max_delay
}

function faster() {
   delay /= mul
   if( delay < min_delay ) delay = min_delay
}
</SCRIPT>

<BODY BGCOLOR="white">
 <IMG NAME="animation" SRC="${first_file}" onLoad="setTimeout('animate()', delay)">
<FORM>  
<INPUT TYPE="button" Value="Slower" onClick="slower()">
<INPUT TYPE="button" Value="Faster" onClick="faster()">
</FORM>
</BODY>
]]

if #arg ~= 1 then
  io.write('Usage: lua mkanima.lua filelist\n')
  os.exit()
end

fnm = arg[1]
ofn = fnm .. '.htm'

local lst = ""
local j = 0
local first_file = nil
for s in io.lines(fnm) do
  if not first_file then first_file = s end
  lst = lst .. string.format('names[%d] = "%s"\n', j, s)
  j = j + 1
end

stbl = {
  first_file = first_file,
  names = lst,
  img_num = j,
  delay = params.start_delay,
  max_delay = params.max_delay,
  min_delay = params.min_delay,
  mul = params.mul,
}

io.output(ofn)
io.write(macro.subst(templ, stbl))
