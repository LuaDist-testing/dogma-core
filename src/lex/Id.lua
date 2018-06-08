--imports
local Token = require("dogma.lex._.Token")

--An identifier.
local Id = {}
Id.__index = Id
setmetatable(Id, {__index = Token})
package.loaded[...] = Id

--Constructor.
--
--@param t:string   Token type.
--@param ln:number  Line number.
--@param col:number Column number
--@param id:string  Identifier.
function Id.new(t, ln, col, id)
  return setmetatable(Token.new(t, ln, col, id), Id)
end
