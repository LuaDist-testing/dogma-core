--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--An export statement.
local ExportStmt = {}
ExportStmt.__index = ExportStmt
setmetatable(ExportStmt, {__index = Stmt})
package.loaded[...] = ExportStmt

--Constructor.
function ExportStmt.new(ln, col, exp)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.EXPORT, ln, col), ExportStmt)
  self.exp = exp

  --(2) return
  return self
end
