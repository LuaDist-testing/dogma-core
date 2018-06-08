--imports
local Op = require("dogma.syn._.Op")

--A ternary operator.
local CallOp = {}
CallOp.__index = CallOp
setmetatable(CallOp, {__index = Op})
package.loaded[...] = CallOp

--Constructor.
--
--@param tok:Token
function CallOp.new(tok)
  local self

  --(1) create
  self = setmetatable(Op.new("n", tok), CallOp)
  self.children = {}
  self.finished = false

  --(2) return
  return self
end

--@override
function CallOp:insert(node)
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
function CallOp.remove()
  error("call operator can't remove children.")
end

--@override
function CallOp:isWellFormed()
  return self.finished
end

--@override
function CallOp:__tostring()
  local ops

  --(1) get expressions
  ops = ""
  for _, op in ipairs(self.children) do
    ops = ops .. (ops == "" and "" or " ") .. op:__tostring()
  end

  --(2) return
  return string.format("(call %s)", ops)
end
