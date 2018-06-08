--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--A throw function.
local ThrowFn = {}
ThrowFn.__index = ThrowFn
setmetatable(ThrowFn, {__index = Terminal})
package.loaded[...] = ThrowFn

--Constructor.
function ThrowFn.new(ln, col, args)
  local self

  --(1) create
  self = setmetatable(Terminal.new(TerminalType.THROW, {line = ln, col = col}), ThrowFn)
  self.args = args

  --(2) return
  return self
end

--@override
function ThrowFn:__tostring()
  local repr

  --(1) build
  repr = "(throw "

  for i, arg in ipairs(self.args) do
    repr = repr .. (i == 1 and "" or " ") .. tostring(arg)
  end

  repr = repr .. ")"

  --(2) return
  return repr
end
