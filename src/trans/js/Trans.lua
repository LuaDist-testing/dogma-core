--imports
local Trans = require("dogma.trans.Trans")
local DirectiveTrans = require("dogma.trans.js._.DirectiveTrans")
local ExpTrans = require("dogma.trans.js._.ExpTrans")
local StmtTrans = require("dogma.trans.js._.StmtTrans")
local UnpackTrans = require("dogma.trans.js._.UnpackTrans")
local SentType = require("dogma.syn.SentType")

--A JavaScript transformer.
local JsTrans = {}
JsTrans.__index = JsTrans
setmetatable(JsTrans, {__index = Trans})
package.loaded[...] = JsTrans

--Constructor.
function JsTrans.new(opts)
  local self

  --(1) create
  self = setmetatable(Trans.new(opts), JsTrans)
  self._.directiveTrans = DirectiveTrans.new(self)
  self._.expTrans = ExpTrans.new(self)
  self._.stmtTrans = StmtTrans.new(self)
  self._.unpackTrans = UnpackTrans.new(self)

  --(2) return
  return self
end

--@override
function JsTrans:next()
  local parser = self._.parser
  local out

  --(1) transform
  out = ""

  while true do
    local sent

    sent = parser:next()

    if sent == nil then
      break
    end

    out = out .. self:_trans(sent, ";") .. "\n"
  end

  --(2) return
  return out
end

function JsTrans:_trans(sent, eoe)
  if sent.type == SentType.DIRECTIVE then
    return self._.directiveTrans:transform(sent)
  elseif sent.type == SentType.EXP then
    return self._.expTrans:transform(sent) .. (eoe or "")
  elseif sent.type == SentType.STMT then
    return self._.stmtTrans:transform(sent)
  elseif sent.type == SentType.UNPACK then
    return self._.unpackTrans:transform(sent)
  end
end
