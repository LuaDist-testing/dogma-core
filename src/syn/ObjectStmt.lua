--imports
local Stmt = require("dogma.syn._.Stmt")

--A statement for defining an object.
local ObjectStmt = {}
ObjectStmt.__index = ObjectStmt
setmetatable(ObjectStmt, {__index = Stmt})
package.loaded[...] = ObjectStmt

--Constructor.
--
--@param sub:StmtType   Statement type.
--@param ln:number      Line number.
--@param col:number     Column number.
--@param name:string    Object name.
--@param visib:string   export or pub if indicated?
function ObjectStmt.new(sub, ln, col, name, visib)
  local self

  --(1) create
  self = setmetatable(Stmt.new(sub, ln, col), ObjectStmt)
  self.name = name
  self.visib = visib

  --(2) return
  return self
end
