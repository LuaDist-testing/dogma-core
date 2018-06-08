--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--A map terminal node.
local LiteralMap = {}
LiteralMap.__index = LiteralMap
setmetatable(LiteralMap, {__index = Terminal})
package.loaded[...] = LiteralMap

--Constructor.
function LiteralMap.new(ln, col, map)
  return setmetatable(Terminal.new(TerminalType.MAP, {line = ln, col = col, value = map}), LiteralMap)
end

--@override
function LiteralMap:__tostring()
  local desc

  desc = "{"
  for i, e in ipairs(self.data) do
    desc = desc .. (i == 1 and "" or ", ") .. e.name .. " = " .. tostring(e.value)
  end
  desc = desc .. "}"

  return desc
end
