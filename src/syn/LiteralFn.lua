--imports
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")

--An array terminal node.
local LiteralFn = {}
LiteralFn.__index = LiteralFn
setmetatable(LiteralFn, {__index = Terminal})
package.loaded[...] = LiteralFn

--Constructor.
function LiteralFn.new(ln, col, params, rtype, rvar, body)
  local self

  self = setmetatable(Terminal.new(TerminalType.FN, {
    line = ln,
    col = col,
    value = {
      params = params,
      type = rtype,
      rvar = rvar,
      body = body
    }
  }), LiteralFn)

  return self
end

--@override
function LiteralFn:__tostring()
  local desc

  desc = "fn("
  for i, p in ipairs(self.data.params) do
    desc = desc .. (i == 1 and "" or ", ") .. p.name
  end
  desc = desc .. ")"

  desc = desc .. "{"
  for i, s in ipairs(self.data.body) do
    desc = desc .. (i == 1 and "" or "; ") .. tostring(s)
  end
  desc = desc .. "}"

  return desc
end
