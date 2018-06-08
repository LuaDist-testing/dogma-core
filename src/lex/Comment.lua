--imports
local Token = require("dogma.lex._.Token")
local TokenType = require("dogma.lex.TokenType")

--A comment.
local Comment = {}
Comment.__index = Comment
setmetatable(Comment, {__index = Token})
package.loaded[...] = Comment

--Constructor.
--
--@param ln:number    Line number.
--@param col:number   Column number.
--@param text:string  Comment text.
function Comment.new(ln, col, text)
  return setmetatable(Token.new(TokenType.COMMENT, ln, col, text), Comment)
end

--@override
function Comment:__tostring()
  return string.format("<comment>%s</comment>", self.value)
end
