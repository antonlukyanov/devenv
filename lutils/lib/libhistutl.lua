-- функции для построения гистограммы

local function minmax( d )
  local min, max = d[1], d[1]
  for j = 2, #d do
    if d[j] > max then max = d[j] end
    if d[j] < min then min = d[j] end
  end
  return min, max
end

local function val2idx( x, ax, bx, len )
  local idx = math.floor(len * (x - ax) / (bx - ax))
  return ((idx == len) and len) or idx + 1
end

local function idx2val( idx, ax, bx, len )
  local st = ( bx - ax ) / len
  return ax + (idx-1) * st, ax + idx * st, ax + (idx-0.5) * st
end

local function mk_hist( data, num )
  local min, max = minmax(data)

  local hist = {}
  for j = 1, num do hist[j] = 0 end
  for j = 1, #data do
    local idx = val2idx(data[j], min, max, num)
    hist[idx] = hist[idx] + 1
  end

  hist.min, hist.max = min, max
  return hist
end

local function wr_hist( fn, hist )
  local file = io.open(fn, 'wt')
  file:write('set grid\n')
  file:write('unset key\n')
  file:write('set xrange [', hist.min, ':', hist.max, ']\n')
  file:write('plot "-" with boxes\n')

  for j = 1, #hist do
    local va, vb, vc = idx2val(j, hist.min, hist.max, #hist)
    file:write(vc, ' ', hist[j], '\n')
  end
  file:write('e\n')
  file:close()
end

histutl = {
  make = mk_hist,
  write = wr_hist,
}
