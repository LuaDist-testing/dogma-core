--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--A use call.
local UseFn = {}
UseFn.__index = UseFn
setmetatable(UseFn, {__index = Terminal})
package.loaded[...] = UseFn

--Constructor.
function UseFn.new(ln, col, exp)
  local self

  --(1) create
  self = setmetatable(Terminal.new(TerminalType.USE, {line = ln, col = col}), UseFn)
  self.exp = exp

  --(2) return
  return self
end

--@override
function UseFn:__tostring()
  return string.format("(use %s)", tostring(self.exp))
end
