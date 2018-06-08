--imports
local Lexer = require("dogma.lex.Lexer")
local TokenType = require("dogma.lex.TokenType")
local DirectiveParser = require("dogma.syn.DirectiveParser")
local ExpParser = require("dogma.syn.ExpParser")
local StmtParser = require("dogma.syn.StmtParser")
local UnpackParser = require("dogma.syn.UnpackParser")

--A parser.
local Parser = {}
Parser.__index = Parser
package.loaded[...] = Parser

--Constructor.
function Parser.new()
  local self

  --(1) create
  self = setmetatable({_ = {}}, Parser)
  self._.lexer = Lexer.new()
  self._.directiveParser = DirectiveParser.new(self)
  self._.expParser = ExpParser.new(self)
  self._.stmtParser = StmtParser.new(self)
  self._.unpackParser = UnpackParser.new(self)
  self._.expParser._.stmtParser = self._.stmtParser

  --(2) return
  return self
end

--Parse a given text.
--
--@param txt:string   Text to parse.
--@param file?:string File name..
function Parser:parse(txt, file)
  self._.lexer:scan(txt, file)
end

--Parse the next sentence.
--
--@return Sentence
function Parser:next()
  local lex, stmter, unpacker, direr = self._.lexer, self._.stmtParser, self._.unpackParser, self._.directiveParser
  local sent, tok, annots

  --(1) remove white lines and read annotations
  annots = {}
  tok = lex:advance()
  while true do
    if tok == nil then
      break
    elseif tok.type == TokenType.EOL then
      lex:next()
    elseif tok.type == TokenType.ANNOTATION then
      lex:next()
      table.insert(annots, tok.value)
    else
      break
    end

    tok = lex:advance()
  end

   --(2) parse next sentence
  tok = lex:advance()

  if tok ~= nil then
    if tok.type == TokenType.DIRECTIVE then
      if tok.value:find("^if") then
        sent = direr:nextIf()
      elseif tok.value:find("^/") then
        sent = direr:nextRunWith()
      end
    elseif tok.type == TokenType.KEYWORD then
      if tok.value == "async" then
        sent = stmter:nextAsync()
      elseif tok.value == "break" then
        sent = stmter:nextBreak()
      elseif tok.value == "const" then
        tok = lex:advance(2)

        if tok.type == TokenType.SYMBOL and (tok.value == "{" or tok.value == "[") then
          sent = self._.unpackParser:next()
        else
          sent = stmter:nextConst()
        end
      elseif tok.value == "do" then
        sent = stmter:nextDo()
      elseif tok.value == "enum" then
        sent = stmter:nextEnum(annots)
      elseif tok.value == "export" or tok.value == "pub" or tok.value == "pvt" then
        local toParse = tok.value

        tok = lex:advance(2)

        if tok.type == TokenType.KEYWORD then
          if tok.value == "const" then
            tok = lex:advance(3)

            if tok.type == TokenType.SYMBOL and (tok.value == "{" or tok.value == "[") then
              sent = unpacker:next()
            else
              sent = stmter:nextConst()
            end
          elseif tok.value == "enum" then
            sent = stmter:nextEnum(annots)
          elseif tok.value == "fn" then
            sent = stmter:nextFn(annots)
          elseif tok.value == "type" then
            sent = stmter:nextType(annots)
          elseif tok.value == "var" then
            tok = lex:advance(3)

            if tok.type == TokenType.SYMBOL and (tok.value == "{" or tok.value == "[") then
              sent = unpacker:next()
            else
              sent = stmter:nextVar()
            end
          end
        end

        if not sent then
          if toParse == "pub" then
            sent = stmter:nextPub()
          elseif toParse == "export" then
            sent = stmter:nextExport()
          end
        end
      elseif tok.value == "fn" then
        sent = stmter:nextFn(annots)
      elseif tok.value == "for" then
        tok = lex:advance(2)

        if tok.type == TokenType.KEYWORD and tok.value == "each" then
          sent = stmter:nextForEach()
        else
          sent = stmter:nextFor()
        end
      elseif tok.value == "from" then
        sent = stmter:nextFrom()
      elseif tok.value == "if" then
        sent = stmter:nextIf()
      elseif tok.value == "next" then
        sent = stmter:nextNext()
      elseif tok.value == "return" then
        sent = stmter:nextReturn()
      elseif tok.value == "type" then
        sent = stmter:nextType(annots)
      elseif tok.value == "use" then
        sent = stmter:nextUse()
      elseif tok.value == "var" then
        tok = lex:advance(2)

        if tok.type == TokenType.SYMBOL and (tok.value == "{" or tok.value == "[") then
          sent = self._.unpackParser:next()
        else
          sent = stmter:nextVar()
        end
      elseif tok.value == "while" then
        sent = stmter:nextWhile()
      elseif tok.value == "with" then
        sent = stmter:nextWith()
      end
    end

    if not sent and tok.type == TokenType.SYMBOL and (tok.value == "[" or tok.value == "{") then
      sent = self._.unpackParser:next()
    end

    if not sent then
      sent = self:nextExp()
    end
  end

  --(3) return
  return sent
end

--Read the next expression.
--
--@return Exp
function Parser:nextExp()
  return self._.expParser:next()
end
