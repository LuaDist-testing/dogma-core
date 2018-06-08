--imports
local ObjectStmt = require("dogma.syn._.ObjectStmt")
local StmtType = require("dogma.syn.StmtType")

--A fn statement.
local FnStmt = {}
FnStmt.__index = FnStmt
setmetatable(FnStmt, {__index = ObjectStmt})
package.loaded[...] = FnStmt

--Constructor.
function FnStmt.new(ln, col, annots, visib, async, itype, name, params, rtype, rvar, body, catch, fin)
  local self

  --(1) create
  self = setmetatable(ObjectStmt.new(StmtType.FN, ln, col, name, visib), FnStmt)
  self.async = async
  self.itype = itype
  self.params = params
  self.rtype = rtype
  self.rvar = rvar
  self.body = body
  self.catch = catch
  self.finally = fin
  self.annots = annots or {}

  --(2) return
  return self
end
