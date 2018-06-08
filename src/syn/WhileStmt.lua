--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A while statement.
local WhileStmt = {}
WhileStmt.__index = WhileStmt
setmetatable(WhileStmt, {__index = Stmt})
package.loaded[...] = WhileStmt

--Constructor.
--
--@param ln:number
--@param col:number
--@param cond:Exp
--@param iter?:Exp
--@param body:Sent[]
--@param catch?:CatchCl
--@param fin?:FinallyCl
function WhileStmt.new(ln, col, cond, iter, body, catch, fin)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.WHILE, ln, col), WhileStmt)
  self.cond = cond
  self.iter = iter
  self.body = body
  self.catch = catch
  self.finally = fin

  --(2) return
  return self
end
