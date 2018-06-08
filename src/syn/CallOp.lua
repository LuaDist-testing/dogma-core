--imports
local NaryOp = require("dogma.syn._.NaryOp")

--A call operator.
local CallOp = {}
CallOp.__index = CallOp
setmetatable(CallOp, {__index = NaryOp})
package.loaded[...] = CallOp

--Constructor.
--
--@param tok:Token
function CallOp.new(tok)
  local self

  --(1) create
  self = setmetatable(NaryOp.new(tok), CallOp)
  self.children = {}
  self.finished = false

  --(2) return
  return self
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
