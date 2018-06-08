--importsa
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--An if statement.
local IfStmt = {}
IfStmt.__index = IfStmt
setmetatable(IfStmt, {__index = Stmt})
package.loaded[...] = IfStmt

--Constructor.
function IfStmt.new(ln, col, cond, body, elif, el)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.IF, ln, col), IfStmt)
  self.cond = cond
  self.body = body
  self.elif = elif
  self.el = el

  --(2) return
  return self
end
