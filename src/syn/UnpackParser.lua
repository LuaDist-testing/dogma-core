--imports
local TokenType = require("dogma.lex.TokenType")
local SubParser = require("dogma.syn._.SubParser")
local Unpack = require("dogma.syn._.Unpack")

--An unpack sentence parser.
local UnpackParser = {}
UnpackParser.__index = UnpackParser
setmetatable(UnpackParser, {__index = SubParser})
package.loaded[...] = UnpackParser

--Constructor.
--
--@param parser:Parser  Parent parser.
function UnpackParser.new(parser)
  return setmetatable(SubParser.new(parser), UnpackParser)
end

--Parse the next unpack sentence.
--
--@return Unpack
function UnpackParser:next()
  local lex, parser = self._.lexer, self._.parser
  local tok, ln, col, visib, def, typ, vars, assign, exp

  --(1) read visibility if needed
  tok = lex:advance()
  ln, col = tok.line, tok.col

  if tok.type == TokenType.KEYWORD and (tok.value == "export" or tok.value == "pub") then
    lex:next()
    visib = tok.value
  end

  --(2) get type definition
  tok = lex:advance()

  if tok.type == TokenType.KEYWORD and (tok.value == "var" or tok.value == "const") then
    lex:next()
    def = tok.value
  end

  --(3) get type
  tok = lex:next()

  if tok.type == TokenType.SYMBOL and tok.value == "[" then
    typ = "[]"
  else
    typ = "{}"
  end

  --(4) get vars
  vars = {}

  while true do
    local rest, name, val

    --rest?
    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "..." then
      rest = true
      lex:next()
    else
      rest = false
    end

    --name
    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and (tok.value == "$" or tok.value == "." or tok.value == ":") then
      name = tok.value
      lex:next()
    else
      name = ""
    end

    name = name .. lex:next(TokenType.NAME).value

    --default value
    tok = lex:advance()

    if tok.type == TokenType.SYMBOL and tok.value == "=" then
      lex:next()
      val = parser:nextExp()
    else
      val = nil
    end

    --insert
    table.insert(vars, {rest = rest, name = name, value = val})

    --comma or end
    tok = lex:advance()

    if typ == "[]" then
      if tok.type == TokenType.SYMBOL and tok.value == "]" then
        lex:next()
        break
      end
    elseif typ == "{}" then
      if tok.type == TokenType.SYMBOL and tok.value == "}" then
        lex:next()
        break
      end
    end

    lex:next(TokenType.SYMBOL, ",")
  end

  --(5) expression
  tok = lex:advance()
  if not (tok.type == TokenType.SYMBOL and (tok.value == "=" or tok.value == ":=")) then
    error(string.format("on (%s,%s), = or := expected.", tok.line, tok.col))
  end

  lex:next()
  assign = tok.value
  exp = parser:nextExp()
  lex:next(TokenType.EOL)

  --(6) return
  return Unpack.new(ln, col, visib, def, typ, vars, assign, exp)
end
