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
--@param mod:string   Module to use.
--@param name?:string Variable module name.
function UseStmt:insert(mod, name)
  --(1) set name if needed
  if not name then
    name = UseStmt.getNameFor(mod)
  end

  --(2) add module
  table.insert(self.modules, {name = name, path = mod})
end

function UseStmt.getNameFor(path)
  local NAME_PATTERN1 = "^[%a_][%w_]*$"
  local NAME_PATTERN2 = "^[%a_][%w_%-]*-([%a_][%w_]*)$"
  local Q_PATTERN1 = "^.*/([%a_][%w_]*)$"
  local Q_PATTERN2 = "^.*%.([%a_][%w_]*)$"
  local name

  if path:find(NAME_PATTERN1) then
    name = path
  elseif path:find(NAME_PATTERN2) then
    name = path:match(NAME_PATTERN2)
  elseif path:find(Q_PATTERN1) then
    name = path:match(Q_PATTERN1)
  elseif path:find(Q_PATTERN2) then
    name = path:match(Q_PATTERN2)
  else
    error(string.format("invalid module path format: '%s'.", path))
  end

  return name
end
