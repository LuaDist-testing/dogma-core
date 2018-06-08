--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A var statement.
local VarStmt = {}
VarStmt.__index = VarStmt
setmetatable(VarStmt, {__index = Stmt})
package.loaded[...] = VarStmt

--Constructor.
--
--@param ln:number    Line number.
--@param col:number   Column number.
--@param visib:string Visibility: export or pub.
--@param decls:list   Declarations.
function VarStmt.new(ln, col, visib, decls)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.VAR, ln, col), VarStmt)
  self.decls = decls
  self.visib = visib

  --(2) return
  return self
end
