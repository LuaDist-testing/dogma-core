--imports
local Sent = require("dogma.syn._.Sent")
local SentType = require("dogma.syn.SentType")
local SyntaxTree = require("dogma.syn._.SyntaxTree")

--An expression.
local Exp = {}
Exp.__index = Exp
setmetatable(Exp, {__index = Sent})
package.loaded[...] = Exp

--Constructor.
--
--@param ln:number  Line number.
--@param col:number Column number.
function Exp.new(ln, col)
  local self

  --(1) create
  self = setmetatable(Sent.new(SentType.EXP, ln, col), Exp)
  self.tree = SyntaxTree.new()

  --(2) return
  return self
end

--Add a new node to the expression.
--
--@param node:Node  Node to add.
function Exp:insert(node)
  self.tree:insert(node)
end

--@override
function Exp:__tostring()
  return self.tree:__tostring()
end
