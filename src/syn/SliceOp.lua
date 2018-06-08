--imports
local Op = require("dogma.syn._.Op")

--A slice operator: [,].
local SliceOp = {}
SliceOp.__index = SliceOp
setmetatable(SliceOp, {__index = Op})
package.loaded[...] = SliceOp

--Constructor.
--
--@param tok:Token
function SliceOp.new(tok)
  local self

  self = setmetatable(Op.new("t", tok), SliceOp)
  self.children = {}

  return self
end

--@override
function SliceOp:insert(node)
  -- if #self.children == 3 then
  --   error("children already set.")
  -- end

  table.insert(self.children, node)
end

--@override
-- function SliceOp.remove()
--   error("slice operator can't remove children.")
-- end

--@override
function SliceOp:isWellFormed()
  return #self.children == 3
end

--@override
function SliceOp:__tostring()
  return string.format("(%s %s %s %s)", self.op, self.children[1], self.children[2], self.children[3])
end
