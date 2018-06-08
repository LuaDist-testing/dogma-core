--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A var statement.
local ConstStmt = {}
ConstStmt.__index = ConstStmt
setmetatable(ConstStmt, {__index = Stmt})
package.loaded[...] = ConstStmt

--Constructor.
--
--@param ln:number    Line number.
--@param col:number   Column number.
--@param visib:string Visibility: export or pub.
--@param decls:list   Declarations.
function ConstStmt.new(ln, col, visib, decls)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.CONST, ln, col), ConstStmt)
  self.decls = decls
  self.visib = visib

  --(2) return
  return self
end
