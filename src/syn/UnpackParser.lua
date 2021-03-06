--imports
local TokenType = require("dogma.lex.TokenType")
local SubParser = require("dogma.syn._.SubParser")
local Unpack = require("dogma.syn._.Unpack")
local DataAccess = require("dogma.syn._.DataAccess")

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
  local tok, ln, col, typ, vars, assign, exp

  --(1) read type
  tok = lex:next()
  ln, col = tok.line, tok.col

  if tok.type == TokenType.SYMBOL and tok.value == "[" then
    typ = "[]"
  else
    typ = "{}"
  end

  --(2) get vars
  vars = {}

  while true do
    local mod, name, val

    --visib
    tok = lex:advance()

    if tok.type == TokenType.SYMBOL and (tok.value == "." or tok.value == ":") then
      lex:next()
      mod = tok.value
    elseif tok.type == TokenType.SYMBOL and tok.value == "..." then
      if typ == "{}" then
        error(string.format("on (%s,%s), '...' only allowed with list unpack.", tok.line, tok.col))
      else
        lex:next()
        mod = tok.value
      end
    end

    --name, name=val, name{...}
    name = lex:nextId().value

    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "{" then
      if typ == "{}" then
        error(string.format("on (%s,%s), 'object{}' only allowed with list unpack.", tok.line, tok.col))
      else
        lex:next(TokenType.SYMBOL, "{")

        while true do
          local fmod

          tok = lex:advance()
          if tok.type == TokenType.SYMBOL and tok.value == ":" then
            lex:next()
            fmod = ":"
          else
            fmod = "."
          end

          table.insert(vars, DataAccess.new(nil, name .. fmod .. lex:nextId().value))

          tok = lex:advance()
          if not (tok.type == TokenType.SYMBOL and tok.value == ",") then
            break
          end

          lex:next(TokenType.SYMBOL, ",")
        end

        lex:next(TokenType.SYMBOL, "}")
      end
    else
      while true do
        tok = lex:advance()

        if tok.type == TokenType.SYMBOL and (tok.value == "." or tok.value == ":") then
          lex:next()
          name = name .. tok.value .. lex:nextId().value
        else
          break
        end
      end

      tok = lex:advance()

      if tok.type == TokenType.SYMBOL and tok.value == "=" then
        lex:next()
        val = parser:nextExp()
      end

      table.insert(vars, DataAccess.new(mod, name, val))
    end

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

  --(3) expression
  tok = lex:advance()

  if typ == "[]" then
    if not (tok.type == TokenType.SYMBOL and (tok.value == "=" or tok.value == ".=" or tok.value == ":=" or tok.value == "?=")) then
      error(string.format("on (%s,%s), '=', '.=', ':=' or '?=' expected.", tok.line, tok.col))
    end
  else
    if not (tok.type == TokenType.SYMBOL and (tok.value == "=" or tok.value == ":=")) then
      error(string.format("on (%s,%s), '=' or ':=' expected.", tok.line, tok.col))
    end
  end

  lex:next()
  assign = tok.value
  exp = parser:nextExp()
  lex:next(TokenType.EOL)

  --(6) return
  return Unpack.new(ln, col, typ, vars, assign, exp)
end
