-- Система управления требованиями
-- (c) ltwood, 2006

require "libhtml"

--[[
  Файл описания требований содержит таблицу требований
  и вызывает функцию rcs(), передавая ей эту таблицу и имя проекта.

  Таблица требований представляет собой массив (числовые индексы) требований.
  Каждое требование представляет собой таблицу со следующими полями:

    type       -- тип записи
    date       -- дата появления записи в формате YYYY.MM.DD
    from       -- источник записи (имя или слово 'customer')
    to       * -- адресат записи (имя)
    content    -- содержание записи
    state      -- состояние записи
    comment  * -- комментарий к состоянию записи

  Звездочкой помечены необязательные поля.

  Допустимые типы записей:

    request    -- запрос на функциональность
    bug        -- запрос на багфикс
    decision   -- проектное решение (иногда фича -- узаконенный баг)

  Допустимые состояния записи:

    active     -- активна
    done       -- завершена (требование выполнено)
    frozen     -- запись заморожена (требование потеряло актуальность)
    transfered -- запись перенесена (превратилась в одну или несколько других записей)

  Для замороженных и перенесенных записей комментарий (comment) обязателен.
  Он должен пояснять причину заморозки или переноса.

  Смысл некоторых состояний:
    -- Заморозка бага означает его фактическое отсутствие.
    -- Завершение требования означает отказ от него.
    -- Заморозка проектного решения разрешена, но вряд ли осмысленна.

  Трансфер записи может произойти в результате детализации требования
  (при этом оно обычно разбивается на более мелкие задачи),
  при изменении типа записи (например когда баг превращается в фичу -- decision),
  при изменении адресата записи (обычно в случае запроса на багфикс).
--]]

-- data validator

local field_set = {
  type=1, date=1, from=1, to=1, content=1, state=1, comment=1
}
local req_fields = {
  "type", "date", "from", "content", "state"
}
local type_set = {
  request=1, bug=1, decision=1
}
local state_set = {
  active=1, done=1, frozen=1, transfered=1
}
local req_comment_state_set = {
  frozen=1, transfered=1
}

local function validate( data )
  for _, r in ipairs(data) do
    -- проверка допустимости всех полей
    for f, v in pairs(r) do
      if field_set[f] == nil then
        error('unknown field: ' .. f)
      end
    end

    -- проверка наличия обязательных полей
    for _, rf in ipairs(req_fields) do
      if r[rf] == nil then
        error('field expected: ' .. rf)
      end
    end

    -- проверка допустимости типа записи
    if type_set[r.type] == nil then
      error('unknown record type: ' .. r.type)
    end

    -- проверка допустимости состояния записи
    if state_set[r.state] == nil then
      error('unknown record state: ' .. r.state)
    end

    -- проверка наличия комментария для некоторых состояний записи
    if req_comment_state_set[r.state] ~= nil and r.comment == nil then
      error('comment expected for state: ' .. r.state)
    end
  end
end

-- html generator

local html_fields = {
  "type", "date", "from", "to", "content", "state", "comment"
}

local titles = {
  type = "Type", 
  date = "Date", 
  from = "From", 
  to = "To", 
  content = "Content", 
  state = "State",
  comment = "Comment", 
}

local function mkhtml( data, fname, mode )
  io.output(fname)

  html.write_header()
  io.write('<table border=1 width=100%>\n')

  io.write('<tr>')
  for _, f in ipairs(html_fields) do
    io.write('<td><b>' .. titles[f] .. '</b></td>')
  end
  io.write('</tr>\n')

  for _, r in ipairs(data) do
    if (mode == 'all') or (not mode and r.state=='active') then
      io.write('<tr>')
      for _, f in ipairs(html_fields) do
        local ss = (r[f] and tostring(r[f])) or '&nbsp;'
        io.write('<td>' .. ss .. '</td>')
      end
      io.write('</tr>\n')
    end
  end

  io.write('</table>\n')
  html.write_trailer()
end

-- export

function rcs( data, pname, mode )
  validate(data)
  mkhtml(data, pname .. '.htm', mode)
end
