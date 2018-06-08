--imports
local tablex = require("pl.tablex")
local Op = require("dogma.syn._.Op")
local NodeType = require("dogma.syn.NodeType")

--Unary operator.
local UnaryOp = {}
UnaryOp.__index = UnaryOp
setmetatable(UnaryOp, {__index = Op})
package.loaded[...] = UnaryOp

--Constructor.
--
--@param tok:Token
function UnaryOp.new(tok)
  local self

  --(1) create
  self = setmetatable(Op.new("u", tok), UnaryOp)
  self.child = nil

  --(2) return
  return self
end

--@override
function UnaryOp:insert(node)
  --(1) pre
  if tablex.find({".", ":"}, self.op) then
    if not (node.type == NodeType.TERMINAL and node:isId()) then
      error(string.format(
        "on (%s, %s), '.' and ':' must be followed by identifier.",
        node.token.line,
        node.token.col
      ))
    end
  end

  --(2) add
  self.child = node
  node.parent = self
end

--@override
function UnaryOp:remove()
  local c = self.child
  self.child = nil
  return c
end

--@override
function UnaryOp:isWellFormed()
  return not not self.child
end

--@override
function UnaryOp:__tostring()
  return string.format("(%s %s)", self.op, self.child)
end
