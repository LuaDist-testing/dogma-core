--A catch clause.
local CatchCl = {}
CatchCl.__index = CatchCl
package.loaded[...] = CatchCl

--Constructor.
--
--@param var:string Exception variable name.
--@param body:Body  Body sentences.
function CatchCl.new(var, body)
  return setmetatable({
    var = var,
    body = body
  }, CatchCl)
end
