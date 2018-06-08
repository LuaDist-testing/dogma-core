--imports
local Token = require("dogma.lex._.Token")
local TokenType = require("dogma.lex.TokenType")

--An end of line.
local Eol = {}
Eol.__index = Eol
setmetatable(Eol, {__index = Token})
package.loaded[...] = Eol

--Constructor.
--
--@param ln:number  Line number.
--@param col:number Column number.
function Eol.new(ln, col)
  return setmetatable(Token.new(TokenType.EOL, ln, col, "\n"), Eol)
end

function Eol:__tostring()
  return "<eol/>"
end
