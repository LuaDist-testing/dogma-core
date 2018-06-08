--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A pub statement.
local PubStmt = {}
PubStmt.__index = PubStmt
setmetatable(PubStmt, {__index = Stmt})
package.loaded[...] = PubStmt

--Constructor.
function PubStmt.new(ln, col, items)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.PUB, ln, col), PubStmt)
  self.items = items

  --(2) return
  return self
end
