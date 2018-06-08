--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--A pawait call.
local PawaitFn = {}
PawaitFn.__index = PawaitFn
setmetatable(PawaitFn, {__index = Terminal})
package.loaded[...] = PawaitFn

--Constructor.
function PawaitFn.new(ln, col, exp)
  local self

  --(1) create
  self = setmetatable(Terminal.new(TerminalType.PAWAIT, {line = ln, col = col}), PawaitFn)
  self.exp = exp

  --(2) return
  return self
end

--@override
function PawaitFn:__tostring()
  return string.format("(pawait %s)", tostring(self.exp))
end
