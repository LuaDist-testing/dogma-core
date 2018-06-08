--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A break statement.
local BreakStmt = {}
BreakStmt.__index = BreakStmt
setmetatable(BreakStmt, {__index = Stmt})
package.loaded[...] = BreakStmt

--Constructor.
--
--@param ln:number  Line number.
--@param col:number Column number.
function BreakStmt.new(ln, col)
  return setmetatable(Stmt.new(StmtType.BREAK, ln, col), BreakStmt)
end
