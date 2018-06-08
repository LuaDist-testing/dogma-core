--imports
local Id = require("dogma.lex._.Id")
local TokenType = require("dogma.lex.TokenType")

--An identifier.
local Name = {}
Name.__index = Id
setmetatable(Name, {__index = Id})
package.loaded[...] = Name

--Constructor.
--
--@param ln:number  Line number.
--@param col:number Column number
--@param id:string  Identifier.
function Name.new(ln, col, id)
  return setmetatable(Id.new(TokenType.NAME, ln, col, id), Id)
end

--@override
function Id:__tostring()
  return string.format("<name>%s</name>", self.value)
end
