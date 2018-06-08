--imports
local TokenType = require("dogma.lex.TokenType")
local Node = require("dogma.syn._.Node")
local NodeType = require("dogma.syn.NodeType")

--A terminal node.
local Terminal = {}
Terminal.__index = Terminal
setmetatable(Terminal, {__index = Node})
package.loaded[...] = Terminal

--Constructor.
--
--@param sub:TerminalTtype
--@param tok:Token
function Terminal.new(sub, tok)
  local self

  --(1) create
  self = setmetatable(Node.new(NodeType.TERMINAL, tok), Terminal)
  self.subtype = sub
  self.data = tok.value

  --(2) return
  return self
end

--@override
function Terminal:__tostring()
  return string.format("%s", self.data)
end

--Is it an identifier?
--
--@return bool
function Terminal:isId()
  return self.token.type == TokenType.NAME
end
