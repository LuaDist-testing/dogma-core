--imports
local Id = require("dogma.lex._.Id")
local TokenType = require("dogma.lex.TokenType")

--A keyword.
local Keyword = {}
Keyword.__index = Keyword
setmetatable(Keyword, {__index = Id})
package.loaded[...] = Keyword

--Constructor.
--
--@param ln:number  Line number.
--@param col:number Column number.
--@param id:string  Identifier.
function Keyword.new(ln, col, id)
  return setmetatable(Id.new(TokenType.KEYWORD, ln, col, id), Keyword)
end

--Check whether an identifier is a keyword.
--
--@param id:string  Identifier to check.
--@return bool
function Keyword.isKeyword(id)
  local KEYWORDS = {
    ["and"] = true,
    ["as"] = true,
    ["async"] = true,
    ["await"] = true,
    ["break"] = true,
    ["catch"] = true,
    ["const"] = true,
    ["do"] = true,
    ["dogma"] = true,
    ["each"] = true,
    ["else"] = true,
    ["end"] = true,
    ["enum"] = true,
    ["export"] = true,
    ["extern"] = true,
    ["false"] = true,
    ["finally"] = true,
    ["fn"] = true,
    ["for"] = true,
    ["from"] = true,
    ["if"] = true,
    ["impl"] = true,
    ["in"] = true,
    ["is"] = true,
    ["like"] = true,
    ["native"] = true,
    ["next"] = true,
    ["nil"] = true,
    ["nop"] = true,
    ["not"] = true,
    ["op"] = true,
    ["or"] = true,
    ["peval"] = true,
    ["pub"] = true,
    ["pvt"] = true, --private
    ["return"] = true,
    ["self"] = true,
    ["Self"] = true,
    ["super"] = true,
    ["then"] = true,
    ["throw"] = true,
    ["true"] = true,
    ["type"] = true,
    ["use"] = true,
    ["var"] = true,
    ["while"] = true,
    ["yield"] = true
  }

  return KEYWORDS[id] or false
end

--@override
function Keyword:__tostring()
  return string.format("<keyword>%s</keyword>", self.value)
end
