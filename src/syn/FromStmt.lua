--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A from statement.
local FromStmt = {}
FromStmt.__index = FromStmt
setmetatable(FromStmt, {__index = Stmt})
package.loaded[...] = FromStmt

--Constructor.
function FromStmt.new(ln, col, mod)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.FROM, ln, col), FromStmt)
  self.module = mod
  self.members = {}

  --(2) return
  return self
end

--Insert an imported member.
--
--@param type:bool    Is a type?
--@param name:string  Member name to import.
--@param as?:string   Name to use in the code.
function FromStmt:insert(type, name, as)
  table.insert(self.members, {type = type, name = name, as = as or name})
end
