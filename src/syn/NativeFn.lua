--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--A native code.
local NativeFn = {}
NativeFn.__index = NativeFn
setmetatable(NativeFn, {__index = Terminal})
package.loaded[...] = NativeFn

--Constructor.
function NativeFn.new(ln, col, code)
  local self

  --(1) create
  self = setmetatable(Terminal.new(TerminalType.NATIVE, {line = ln, col = col}), NativeFn)
  self.code = code

  --(2) return
  return self
end

--@override
function NativeFn:__tostring()
  return string.format('(native "%s")', self.code)
end
