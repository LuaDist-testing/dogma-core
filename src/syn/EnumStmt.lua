--imports
local ObjectStmt = require("dogma.syn._.ObjectStmt")
local StmtType = require("dogma.syn.StmtType")

--An enum statement.
local EnumStmt = {}
EnumStmt.__index = EnumStmt
setmetatable(EnumStmt, {__index = ObjectStmt})
package.loaded[...] = EnumStmt

--Constructor.
function EnumStmt.new(ln, col, annots, visib, name)
  local self

  --(1) create
  self = setmetatable(ObjectStmt.new(StmtType.ENUM, ln, col, name, visib), EnumStmt)
  self.items = {}
  self.annots = annots or {}
  self._.lastValue = nil

  --(2) return
  return self
end

--Insert an item.
--
--@param item:string    Item name.
--@param value:any      Item value.
function EnumStmt:insert(item, value)
  --(1) set value if needed
  if value == nil then
    if self._.lastValue == nil then
      self._.lastValue = 1
    else
      self._.lastValue = self._.lastValue + 1
    end

    value = self._.lastValue
  end

  --(2) insert
  table.insert(self.items, {name = item, value = value})
end
