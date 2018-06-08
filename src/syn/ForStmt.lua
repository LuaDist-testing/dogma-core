--Imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A for statement.
local ForStmt = {}
ForStmt.__index = ForStmt
setmetatable(ForStmt, {__index = Stmt})
package.loaded[...] = ForStmt

--Constructor.
--
--@param ln:number
--@param col:number
--@param def:VarStmt
--@param cond:Exp
--@param iter:Exp
--@param body:Sent[]
--@param catch?:CatchCl
--@param fin?:FinallyCl
function ForStmt.new(ln, col, def, cond, iter, body, catch, fin)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.FOR, ln, col), ForStmt)
  self.def = def
  self.cond = cond
  self.iter = iter
  self.body = body
  self.catch = catch
  self.finally = fin

  --(2) return
  return self
end
