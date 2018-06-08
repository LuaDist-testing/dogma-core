--imports
local Sent = require("dogma.syn._.Sent")
local SentType = require("dogma.syn.SentType")

--A statement.
local Stmt = {}
Stmt.__index = Stmt
setmetatable(Stmt, {__index = Sent})
package.loaded[...] = Stmt

--Constructor.
--
--@param sub:StmtType   Statement type.
--@param ln:number      Line number.
--@param col:number     Column number.
function Stmt.new(sub, ln, col)
  local self

  --(1) create
  self = setmetatable(Sent.new(SentType.STMT, ln, col), Stmt)
  self.subtype = sub

  --(2) return
  return self
end
