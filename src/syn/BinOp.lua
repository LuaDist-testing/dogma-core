--imports
local Op = require("dogma.syn._.Op")

--A binary operator.
local BinOp = {}
BinOp.__index = BinOp
setmetatable(BinOp, {__index = Op})
package.loaded[...] = BinOp

--Constructor.
--
--@param tok:Token
function BinOp.new(tok)
  local self

  --(1) create
  self = setmetatable(Op.new("b", tok), BinOp)
  self.children = {}

  --(2) return
  return self
end

--@override
function BinOp:insert(node)
  -- if #self.children == 2 then
  --   error("children already set.")
  -- end

  table.insert(self.children, node)
  node.parent = self
end

--@override
function BinOp:remove(node)
  -- if #self.children == 0 then
  --   error("no child to remove from the operator.")
  -- end

  return table.remove(self.children)
end

--@override
function BinOp:isWellFormed()
  return #self.children == 2
end

--@override
function BinOp:__tostring()
  return string.format("(%s %s %s)", self.op, self.children[1], self.children[2])
end
