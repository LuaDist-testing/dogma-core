--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--A subexpression: (Exp).
local SubExp = {}
SubExp.__index = SubExp
setmetatable(SubExp, {__index = Terminal})
package.loaded[...] = SubExp

--Constructor.
function SubExp.new(ln, col, exp)
  return setmetatable(Terminal.new(TerminalType.SUBEXP, {line = ln, col = col, value = exp}), SubExp)
end

--@override
function SubExp:__tostring()
  return tostring(self.data)
end
