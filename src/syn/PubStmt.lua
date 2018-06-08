--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")
local UseStmt = require("dogma.syn._.UseStmt")

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

  for _, item in ipairs(items) do
    if item.type == "use" then
      item.value = {
        path = item.value,
        name = UseStmt.getNameFor(item.value)
      }
    end
  end

  --(2) return
  return self
end
