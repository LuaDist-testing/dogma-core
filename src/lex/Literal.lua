--imports
local Token = require("dogma.lex._.Token")
local TokenType = require("dogma.lex.TokenType")

--A literal.
local Literal = {}
Literal.__index = Literal
setmetatable(Literal, {__index = Token})
package.loaded[...] = Literal

--Constructor.
--
--@param ln:number    Line number.
--@param col:number   Column number.
--@param t:string     Literal type: number, string...
--@param val:any      Literal value.
function Literal.new(ln, col, t, val)
  local self

  --(1) create
  self = setmetatable(Token.new(TokenType.LITERAL, ln, col, val), Literal)
  self.subtype = t

  --(2) return
  return self
end

--@override
function Literal:__tostring()
  return string.format("<literal type='%s'>%s</literal>", self.type, self.value)
end
