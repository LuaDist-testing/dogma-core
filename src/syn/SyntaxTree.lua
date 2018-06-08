--imports
local NodeType = require("dogma.syn.NodeType")
local NonTerminal = require("dogma.syn._.NonTerminal")
local NonTerminalType = require("dogma.syn.NonTerminalType")

--A syntax tree, for example, an expression.
local SyntaxTree = {}
SyntaxTree.__index = SyntaxTree
setmetatable(SyntaxTree, {__index = NonTerminal})
package.loaded[...] = SyntaxTree

--Constructor.
function SyntaxTree.new()
  local self

  --(1) create
  self = setmetatable(NonTerminal.new(NonTerminalType.TREE), SyntaxTree)
  self.root = nil
  self._ = {
    current = nil
  }

  --(2) return
  return self
end

--@override
function SyntaxTree:insert(node)
  --(1) arguments
  if not node then error("node expected.") end

  --(2) add
  if self.root == nil then --1st node to add
    self:_init(node)
  else
    self:_update(node)
  end
end

function SyntaxTree:_init(node)
  self.root = node

  if node.type == NodeType.NON_TERMINAL then
    self._.current = node
  end
end

function SyntaxTree:_update(node)
  if self.root.type == NodeType.TERMINAL then
    self:_updateTerminalRoot(node)
  else
    self:_updateFromCurrent(node)
  end
end

--Update the tree when this is well-formed with one terminal.
function SyntaxTree:_updateTerminalRoot(node)
  if node.type == NodeType.TERMINAL then
    error(string.format(
      "(%s,%s): terminal can't follow to other terminal.",
      node.token.line,
      node.token.col
    ))
  end

  --node is non-terminal, for example, an operator
  node:insert(self.root)
  self.root = node
  self._.current = node
end

--Update th tree from the current node.
--For example, when a+b for adding a call operator.
--We use the precedence and the associativity for determining.
function SyntaxTree:_updateFromCurrent(new)
  local cur = self._.current

  if self:isWellFormed() then
    if new.type == NodeType.TERMINAL then
      error(string.format(
        "on (%s,%s), invalid terminal node for well-formed expression.",
        new.token.line,
        new.token.col
      ))
    else
      if cur.prec > new.prec then
        self:_updateUpNodeFromCurrent(new)
      elseif cur.prec < new.prec then
        self:_updateDownNodeFromCurrent(new)
      else
        if cur.assoc == "l" then
          self:_updateUpNodeFromCurrent(new)
        else
          self:_updateDownNodeFromCurrent(new)
        end
      end
    end
  else  --non well-formed
    cur:insert(new)

    if new.type == NodeType.NON_TERMINAL then
      self._.current = new
    end
  end
end

function SyntaxTree:_updateUpNodeFromCurrent(node)
  if self.root == self._.current then
    node:insert(self.root)
    self.root = node
    self._.current = node
  else
    self._.current = self._.current.parent
    self:_updateFromCurrent(node)
  end
end

function SyntaxTree:_updateDownNodeFromCurrent(node)
  node:insert(self._.current:remove())
  self._.current:insert(node)
  self._.current = node
end

--@override
function SyntaxTree:__tostring()
  return self.root:__tostring()
end

--@override
function SyntaxTree:isWellFormed()
  if not self.root then
    return false
  elseif self.root.type == NodeType.TERMINAL then
    return true
  else
    return self._.current:isWellFormed()
  end
end
