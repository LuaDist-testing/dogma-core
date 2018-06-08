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
function ConstStmt.new(ln, col, visib)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.CONST, ln, col), ConstStmt)
  self.vars = {}
  self.visib = visib

  --(2) return
  return self
end

--Add a variable declaration.
--
--@param name:string  Variable name.
--@param val?:Exp     Default value.
function ConstStmt:insert(name, val)
  table.insert(self.vars, {name = name, value = val})
end
