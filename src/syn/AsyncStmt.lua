--imports
local Stmt = require("dogma.syn._.Stmt")
local StmtType = require("dogma.syn.StmtType")

--An async statement.
local AsyncStmt = {}
AsyncStmt.__index = AsyncStmt
setmetatable(AsyncStmt, {__index = Stmt})
package.loaded[...] = AsyncStmt

--Constructor.
--
--@param ln:number
--@param col:number
--@param opts:object
--@param body:Sent[]
--@param catch:CatchCls
function AsyncStmt.new(ln, col, opts, body, catch)
  local self

  --(1) create
  self = setmetatable(Stmt.new(StmtType.ASYNC, ln, col), AsyncStmt)
  self.opts = opts
  self.body = body
  self.catch = catch

  --(2) return
  return self
end
