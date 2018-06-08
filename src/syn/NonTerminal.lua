--imports
local Node = require("dogma.syn._.Node")
local NodeType = require("dogma.syn.NodeType")

--A non-terminal node, that is, a branch.
local NonTerminal = {}
NonTerminal.__index = NonTerminal
setmetatable(NonTerminal, {__index = Node})
package.loaded[...] = NonTerminal

--Constructor.
--
--@param sub:NonTerminalType
--@param tok:Token
function NonTerminal.new(sub, tok)
  local self

  --(1) create
  self = setmetatable(Node.new(NodeType.NON_TERMINAL, tok), NonTerminal)
  self.subtype = sub

  --(2) return
  return self
end

--Add a node to the non-terminal.
--
--@param child:Node Node to add.
function NonTerminal.insert()
  error("abstract node.")
end

--Remove and return last child for transfering to other node.
--
--@return Node
function NonTerminal.remove()
  error("abstract node.")
end

--Is it well-formed?
--
--@return bool
-- function NonTerminal:isWellFormed()
--   error("abstract method.")
-- end
