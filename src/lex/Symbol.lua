--imports
local Token = require("dogma.lex._.Token")
local TokenType = require("dogma.lex.TokenType")

--A symbol.
local Symbol = {}
Symbol.__index = Symbol
setmetatable(Symbol, {__index = Token})
package.loaded[...] = Symbol

--Constructor.
--
--@param ln:number    Line number.
--@param col:number   Column number.
--@param sym:string   Symbol.
function Symbol.new(ln, col, sym)
  return setmetatable(Token.new(TokenType.SYMBOL, ln, col, sym), Symbol)
end

--@override
function Symbol:__tostring()
  return string.format("<symbol>%s</symbol>", self.value)
end
