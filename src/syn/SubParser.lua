--A subparser.
local SubParser = {}
SubParser.__index = SubParser
package.loaded[...] = SubParser

--Constructor.
--
--@param Parser:Parser  Parent parser.
function SubParser.new(parser)
  --(1) arguments
  if not parser then error("parser expected.") end

  --(2) create
  return setmetatable({
    _ = {
      parser = parser,
      lexer = parser._.lexer
    }
  }, SubParser)
end
