--A token.
local Token = {}
Token.__index = Token
package.loaded[...] = Token

--Constructor.
--
--@param t:TokenType  Token type.
--@param ln:number    Line number.
--@param col:number   Column number.
--@param val:any      Value.
function Token.new(t, ln, col, val)
  return setmetatable({
    type = t,
    line = ln,
    col = col,
    value = val
  }, Token)
end
