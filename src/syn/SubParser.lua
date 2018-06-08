--imports
local TokenType = require("dogma.lex.TokenType")
local DataAccess = require("dogma.syn._.DataAccess")

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

--Read the next data access.
--
--@return DataAccess
function SubParser:_nextDataAccess(opts)
  local lex, parser = self._.lexer, self._.parser
  local tok, mod, name, val

  --(1) read modifier
  tok = lex:advance()

  if tok.type == TokenType.SYMBOL and (tok.value == "..." or tok.value == "." or tok.value == ":") then
    if tok.value == "..." and not opts.rest then
      error(string.format("on (%s,%s), '...' not allowed with list unpack.", tok.line, tok.col))
    end

    lex:next()
    mod = tok.value
  end

  --(2) read name
  name = lex:next(TokenType.NAME).value

  while true do
    tok = lex:advance()

    if tok.type == TokenType.SYMBOL and (tok.value == "." or tok.value == ":") then
      lex:next()
      name = name .. tok.value .. lex:next(TokenType.NAME).value
    else
      break
    end
  end

  --(3) read value
  if opts.default then
    tok = lex:advance()

    if tok.type == TokenType.SYMBOL and tok.value == "=" then
      lex:next()
      val = parser:nextExp()
    end
  end

  --(4) return
  return DataAccess.new(mod, name, val)
end

--Read next end of lines.
function SubParser:_nextEols()
  local lex = self._.lexer

  while true do
    local tok = lex:advance()
    if tok.type == TokenType.EOL then
      lex:next()
    else
      break
    end
  end
end
