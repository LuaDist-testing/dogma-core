--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--A protected call.
local PevalFn = {}
PevalFn.__index = PevalFn
setmetatable(PevalFn, {__index = Terminal})
package.loaded[...] = PevalFn

--Constructor.
function PevalFn.new(ln, col, exp)
  local self

  --(1) create
  self = setmetatable(Terminal.new(TerminalType.PEVAL, {line = ln, col = col}), PevalFn)
  self.exp = exp

  --(2) return
  return self
end

--@override
function PevalFn:__tostring()
  return string.format("(peval %s)", tostring(self.exp))
end
