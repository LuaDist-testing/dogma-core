--imports
local NaryOp = require("dogma.syn._.NaryOp")

--A
local PackOp = {}
PackOp.__index = PackOp
setmetatable(PackOp, {__index = NaryOp})
package.loaded[...] = PackOp

--Constructor.
--
--@param tok:Token
--@param
function PackOp.new(tok)
  local self

  --(1) create
  self = setmetatable(NaryOp.new(tok), PackOp)
  self.children = {}
  self.finished = false

  --(2) return
  return self
end

--@override
function NaryOp:__tostring()
  local ops

  --(1) get expressions
  for ix, op in ipairs(self.children) do
    if ix == 1 then
      ops = op:__tostring()
    else
      ops = ops .. " " .. op.visib .. op.name
    end
  end

  --(2) return
  return string.format("(pack %s)", ops)
end
