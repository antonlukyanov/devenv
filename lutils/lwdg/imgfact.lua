require "lualwml"

function usage()
  io.write('Image factory, (c) ltwood\n')
  io.write('usage: lua imgfact command parameters\n\n')
  io.write('  lua imgfact img2dat infilename.bmp outfilename.dat\n')
  io.write('  lua imgfact dat2img infilename.dat outfilename.bmp\n')
  io.write('  lua imgfact equalize infilename.bmp outfilename.bmp [hstlen]\n')
  io.write('  lua imgfact requantify infilename.bmp outfilename.bmp levelnum\n')
  io.write('  lua imgfact decimate infilename.bmp outfilename.bmp decfactor\n')
  io.write('  lua imgfact thresholding infilename.bmp outfilename.bmp threshold\n')
  io.write('  lua imgfact sobel infilename.bmp outfilename.bmp\n')
  io.write('  lua imgfact filter infilename.bmp outfilename.bmp center cross diag\n')
  io.write('  lua imgfact mkdiff infilename1.bmp infilename2.bmp outfilename.bmp\n')
  io.write('  lua imgfact diff infilename1.bmp infilename2.bmp\n')
  io.write('  lua imgfact stat infilename.bmp\n')
  io.write('  lua imgfact hist infilename.bmp outfilename.dat [histlen]\n')
  io.write('  lua imgfact crop infilename.bmp outfilename.bmp x0 y0 lx ly\n')
  io.write('  lua imgfact hsect infilename.bmp outfilename.dat y0 [ly]\n')
  io.write('  lua imgfact vsect infilename.bmp outfilename.dat x0 [lx]\n')
  io.write('  lua imgfact gaussblur infilename.bmp outfilename.bmp sigmax sigmay [phi_deg]\n')
  io.write('  lua imgfact sqgaussblur infilename.bmp outfilename.bmp half_sq sigma\n')
  io.write('  lua imgfact resample infilename.bmp outfilename.bmp new_lx new_ly [radius]\n')
  io.write('  lua imgfact resize infilename.bmp outfilename.bmp incfactor\n')
  io.write('  lua imgfact median infilename.bmp outfilename.bmp apt\n')
  io.write('  lua imgfact rot infilename.bmp outfilename.bmp angle\n')
  os.exit()
end

if #arg == 0 then
  usage()
end

cmd = arg[1]

function test( idx )
  if arg[idx] == nil then
    usage()
  else
    return arg[idx]
  end
end

function optn( idx )
  return arg[idx]
end

function img2dat( ifn, ofn )
  assert(vbmp.load(ifn)):save_matrix(ofn)
end

function dat2img( ifn, ofn )
  assert(vbmp.load_matrix(ifn)):save(ofn)
end

function equalize( ifn, ofn, hst_len )
  b = assert(vbmp.load(ifn))
  if hst_len then
    b:equalize(hst_len):save(ofn)
  else
    b:equalize():save(ofn)
  end
end

function requantify( ifn, ofn, lev_num )
  b = assert(vbmp.load(ifn))
  b:requantify(lev_num):save(ofn)
end

function decimate( ifn, ofn, dec )
  b = assert(vbmp.load(ifn))
  b:decimate(dec):save(ofn)
end

function thresholding( ifn, ofn, dec )
  b = assert(vbmp.load(ifn))
  b:thresholding(dec):save(ofn)
end

function sobel( ifn, ofn )
  b = assert(vbmp.load(ifn))
  b:sobel():save(ofn)
end

function filter( ifn, ofn, cnt, cross, diag )
  b = assert(vbmp.load(ifn))
  b:filter(cnt, cross, diag):save(ofn)
end

function mkdiff( ifn1, ifn2, ofn )
  b1 = assert(vbmp.load(ifn1))
  b2 = assert(vbmp.load(ifn2))
  r = vbmp.mkdiff(b1, b2)
  r:save(ofn)
  io.write(string.format('min=%f max=%f mid=%f var=%f\n', r:stat()))
end

function diff( ifn1, ifn2 )
  b1 = assert(vbmp.load(ifn1))
  b2 = assert(vbmp.load(ifn2))
  io.write(string.format('img1: min=%f max=%f mid=%f var=%f\n', b1:stat()))
  io.write(string.format('img2: min=%f max=%f mid=%f var=%f\n', b2:stat()))
  io.write(string.format("diff: max=%f mid=%f", vbmp.diff(b1, b2)))
end

function stat( ifn )
  b = assert(vbmp.load(ifn))
  io.write(string.format('min=%f max=%f mid=%f var=%f\n', b:stat()))
end

function hist( ifn, ofn, len )
  b = assert(vbmp.load(ifn))
  if len then
    array.save(b:hist(len), ofn)
  else
    array.save(b:hist(), ofn)
  end
end

function crop( ifn, ofn, x0, y0, lx, ly )
  b = assert(vbmp.load(ifn))
  b:crop(x0, y0, lx, ly):save(ofn)
end

function hsect( ifn, ofn, y0, ly )
  b = assert(vbmp.load(ifn))
  if ly then
    array.save(b:hsect(y0, ly), ofn)
  else
    array.save(b:hsect(y0), ofn)
  end
end

function vsect( ifn, ofn, x0, lx )
  b = assert(vbmp.load(ifn))
  if lx then
    array.save(b:hsect(x0, lx), ofn)
  else
    array.save(b:hsect(x0), ofn)
  end
end

function gaussblur( ifn, ofn, sx, sy, phi)
  b = assert(vbmp.load(ifn))
  if phi then
    b:gaussblur(sx, sy, math.rad(phi)):save(ofn)
  else
    b:gaussblur(sx, sy):save(ofn)
  end
end

function sqgaussblur( ifn, ofn, half_sq, sigma)
  b = assert(vbmp.load(ifn))
  b:sqgaussblur(half_sq, sigma):save(ofn)
end

function resample( ifn, ofn, new_lx, new_ly, r)
  b = assert(vbmp.load(ifn))
  if r then
    b:resample(new_lx, new_ly, r):save(ofn)
  else
    b:resample(new_lx, new_ly):save(ofn)
  end
end

function resize( ifn, ofn, fact )
  b = assert(vbmp.load(ifn))
  b:resize(fact):save(ofn)
end

function median( ifn, ofn, apt )
  b = assert(vbmp.load(ifn))
  b:median(apt):save(ofn)
end

function rot( ifn, ofn, angle )
  b = assert(vbmp.load(ifn))
  b:rot(math.rad(angle)):save(ofn)
end

if cmd == 'img2dat' then
  img2dat(test(2), test(3))
elseif cmd == 'dat2img' then
  dat2img(test(2), test(3))
elseif cmd == 'equalize' then
  equalize(test(2), test(3), optn(4))
elseif cmd == 'requantify' then
  requantify(test(2), test(3), test(4))
elseif cmd == 'decimate' then
  decimate(test(2), test(3), test(4))
elseif cmd == 'thresholding' then
  thresholding(test(2), test(3), test(4))
elseif cmd == 'sobel' then
  sobel(test(2), test(3))
elseif cmd == 'filter' then
  filter(test(2), test(3), test(4), test(5), test(6))
elseif cmd == 'mkdiff' then
  mkdiff(test(2), test(3), test(4))
elseif cmd == 'diff' then
  diff(test(2), test(3))
elseif cmd == 'stat' then
  stat(test(2))
elseif cmd == 'hist' then
  hist(test(2), test(3), optn(4))
elseif cmd == 'crop' then
  crop(test(2), test(3), test(4), test(5), test(6), test(7))
elseif cmd == 'hsect' then
  hsect(test(2), test(3), test(4), optn(5))
elseif cmd == 'vsect' then
  vsect(test(2), test(3), test(4), optn(5))
elseif cmd == 'gaussblur' then
  gaussblur(test(2), test(3), test(4), test(5), optn(6) )
elseif cmd == 'sqgaussblur' then
  sqgaussblur(test(2), test(3), test(4), test(5))
elseif cmd == 'resample' then
  resample(test(2), test(3), test(4), test(5), optn(6))
elseif cmd == 'resize' then
  resize(test(2), test(3), test(4))
elseif cmd == 'median' then
  median(test(2), test(3), test(4))
elseif cmd == 'rot' then
  rot(test(2), test(3), test(4))
else
  usage()
end
