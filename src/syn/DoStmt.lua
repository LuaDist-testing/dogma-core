--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A while statement.
local DoStmt = {}
DoStmt.__index = DoStmt
setmetatable(DoStmt, {__index = Stmt})
package.loaded[...] = DoStmt

--Constructor.
--
--@param ln:number
--@param col:number
--@param body:Sent[]
--@param cond?:Exp
--@param catch?:CatchCl
--@param fin?:FinallyCl
function DoStmt.new(ln, col, body, cond, catch, fin)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.DO, ln, col), DoStmt)
  self.body = body
  self.cond = cond
  self.catch = catch
  self.finally = fin

  --(2) return
  return self
end
