--A character.
local Char = {}
Char.__index = Char
package.loaded[...] = Char

--Constructor.
--
--@param ln:number  Line number.
--@param col:number Column number.
--@param ch:char    Character.
function Char.new(ln, col, ch)
  return setmetatable({
    line = ln,
    col = col,
    char = ch
  }, Char)
end
