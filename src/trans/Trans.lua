--A transformer.
local Trans = {}
Trans.__index = Trans
package.loaded[...] = Trans

--Constructor.
function Trans.new()
  return setmetatable({
    _ = {

    }
  }, Trans)
end

--Confirgue the transformer.
--
--@param parser:Parser  Parser to use.
function Trans:transform(parser)
  self._.parser = parser
end

--Transform the next sentence or file from the parser configured previously.
--
--@abstract
--@return string
function Trans:next()
  error("abstract method.")
end
