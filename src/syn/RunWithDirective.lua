--imports
local Directive = require("dogma.syn._.Directive")
local DirectiveType = require("dogma.syn.DirectiveType")

--A runWith directive.
local RunWithDirective = {}
RunWithDirective.__index = RunWithDirective
setmetatable(RunWithDirective, {__index = Directive})
package.loaded[...] = RunWithDirective

--Constructor.
function RunWithDirective.new(ln, col, cmd)
  local self

  --(1) create
  self = setmetatable(Directive.new(DirectiveType.RUNWITH, ln, col), RunWithDirective)
  self.cmd = cmd

  --(2) return
  return self
end
