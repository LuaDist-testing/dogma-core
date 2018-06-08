--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--An iif() call.
local IifFn = {}
IifFn.__index = IifFn
setmetatable(IifFn, {__index = Terminal})
package.loaded[...] = IifFn

--Constructor.
function IifFn.new(ln, col, cond, onTrue, onFalse)
  local self

  --(1) create
  self = setmetatable(Terminal.new(TerminalType.IIF, {line = ln, col = col}), IifFn)
  self.cond = cond
  self.onTrue = onTrue
  self.onFalse = onFalse

  --(2) return
  return self
end

--@override
function IifFn:__tostring()
  return string.format(
    "(iif %s %s %s)",
    tostring(self.cond),
    tostring(self.onTrue),
    tostring(self.onFalse)
  )
end
