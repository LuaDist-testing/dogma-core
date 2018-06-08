--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A next statement.
local NextStmt = {}
NextStmt.__index = NextStmt
setmetatable(NextStmt, {__index = Stmt})
package.loaded[...] = NextStmt

--Constructor.
--
--@param ln:number  Line number.
--@param col:number Column number.
function NextStmt.new(ln, col)
  return setmetatable(Stmt.new(StmtType.NEXT, ln, col), NextStmt)
end
