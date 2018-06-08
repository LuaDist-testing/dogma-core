----A finally clause.
local FinallyCl = {}
FinallyCl.__index = FinallyCl
package.loaded[...] = FinallyCl

--Constructor.
--
--@param body:Body  Body sentences.
function FinallyCl.new(body)
  return setmetatable({
    body = body
  }, FinallyCl)
end
