--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--use statement.
local UseStmt = {}
UseStmt.__index = UseStmt
setmetatable(UseStmt, {__index = Stmt})
package.loaded[...] = UseStmt

--Constructor.
function UseStmt.new(ln, col)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.USE, ln, col), UseStmt)
  self.modules = {}

  --(2) return
  return self
end

--Add a module.
--
--@param type:bool    Is a type?
--@param mod:string   Module to use.
--@param name?:string Variable module name.
function UseStmt:insert(type, mod, name)
  local NAME_PATTERN1 = "^[%a_][%w_]*$"
  local NAME_PATTERN2 = "^[%a_][%w_%-]*-([%a_][%w_]*)$"
  local Q_PATTERN1 = "^.*/([%a_][%w_]*)$"
  local Q_PATTERN2 = "^.*%.([%a_][%w_]*)$"

  --(1) set name if needed
  if not name then
    if mod:find(NAME_PATTERN1) then
      name = mod
    elseif mod:find(NAME_PATTERN2) then
      name = mod:match(NAME_PATTERN2)
    elseif mod:find(Q_PATTERN1) then
      name = mod:match(Q_PATTERN1)
    elseif mod:find(Q_PATTERN2) then
      name = mod:match(Q_PATTERN2)
    else
      error(string.format("invalid module path format: '%s'.", mod))
    end
  end

  --(2) add module
  table.insert(self.modules, {type = type, name = name, path = mod})
end
