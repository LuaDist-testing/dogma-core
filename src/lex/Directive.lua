--imports
local Token = require("dogma.lex._.Token")
local TokenType = require("dogma.lex.TokenType")

--A comilation directive.
local Directive = {}
Directive.__index = Directive
setmetatable(Directive, {__index = Token})
package.loaded[...] = Directive

--Constructor.
--
--@param ln:number
--@param col:number
--@param val:string
function Directive.new(ln, col, val)
  return setmetatable(Token.new(TokenType.DIRECTIVE, ln, col, val), Directive)
end

--@override
function Directive:__tostring()
  return string.format("<directive>%s</directive>", self.value)
end
