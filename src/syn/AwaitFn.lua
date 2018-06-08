--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--An await call.
local AwaitFn = {}
AwaitFn.__index = AwaitFn
setmetatable(AwaitFn, {__index = Terminal})
package.loaded[...] = AwaitFn

--Constructor.
function AwaitFn.new(ln, col, exp)
  local self

  --(1) create
  self = setmetatable(Terminal.new(TerminalType.AWAIT, {line = ln, col = col}), AwaitFn)
  self.exp = exp

  --(2) return
  return self
end

--@override
function AwaitFn:__tostring()
  return string.format("(await %s)", tostring(self.exp))
end
