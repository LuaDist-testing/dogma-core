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
function VarStmt.new(ln, col, visib)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.VAR, ln, col), VarStmt)
  self.vars = {}
  self.visib = visib

  --(2) return
  return self
end

--Add a variable declaration.
--
--@param name:string  Variable name.
--@param val?:Exp     Default value.
function VarStmt:insert(name, val)
  table.insert(self.vars, {name = name, value = val})
end
