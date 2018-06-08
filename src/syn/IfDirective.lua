--imports
local Directive = require("dogma.syn._.Directive")
local DirectiveType = require("dogma.syn.DirectiveType")

--An if directive.
local IfDirective = {}
IfDirective.__index = IfDirective
setmetatable(IfDirective, {__index = Directive})
package.loaded[...] = IfDirective

--Constructor.
function IfDirective.new(ln, col, cond, body, el)
  local self

  --(1) create
  self = setmetatable(Directive.new(DirectiveType.IF, ln, col), IfDirective)
  self.cond = cond
  self.body = body
  self.el = el

  --(2) return
  return self
end
