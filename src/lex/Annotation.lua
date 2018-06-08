--imports
local Token = require("dogma.lex._.Token")
local TokenType = require("dogma.lex.TokenType")

--An annotation.
local Annotation = {}
Annotation.__index = Annotation
setmetatable(Annotation, {__index = Token})
package.loaded[...] = Annotation

--Constructor.
--
--@param ln:number
--@param col:number
--@param val:string
function Annotation.new(ln, col, val)
  return setmetatable(Token.new(TokenType.ANNOTATION, ln, col, val), Annotation)
end

--@override
function Annotation:__tostring()
  return string.format("<annotation>%s</annotation>", self.value)
end
