--imports
local ObjectStmt = require("dogma.syn._.ObjectStmt")
local StmtType = require("dogma.syn.StmtType")

--A type statement.
local TypeStmt = {}
TypeStmt.__index = TypeStmt
setmetatable(TypeStmt, {__index = ObjectStmt})
package.loaded[...] = TypeStmt

--Constructor.
function TypeStmt.new(ln, col, annots, visib, name, params, btype, bargs, body, catch, fin)
  local self

  --(1) create
  self = setmetatable(ObjectStmt.new(StmtType.TYPE, ln, col, name, visib), TypeStmt)
  self.params = params
  self.base = btype
  self.bargs = bargs
  self.body = body
  self.catch = catch
  self.finally = fin
  self.annots = annots or {}

  --(2) return
  return self
end
