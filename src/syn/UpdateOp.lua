--imports
local NaryOp = require("dogma.syn._.NaryOp")

--An update op: Exp.{...} or Exp:{...}.
local UpdateOp = {}
UpdateOp.__index = UpdateOp
setmetatable(UpdateOp, {__index = NaryOp})
package.loaded[...] = UpdateOp

--Constructor.
--
--@param tok:Token
--@param
function UpdateOp.new(tok, visib)
  local self

  --(1) create
  self = setmetatable(NaryOp.new(tok), UpdateOp)
  self.visib = visib
  self.children = {}
  self.finished = false

  --(2) return
  return self
end

--@override
function UpdateOp:__tostring()
  local ops

  --(1) get expressions
  for ix, op in ipairs(self.children) do
    if ix == 1 then
      ops = tostring(op)
    else
      for _, name in ipairs(type(op.name) == "string" and {op.name} or op.name) do
        ops = ops .. " " .. string.format(
          "%s%s%s%s",
          op.type == "mapped" and "{" or (op.type == "extended" and "(" or ""),
          self.visib,
          name,
          op.type == "mapped" and "}" or (op.type == "extended" and ")" or "")
        )

        if op.value then
          ops = ops .. op.assign .. tostring(op.value)
        end
      end
    end
  end

  --(2) return
  return string.format("(update %s)", ops)
end
