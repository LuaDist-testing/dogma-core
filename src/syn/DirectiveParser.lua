--imports
local SubParser = require("dogma.syn._.SubParser")
local TokenType = require("dogma.lex.TokenType")
local IfDirective = require("dogma.syn._.IfDirective")

--A directive parser.
local DirectiveParser = {}
DirectiveParser.__index = DirectiveParser
setmetatable(DirectiveParser, {__index = SubParser})
package.loaded[...] = DirectiveParser

--Constructor.
--
--@param parser:Parser  Parser to use.
function DirectiveParser.new(parser)
  return setmetatable(SubParser.new(parser), DirectiveParser)
end

--Read the next if directive.
--
--@return Directive
function DirectiveParser:nextIf()
  local lex, parser = self._.lexer, self._.parser
  local tok, ln, col, cond, body, el

  --(1) read if
  tok = lex:next(TokenType.DIRECTIVE)
  ln, col = tok.line, tok.col

  if tok.value:find("^if [a-zA-Z_0-9]+ then$") then
    cond = tok.value:match("^if ([a-zA-Z_0-9]+) then$")
  else
    cond = tok.value:match("^if (not [a-zA-Z_0-9]+) then$")
  end

  body = {}
  while true do
    tok = lex:advance()

    if tok == nil then
      break
    elseif tok.type == TokenType.EOL then
      lex:next()
    else
      if tok.type == TokenType.DIRECTIVE then
        if tok.value == "else" or tok.value == "end" then
          break
        else
          error(string.format("on (%s,%s), if directive can't be nested.", tok.line, tok.col))
        end
      end

      table.insert(body, parser:next())
    end
  end

  --(2) read else
  tok = lex:advance()

  if tok and tok.type == TokenType.DIRECTIVE and tok.value == "else" then
    lex:next()

    el = {}
    while true do
      tok = lex:advance()

      if tok.type == TokenType.EOL then
        lex:next()
      else
        if tok.type == TokenType.DIRECTIVE then
          if tok.value == "end" then
            break
          else
            error(string.format("on (%s,%s), else directive can't be nested.", tok.line, tok.col))
          end
        end

        table.insert(el, parser:next())
      end
    end
  end

  --(3) read end
  lex:next(TokenType.DIRECTIVE, "end")

  --(4) return
  return IfDirective.new(ln, col, cond, body, el)
end
