--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--A literal list node.
local LiteralList = {}
LiteralList.__index = LiteralList
setmetatable(LiteralList, {__index = Terminal})
package.loaded[...] = LiteralList

--Constructor.
function LiteralList.new(ln, col, arr)
  return setmetatable(Terminal.new(TerminalType.LIST, {line = ln, col = col, value = arr}), LiteralList)
end

--@override
function LiteralList:__tostring()
  local desc

  desc = "["
  for i, v in ipairs(self.data) do
    desc = desc .. (i == 1 and "" or ", ") .. tostring(v)
  end
  desc = desc .. "]"

  return desc
end
