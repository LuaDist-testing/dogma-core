--imports
local Sent = require("dogma.syn._.Sent")
local SentType = require("dogma.syn.SentType")

--A directive.
--@abstract
local Directive = {}
Directive.__index = Directive
setmetatable(Directive, {__index = Sent})
package.loaded[...] = Directive

--Constructor.
--
--@param subtype:DirectiveType  Directive type.
--@param ln:number              Line number.
--@param col:number             Column number.
function Directive.new(subtype, ln, col)
  local self

  --(1) create
  self = setmetatable(Sent.new(SentType.DIRECTIVE, ln, col), Directive)
  self.subtype = subtype

  --(2) return
  return self
end
