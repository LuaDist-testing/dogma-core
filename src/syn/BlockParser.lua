--imports
local TokenType = require("dogma.lex.TokenType")
local SubParser = require("dogma.syn._.SubParser")

--An expression parser.
local BlockParser = {}
BlockParser.__index = BlockParser
setmetatable(BlockParser, {__index = SubParser})
package.loaded[...] = BlockParser

--Constructor.
--
--@param parser:Parser  Parser to use.
--@param col:number     Column number.
function BlockParser.new(parser, col)
  local self

  self = setmetatable(SubParser.new(parser), BlockParser)
  if col == nil then
    self._.col = 0
    self._.type = "end"
  else
    self._.col = col
    self._.type = "\n"
  end

  return self
end

--Parse the next block.
--
--@return Sent[]
function BlockParser:next()
  local lex, parser, btype = self._.lexer, self._.parser, self._.type
  local tok
  local col, block = self._.col, {}

  --(1) see if empty function
  if btype == "end" then
    tok = lex:advance()

    if tok.type == TokenType.KEYWORD and tok.value == "end" then
      lex:next()
      return block
    end
  end

  --(1) read
  while true do
    local sent

    tok = lex:advance()

    --remove white lines
    while tok and tok.type == TokenType.EOL do
      lex:next()
      tok = lex:advance()
    end

    if btype == "end" and tok and tok.type == TokenType.KEYWORD and tok.value == "end" then
      break
    end

    if tok == nil or tok.col <= col then
      break
    end

    --parse next sentence
    sent = parser:next()

    if sent then
      table.insert(block, sent)
    else
      break
    end
  end

  --(3) read } if needed
  if btype == "end" then
    lex:next(TokenType.KEYWORD, "end")
  end

  --(3) return
  return block
end
