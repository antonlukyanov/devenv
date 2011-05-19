require "libfname"

function test( src, sbe )
  if fname.compact_path(src) ~= sbe then
    print('src=<'..src..'>', 'res=<'..fname.compact_path(src)..'>', 'expected=<'..sbe..'>')
  end
end

test('.', '')
test('./', '')
test('/', '/')
test('//', '/')
test('///', '/')
test('/asd', '/asd/')
test('./asd', 'asd/')
test('asd/qwe', 'asd/qwe/')
test('asd//qwe', 'asd/qwe/')
test('asd/./qwe', 'asd/qwe/')
test('asd/.//qwe', 'asd/qwe/')
test('asd/././qwe', 'asd/qwe/')
test('asd/../asd/../qwe', 'qwe/')
test('asd/../../../qwe', '../../qwe/')
