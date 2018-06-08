--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A yield statement.
local YieldStmt = {}
YieldStmt.__index = YieldStmt
setmetatable(YieldStmt, {__index = Stmt})
package.loaded[...] = YieldStmt

--Constructor.
--
--@param ln:number  Line number.
--@param col:number Column number.
--@param val?:Exp   Value to return.
function YieldStmt.new(ln, col, val)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.YIELD, ln, col), YieldStmt)
  self.value = val

  --(2) return
  return self
end

--@override
function YieldStmt:__tostring()
  return "yield " .. tostring(self.value)
end
