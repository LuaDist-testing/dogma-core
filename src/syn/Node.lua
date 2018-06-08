--A node.
local Node = {}
Node.__index = Node
package.loaded[...] = Node

--Constructor.
--
--@param t:string           Node type.
function Node.new(t, tok)
  return setmetatable({
    type = t,
    parent = nil,
    token = tok
  }, Node)
end
