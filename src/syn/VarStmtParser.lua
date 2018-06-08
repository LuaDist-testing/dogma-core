--imports
local TokenType = require("dogma.lex.TokenType")
local SubParser = require("dogma.syn._.SubParser")
local ConstStmt = require("dogma.syn._.ConstStmt")
local VarStmt = require("dogma.syn._.VarStmt")

--A var/const statement parser.
local VarStmtParser = {}
VarStmtParser.__index = VarStmtParser
setmetatable(VarStmtParser, {__index = SubParser})
package.loaded[...] = VarStmtParser

--Constructor.
--
--@param parser:Parser  Parent parser.
function VarStmtParser.new(parser)
  local self

  --(1) create
  self = setmetatable(SubParser.new(parser), VarStmtParser)
  self._.expParser = parser._.expParser

  --(2) return
  return self
end

--Read a const statement.
--
--@return ConstStmt
function VarStmtParser:nextConst()
  local lex = self._.lexer
  local tok, ln, col, visib, sep, decls

  --(1) read visibility
  tok = lex:advance()
  ln, col = tok.line, tok.col

  if tok.type == TokenType.KEYWORD and (tok.value == "export" or tok.value == "pub") then
    lex:next()
    visib = tok.value
  end

  --(2) read const keyword
  lex:nextKeyword("const")

  --(3) get separator
  tok = lex:advance()

  if tok.type == TokenType.EOL then
    sep = "\n"
    lex:next()
  else
    sep = ","
  end

  --(4) get declarations
  decls = {}

  while true do
    --end?
    tok = lex:advance()

    if tok == nil or (sep == "\n" and tok.col <= col) then
      break
    end

    --read declaration
    table.insert(decls, self:nextConstDecl())

    --read separator
    if sep == "\n" then
      lex:nextEol()
    else  --using comma as separator
      tok = lex:advance()

      if tok.type == TokenType.EOL then
        break
      end

      lex:nextSymbol(",")
    end
  end

  --(5) return
  return ConstStmt.new(ln, col, visib, decls)
end

function VarStmtParser:nextConstDecl()
  local lex = self._.lexer
  local tok = lex:advance()

  if tok.type == TokenType.SYMBOL and tok.value == "{" then
    return self:nextMap()
  elseif tok.type == TokenType.SYMBOL and tok.value == "[" then
    return self:nextList()
  else
    return self:nextConstStd()
  end
end

function VarStmtParser:nextConstStd()
  local lex, exp = self._.lexer, self._.expParser
  local name, val

  --(1) name
  name = lex:nextName().value
  lex:nextSymbol("=")
  val = exp:next()

  --(2) return
  return {type = "std", name = name, value = val}
end

--Read a var statement.
--
--@return VarStmt
function VarStmtParser:nextVar()
  local lex = self._.lexer
  local tok, ln, col, visib, sep, decls

  --(1) read visibility
  tok = lex:advance()
  ln, col = tok.line, tok.col

  if tok.type == TokenType.KEYWORD and (tok.value == "export" or tok.value == "pub") then
    lex:next()
    visib = tok.value
  end

  --(2) read var keyword
  lex:nextKeyword("var")

  --(3) get separator
  tok = lex:advance()

  if tok.type == TokenType.EOL then
    sep = "\n"
    lex:next()
  else
    sep = ","
  end

  --(4) get declarations
  decls = {}

  while true do
    --end?
    tok = lex:advance()

    if tok == nil or (sep == "\n" and tok.col <= col) then
      break
    end

    --read declaration
    table.insert(decls, self:nextVarDecl())

    --read separator
    if sep == "\n" then
      lex:nextEol()
    else  --using comma as separator
      tok = lex:advance()

      if tok.type == TokenType.EOL then
        break
      end

      lex:nextSymbol(",")
    end
  end

  --(5) return
  return VarStmt.new(ln, col, visib, decls)
end

--Return the next var declaration.
function VarStmtParser:nextVarDecl()
  local lex = self._.lexer
  local tok = lex:advance()

  if tok.type == TokenType.SYMBOL and tok.value == "{" then
    return self:nextMap()
  elseif tok.type == TokenType.SYMBOL and tok.value == "[" then
    return self:nextList()
  else
    return self:nextVarStd()
  end
end

function VarStmtParser:nextVarStd()
  local lex, exp = self._.lexer, self._.expParser
  local tok, name, val

  --(1) name
  name = lex:nextName().value

  tok = lex:advance()
  if tok.type == TokenType.SYMBOL and tok.value == "=" then
    lex:nextSymbol("=")
    val = exp:next()
  end

  --(2) return
  return {type = "std", name = name, value = val}
end

function VarStmtParser:nextMap()
  local lex, exp = self._.lexer, self._.expParser
  local names, val

  --(1) names
  lex:nextSymbol("{")

  names = {}
  while true do
    local tok

    table.insert(names, lex:nextName().value)

    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "}" then
      break
    end

    lex:nextSymbol(",")
  end

  lex:nextSymbol("}")
  lex:nextSymbol("=")
  val = exp:next()

  --(2) return
  return {type = "map", names = names, value = val}
end

function VarStmtParser:nextList()
  local lex, exp = self._.lexer, self._.expParser
  local names, val

  --(1) names
  lex:nextSymbol("[")

  names = {}
  while true do
    local tok

    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "..." then
      lex:nextSymbol("...")
      table.insert(names, "..." .. lex:nextName().value)
    else
      table.insert(names, lex:nextName().value)
    end

    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "]" then
      break
    end

    lex:nextSymbol(",")
  end

  lex:nextSymbol("]")
  lex:nextSymbol("=")
  val = exp:next()

  --(2) return
  return {type = "list", names = names, value = val}
end
