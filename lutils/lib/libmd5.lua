--[[
  ������� ��� �������� md5 � �������� ���
  ������� � ����� �� ������������ md5.
--]]

require "md5"

-- Returns the md5 hash value as a string of hexadecimal digits

function md5.hex(k)
  k = md5.sum(k)
  return (k:gsub(".", function (c)
           return string.format("%02x", string.byte(c))
         end))
end

return md5
