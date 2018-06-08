--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--with statement.
local WithStmt = {}
WithStmt.__index = WithStmt
setmetatable(WithStmt, {__index = Stmt})
package.loaded[...] = WithStmt

--Constructor.
function WithStmt.new(ln, col, val, ifs, els)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.WITH, ln, col), WithStmt)
  self.value = val
  self.ifs = ifs
  self.els = els

  --(2) return
  return self
end
