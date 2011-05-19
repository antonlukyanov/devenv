--[[
  Формирует шаблон модуля приложения -- файлы с расширением ".h" и ".сс".
--]]

require "libmacro"

if #arg ~= 2 then
  io.write('Usage: lua mkam.lua filename namespace\n')
  os.exit()
end

nm = arg[1]
nmsp = arg[2]

tbl = {
  NM = nm,
  UNM = nm:upper(),
  NMSP = nmsp,
}

-- h

text = [[
//!! type title here
// lwml, (c) ltwood

#ifndef _${UNM}_
#define _${UNM}_

#include "defs.h"
#include "mdefs.h"

/*#build_stop*/

namespace ${NMSP} {

using namespace lwml; //!! comment this line for lwml modules


}; // namespace ${NMSP}

#endif // _${UNM}_
]]

io.output(nm .. '.h')
io.write(macro.subst(text, tbl))
io.close()

-- cc

text = [[
#include "${NM}.h"

/*#build_stop*/

namespace ${NMSP} {


}; // namespace ${NMSP}
]]

io.output(nm .. '.cc')
io.write(macro.subst(text, tbl))
io.close()
