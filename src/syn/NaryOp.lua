--imports
local Op = require("dogma.syn._.Op")

--A n-ary operator.
local NaryOp = {}
NaryOp.__index = NaryOp
setmetatable(NaryOp, {__index = Op})
package.loaded[...] = NaryOp

--Constructor.
--
--@param tok:Token
function NaryOp.new(tok)
  local self

  --(1) create
  self = setmetatable(Op.new("n", tok), NaryOp)
  self.children = {}
  self.finished = false

  --(2) return
  return self
end

--@override
function NaryOp:insert(node)
  if self.finished then
    error(string.format(
      "(%s,%s): node can't be inserted to full call.",
      node.tok.line,
      node.tok.col
    ))
  end

  table.insert(self.children, node)
end

--@override
function NaryOp.remove()
  error("call operator can't remove children.")
end

--@override
function NaryOp:isWellFormed()
  return self.finished
end
