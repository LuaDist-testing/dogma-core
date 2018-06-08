--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--An (if Exp then Exp else Exp) subexpression.
local IfSubExp = {}
IfSubExp.__index = IfSubExp
setmetatable(IfSubExp, {__index = Terminal})
package.loaded[...] = IfSubExp

--Constructor.
function IfSubExp.new(ln, col, cond, ifTrue, ifFalse)
  local self

  --(1) create
  self = setmetatable(Terminal.new(TerminalType.IF, {line = ln, col = col}), IfSubExp)
  self.cond = cond
  self.trueCase = ifTrue
  self.falseCase = ifFalse

  --(2) return
  return self
end

--@override
function IfSubExp:__tostring()
  return string.format(
    "(if %s %s %s)",
    tostring(self.cond),
    tostring(self.trueCase),
    tostring(self.falseCase)
  )
end
