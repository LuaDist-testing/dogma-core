--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--A return statement.
local ReturnStmt = {}
ReturnStmt.__index = ReturnStmt
setmetatable(ReturnStmt, {__index = Stmt})
package.loaded[...] = ReturnStmt

--Constructor.
--
--@param ln:number  Line number.
--@param col:number Column number.
--@param val?:Exp   Value to return.
function ReturnStmt.new(ln, col, val)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.RETURN, ln, col), ReturnStmt)
  if val then
    self.values = {val}
  else
    self.values = {}
  end

  --(2) return
  return self
end

--@override
function ReturnStmt:__len()
  return #self.values
end

--Add a value.
--
--@param val:Exp  Value to add.
function ReturnStmt:insert(val)
  table.insert(self.values, val)
end

function ReturnStmt:__tostring()
  if #self.values == 0 then
    return "return"
  else
    return "return " .. tostring(self.values[1])
  end
end
