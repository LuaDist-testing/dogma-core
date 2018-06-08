--Imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A for each statement.
local ForEachStmt = {}
ForEachStmt.__index = ForEachStmt
setmetatable(ForEachStmt, {__index = Stmt})
package.loaded[...] = ForEachStmt

--Constructor.
--
--@param ln:number
--@param col:number
--@param key?:string
--@param value:string
--@param iter:Exp
--@param body:Sent[]
--@param catch?:CatchCl
--@param fin?:FinallyCl
function ForEachStmt.new(ln, col, key, val, iter, body, catch, fin)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.FOR_EACH, ln, col), ForEachStmt)
  self.key = key
  self.value = val
  self.iter = iter
  self.body = body
  self.catch = catch
  self.finally = fin

  --(2) return
  return self
end
