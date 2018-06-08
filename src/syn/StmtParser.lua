--imports
local TokenType = require("dogma.lex.TokenType")
local SentType = require("dogma.syn.SentType")
local SubParser = require("dogma.syn._.SubParser")
local BlockParser = require("dogma.syn._.BlockParser")
local BreakStmt = require("dogma.syn._.BreakStmt")
local ConstStmt = require("dogma.syn._.ConstStmt")
local EnumStmt = require("dogma.syn._.EnumStmt")
local NextStmt = require("dogma.syn._.NextStmt")
local ReturnStmt = require("dogma.syn._.ReturnStmt")
local UseStmt = require("dogma.syn._.UseStmt")
local FromStmt = require("dogma.syn._.FromStmt")
local VarStmt = require("dogma.syn._.VarStmt")
local WhileStmt = require("dogma.syn._.WhileStmt")
local DoStmt = require("dogma.syn._.DoStmt")
local ForEachStmt = require("dogma.syn._.ForEachStmt")
local ForStmt = require("dogma.syn._.ForStmt")
local CatchCl = require("dogma.syn._.CatchCl")
local FinallyCl = require("dogma.syn._.FinallyCl")
local FnStmt = require("dogma.syn._.FnStmt")
local TypeStmt = require("dogma.syn._.TypeStmt")
local Param = require("dogma.syn._.Param")
local Params = require("dogma.syn._.Params")
local AsyncStmt = require("dogma.syn._.AsyncStmt")
local IfStmt = require("dogma.syn._.IfStmt")
local Exp = require("dogma.syn._.Exp")
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")
local PubStmt = require("dogma.syn._.PubStmt")
local ExportStmt = require("dogma.syn._.ExportStmt")
local WithStmt = require("dogma.syn._.WithStmt")

--Parser for the Dogma statements.
local StmtParser = {}
StmtParser.__index = StmtParser
setmetatable(StmtParser, {__index = SubParser})
package.loaded[...] = StmtParser

--Constructor.
--
--@param parser:Parser  Parser to use.
function StmtParser.new(parser)
  local self

  --(1) create
  self = setmetatable(SubParser.new(parser), StmtParser)
  self._.expParser = parser._.expParser

  --(2) return
  return self
end

--Read a const statement.
--
--@return ConstStmt
function StmtParser:nextConst()
  local lexer, exper = self._.lexer, self._.expParser
  local tok, ln, col, visib, stmt, sep

  --(1) read visibility
  tok = lexer:advance()
  ln, col = tok.line, tok.col

  if tok.type == TokenType.KEYWORD and (tok.value == "export" or tok.value == "pub") then
    lexer:next()
    visib = tok.value
  end

  --(2) read
  lexer:next(TokenType.KEYWORD, "const")
  stmt = ConstStmt.new(ln, col, visib)

  --(3) get separator
  tok = lexer:advance()

  if tok.type == TokenType.EOL then
    sep = "\n"
    lexer:next()
  else
    sep = ","
  end

  --(4) get variables
  while true do
    local name, val

    --read name
    tok = lexer:advance()

    if tok == nil or (sep == "\n" and tok.col <= stmt.col) then
      break
    end

    name = lexer:next(TokenType.NAME).value

    --read value
    lexer:next(TokenType.SYMBOL, "=")
    val = exper:next()

    --insert variable
    stmt:insert(name, val)

    --read separator
    if sep == "\n" then
      lexer:next(TokenType.EOL)
    else  --using comma as separator
      tok = lexer:next()

      if tok.type == TokenType.EOL then
        break
      end

      if not (tok.type == TokenType.SYMBOL and tok.value == ",") then
        error(string.format(
          "comma expected on (%s, %s) for separating variables.",
          tok.line,
          tok.col
        ))
      end
    end
  end

  --(5) return
  return stmt
end

--Read a break statement.
--
--@return BreakStmt
function StmtParser:nextBreak()
  local lexer = self._.lexer
  local tok, stmt

  --(1) read
  tok = lexer:next(TokenType.KEYWORD, "break")
  stmt = BreakStmt.new(tok.line, tok.col)

  --(2) get end of line
  lexer:next(TokenType.EOL)

  --(3) return
  return stmt
end

--Read a next statement.
--
--@return NextStmt
function StmtParser:nextNext()
  local lexer = self._.lexer
  local tok, stmt

  --(1) read
  tok = lexer:next(TokenType.KEYWORD, "next")
  stmt = NextStmt.new(tok.line, tok.col)

  --(2) get end of line
  lexer:next(TokenType.EOL)

  --(3) return
  return stmt
end

--Read a return statement.
--
--@return ReturnStmt
function StmtParser:nextReturn()
  local lex, exper = self._.lexer, self._.expParser
  local tok, stmt

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "return")
  stmt = ReturnStmt.new(tok.line, tok.col)

  --(2) get values
  tok = lex:advance()

  if tok.type ~= TokenType.EOL then
    stmt:insert(exper:next())
  end

  lex:next(TokenType.EOL)

  --(3) return
  return stmt
end

--Read a use stament.
--
--@return UseStmt
function StmtParser:nextUse()
  local lex = self._.lexer
  local tok, stmt, sep

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "use")
  stmt = UseStmt.new(tok.line, tok.col)

  --(2) get separator
  tok = lex:advance()

  if tok.type == TokenType.EOL then
    sep = "\n"
    lex:next()
  else
    sep = ","
  end

  --(3) get variables
  while true do
    local path, name

    tok = lex:advance()

    if tok == nil or (sep == "\n" and tok.col <= stmt.col) then
      break
    end

    --path
    path = lex:next(TokenType.LITERAL).value

    --as
    tok = lex:advance()

    if tok.type == TokenType.KEYWORD and tok.value == "as" then
      lex:next()  --as
      name = lex:next(TokenType.NAME).value
    end

    --insert
    stmt:insert(path, name)

    --read separator
    if sep == "\n" then
      lex:next(TokenType.EOL)
    else  --using comma as separator
      tok = lex:next()

      if tok.type == TokenType.EOL then
        break
      end

      if not (tok.type == TokenType.SYMBOL and tok.value == ",") then
        error(string.format(
          "comma expected on (%s, %s) for separating modules.",
          tok.line,
          tok.col
        ))
      end
    end
  end

  --(4) return
  return stmt
end

--Read a from statement.
--
--@return FromStmt
function StmtParser:nextFrom()
  local lex = self._.lexer
  local tok, ln, col, stmt

  --(1) read module
  tok = lex:next(TokenType.KEYWORD, "from")
  ln, col = tok.line, tok.col
  stmt = FromStmt.new(ln, col, lex:next(TokenType.LITERAL).value)

  --(2) items
  lex:next(TokenType.KEYWORD, "use")

  while true do
    local name, as

    --(1) item
    name = lex:next(TokenType.NAME).value

    tok = lex:advance()
    if tok.type == TokenType.KEYWORD and tok.value == "as" then
      lex:next()  --as
      as = lex:next(TokenType.NAME).value
    end

    stmt:insert(name, as)

    --(2) end?
    tok = lex:advance()
    if tok.type == TokenType.EOL then
      lex:next()
      break
    else
      lex:next(TokenType.SYMBOL, ",")
    end
  end

  --(3) return
  return stmt
end

--Read a var statement.
--
--@return VarStmt
function StmtParser:nextVar()
  local lexer, exper = self._.lexer, self._.expParser
  local tok, ln, col, stmt, visib, sep

  --(1) read visibility
  tok = lexer:advance()
  ln, col = tok.line, tok.col

  if tok.type == TokenType.KEYWORD and (tok.value == "export" or tok.value == "pub") then
    lexer:next()
    visib = tok.value
  end

  --(2) read
  lexer:next(TokenType.KEYWORD, "var")
  stmt = VarStmt.new(ln, col, visib)

  --(3) get separator
  tok = lexer:advance()

  if tok.type == TokenType.EOL then
    sep = "\n"
    lexer:next()
  else
    sep = ","
  end

  --(4) get variables
  while true do
    local name, val

    --read name
    tok = lexer:advance()

    if tok == nil or (sep == "\n" and tok.col <= stmt.col) then
      break
    end

    name = lexer:next(TokenType.NAME).value

    --read value
    tok = lexer:advance()

    if tok.type == TokenType.SYMBOL and tok.value == "=" then
      lexer:next()
      val = exper:next()
    else
      val = nil
    end

    --insert variable
    stmt:insert(name, val)

    --read separator
    if sep == "\n" then
      lexer:next(TokenType.EOL)
    else  --using comma as separator
      tok = lexer:next()

      if tok.type == TokenType.EOL then
        break
      end

      if not (tok.type == TokenType.SYMBOL and tok.value == ",") then
        error(string.format(
          "comma expected on (%s, %s) for separating variables.",
          tok.line,
          tok.col
        ))
      end
    end
  end

  --(5) return
  return stmt
end

--Read a next statement.
--
--@return EnumStmt
function StmtParser:nextEnum(annots)
  local lexer = self._.lexer
  local tok, ln, col, visib, name, stmt, sep

  --(1) create stmt
  tok = lexer:advance()
  ln, col = tok.line, tok.col

  --visibility
  if tok.type == TokenType.KEYWORD then
    if tok.value == "export" or tok.value == "pub" then
      lexer:next()
      visib = tok.value
    end
  end

  --enum Name
  lexer:next(TokenType.KEYWORD, "enum")
  name = lexer:next(TokenType.NAME).value

  --create
  stmt = EnumStmt.new(ln, col, annots, visib, name)

  --(2) read items
  tok = lexer:next()

  if tok.type == TokenType.SYMBOL and tok.value == "{" then
    sep = ","
  elseif tok.type == TokenType.EOL then
    sep = "\n"
  else
    error(string.format("invalid token on (%s, %s).", tok.line, tok.col))
  end

  while true do
    local item, value

    tok = lexer:advance()

    if tok == nil then
      break
    end

    if sep == "\n" and tok.col <= stmt.col then
      break
    end

    --name
    item = lexer:next(TokenType.NAME).value

    --value
    tok = lexer:advance()

    if tok.type == TokenType.SYMBOL and tok.value == "=" then
      lexer:next()  --=
      value = lexer:next(TokenType.LITERAL).value
    else
      value = nil
    end

    --insert
    stmt:insert(item, value)

    --separator
    if sep == "," then
      tok = lexer:advance()

      if tok.type == TokenType.SYMBOL and tok.value == "}" then
        lexer:next()
        break
      else
        lexer:next(TokenType.SYMBOL, ",")
      end
    else
      lexer:next(TokenType.EOL)
    end
  end

  --(3) return
  return stmt
end

--Read a while statement.
--
--@return WhileStmt
function StmtParser:nextWhile()
  local lex, parser = self._.lexer, self._.parser
  local tok, ln, col, btype, cond, iter, body, catch, fin

  --(1) read while keyword
  tok = lex:next(TokenType.KEYWORD, "while")
  ln, col = tok.line, tok.col

  --(2) read condition and iter
  --condition
  cond = parser:nextExp()

  --iter
  tok = lex:advance()

  if tok.type == TokenType.SYMBOL and tok.value == ";" then
    lex:next()
    iter = parser:nextExp()
  end

  --do
  lex:next(TokenType.KEYWORD, "do")

  tok = lex:advance()
  if tok.type == TokenType.EOL then
    lex:next()
    btype = 2
  else
    btype = 1
  end

  --(4) read rest
  body = self:_readBody(btype, col)
  catch = self:_readCatch(col)
  fin = self:_readFinally(col)

  --(5) return
  return WhileStmt.new(ln, col, cond, iter, body, catch, fin)
end

--Read a do statement.
--
--@return Dotmt
function StmtParser:nextDo()
  local lexer, parser = self._.lexer, self._.parser
  local tok, ln, col, cond, body, catch, fin

  --(1) read while keyword
  tok = lexer:next(TokenType.KEYWORD, "do")
  ln, col = tok.line, tok.col

  lexer:next(TokenType.DO)

  --(2) read body
  body = self:_readBody(2, col)

  --(3) read condition if existing
  tok = lexer:advance()

  if tok and tok.type == TokenType.KEYWORD and tok.value == "while" then
    lexer:next()
    cond = parser:nextExp()
    lexer:next(TokenType.EOL)
  end

  --(4) read rest
  catch = self:_readCatch(col)
  fin = self:_readFinally(col)

  --(5) return
  return DoStmt.new(ln, col, body, cond, catch, fin)
end

--Read for statement.
--
--@return ForStmt
function StmtParser:nextFor()
  local lex, parser = self._.lexer, self._.parser
  local tok, ln, col, def, cond, iter, btype, body, catch, fin

  --(1) read for keyword
  tok = lex:next(TokenType.KEYWORD, "for")
  ln, col = tok.line, tok.col

  --(2) variables
  def = {}

  while true do
    local name, val

    --name [= value]
    name = lex:next(TokenType.NAME).value

    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "=" then
      lex:next()
      val = parser:nextExp()
    else
      val = nil
    end

    table.insert(def, {name = name, value = val})

    --end?
    tok = lex:advance()

    if not (tok.type == TokenType.SYMBOL and tok.value == ",") then
      break
    end

    lex:next(TokenType.SYMBOL, ",")
  end

  lex:next(TokenType.SYMBOL, ";")

  --(3) cond
  cond = parser:nextExp()

  --(4) iter
  tok = lex:advance()
  if tok.type == TokenType.SYMBOL and tok.value == ";" then
    lex:next()
    iter = parser:nextExp()
  end

  --(5) rest
  lex:next(TokenType.KEYWORD, "do")

  tok = lex:advance()
  if tok.type == TokenType.EOL then
    lex:next()
    btype = 2
  else
    btype = 1
  end

  body = self:_readBody(btype, col)
  catch = self:_readCatch(col)
  fin = self:_readFinally(col)

  --(5) return
  return ForStmt.new(ln, col, def, cond, iter, body, catch, fin)
end

--Read for each statement.
--
--@return ForEachStmt
function StmtParser:nextForEach()
  local lex, parser = self._.lexer, self._.parser
  local tok, ln, col, key, val, iter, btype, body, catch, fin

  --(1) read for each keywords
  tok = lex:next(TokenType.KEYWORD, "for")
  lex:next(TokenType.KEYWORD, "each")
  ln, col = tok.line, tok.col

  --key
  key = lex:next(TokenType.NAME).value

  --value
  tok = lex:advance()

  if tok.type == TokenType.SYMBOL and tok.value == "," then
    lex:next()
    val = lex:next(TokenType.NAME).value
  else
    val, key = key, nil
  end

  --(3) read iter
  lex:next(TokenType.KEYWORD, "in")
  iter = parser:nextExp()

  --(4) read rest
  lex:next(TokenType.KEYWORD, "do")

  tok = lex:advance()
  if tok.type == TokenType.EOL then
    lex:next()
    btype = 2
  else
    btype = 1
  end

  body = self:_readBody(btype, col)
  catch = self:_readCatch(col)
  fin = self:_readFinally(col)

  --(5) return
  return ForEachStmt.new(ln, col, key, val, iter, body, catch, fin)
end

--Read a body statement as, fo example, while, for, if, etc.
--
--@param btype:number Body type: 1, one line; 2, block; 3, between {}.
--@param col:number   Column line where it starts.
--
--@return Sent[]
function StmtParser:_readBody(btype, col)
  local parser = self._.parser
  local body

  --(1) read body
  if btype == 1 then
    body = {parser:next()}
  elseif btype == 2 then
    body = BlockParser.new(parser, col):next()
  elseif btype == 3 then
    body = BlockParser.new(parser):next()
  end

  --(2) return
  return body
end

--Read a catch clause.
--
--@param col:number Column number where this must start.
--@return CatchCl
function StmtParser:_readCatch(col)
  local lexer, parser = self._.lexer, self._.parser
  local tok, var, body

  --(1) read catch keyword
  tok = lexer:advance()

  if tok == nil or not (tok.type == TokenType.KEYWORD and tok.value == "catch" and tok.col == col) then
    return
  end

  lexer:next()

  --(2) read error variable name
  tok = lexer:advance()

  if tok.type == TokenType.NAME then
    lexer:next()
    var = tok.value
  end

  lexer:next(TokenType.EOL)

  --(3) read body
  body = BlockParser.new(parser, col):next()

  --(4) return
  return CatchCl.new(var, body)
end

--Read a finally clause.
--
--@param col:number Column number where this must start.
--@return FinallyCl
function StmtParser:_readFinally(col)
  local lexer, parser = self._.lexer, self._.parser
  local tok, body

  --(1) read finally keyword
  tok = lexer:advance()

  if tok == nil or not (tok.type == TokenType.KEYWORD and tok.value == "finally" and tok.col == col) then
    return
  end

  lexer:next()
  lexer:next(TokenType.EOL)

  --(2) read body
  body = BlockParser.new(parser, col):next()

  --(4) return
  return FinallyCl.new(body)
end

--Read a fn statement.
--
--@return FnStmt
function StmtParser:nextFn(annots)
  local lexer = self._.lexer
  local tok, ln, col, visib, itype, name, params, rtype, rvar, body, catch, fin

  --(1) read visibility
  tok = lexer:advance()
  ln, col = tok.line, tok.col

  if tok.type == TokenType.KEYWORD and (tok.value == "export" or tok.value == "pub" or tok.value == "pvt") then
    lexer:next()
    visib = tok.value
  end

  --(2) read fn type.name
  lexer:next(TokenType.KEYWORD, "fn")
  name = lexer:next(TokenType.NAME).value

  tok = lexer:advance()
  if tok.type == TokenType.SYMBOL and (tok.value == "." or tok.value == ":") then
    lexer:next()
    visib = (tok.value == "." and "pub" or "pvt")
    itype = name
    name = lexer:next(TokenType.NAME).value
  end

  --(3) read parameters, return type and return variable
  params = self:_readFnParams()
  rvar = self:_readFnReturnVar()
  rtype = self:_readFnType()

  --(4) read body
  tok = lexer:advance()

  if tok.type == TokenType.SYMBOL and tok.value == "=" then
    lexer:next()
    body = {self._.expParser:_readExp()}

    if #body > 0 and body[1].type == SentType.EXP then
      local exp = body[1]

      body[1] = ReturnStmt.new(exp.line, exp.col)
      body[1]:insert(exp)
    end
  else
    lexer:next(TokenType.EOL)
    body = self:_readBody(2, col)
  end

  --(5) read rest
  catch = self:_readCatch(col)
  fin = self:_readFinally(col)

  --(6) return
  return FnStmt.new(ln, col, annots, visib, itype, name, params, rtype, rvar, body, catch, fin)
end

--Read the function parameters.
--
--@return Param[]
function StmtParser:_readFnParams()
  local lex = self._.lexer
  local params = Params.new()
  local tok

  --(1) read (
  lex:next(TokenType.SYMBOL, "(")

  --(2) read params
  tok = lex:advance()

  if not (tok.type == TokenType.SYMBOL and tok.value == ")") then
    while true do
      local const, mod, name, opt, dtype, val

      --const
      tok = lex:advance()

      if tok.type == TokenType.KEYWORD and tok.value == "const" then
        lex:next()
        const = true
      else
        const = false
      end

      --. or : or ...
      tok = lex:advance()

      if tok.type == TokenType.SYMBOL and (tok.value == "." or tok.value == ":" or tok.value == "...") then
        lex:next()
        mod = tok.value
      end

      --name
      name = lex:next(TokenType.NAME).value

      --optional?
      tok = lex:advance()

      if tok.type == TokenType.SYMBOL and tok.value == "?" then
        lex:next()
        opt = true
      end

      --type
      tok = lex:advance()

      if tok.type == TokenType.SYMBOL and tok.value == ":" then
        dtype = self:_readFnParamType()
      else
        dtype = nil
      end

      --default value
      if not opt then
        tok = lex:advance()

        if tok.type == TokenType.SYMBOL and tok.value == "=" then
          opt = true
          val = self:_readFnParamValue()
        elseif tok.type == TokenType.SYMBOL and tok.value == ":=" then
          opt = true
          val, dtype = self:_readFnParamValueWithInference()
        end
      end

      --insert param
      params:insert(Param.new(const, mod, name, opt, dtype, val))

      --,
      tok = lex:advance()

      if tok.type == TokenType.SYMBOL and tok.value == "," then
        lex:next()
      else
        break
      end
    end
  end

  --(3) read close
  lex:next(TokenType.SYMBOL, ")")

  --(4) return
  return params
end

--Read the parameter type.
--
--@return string
function StmtParser:_readFnParamType()
  local lex = self._.lexer
  local tok, dtype

  --(1) read
  lex:next(TokenType.SYMBOL, ":")

  tok = lex:advance()
  if tok.type == TokenType.SYMBOL and tok.value == "{" then
    lex:next()

    dtype = {}

    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "}" then
      lex:next()
    else
      while true do
        --read field
        local pname, ptype

        pname = lex:next(TokenType.NAME).value

        tok = lex:advance()
        if tok.type == TokenType.SYMBOL and tok.value == ":" then
          lex:next()
          ptype = lex:next(TokenType.NAME).value
        else
          ptype = "any"
        end

        table.insert(dtype, {name = pname, type = ptype})

        --read next or end
        tok = lex:advance()
        if tok.type == TokenType.SYMBOL and tok.value == "}" then
          lex:next()
          break
        end

        lex:next(TokenType.SYMBOL, ",")
      end --while
    end
  else
    dtype = lex:next(TokenType.NAME).value
  end

  --(2) return
  return dtype
end

--Read the parameter value wihtout inference.
--
--@return string
function StmtParser:_readFnParamValue()
  self._.lexer:next(TokenType.SYMBOL, "=")
  return self._.parser:nextExp()
end

--Read the parameter value using inference.
--
--@return val, type
function StmtParser:_readFnParamValueWithInference()
  local lex = self._.lexer
  local tok, val, dtype

  --(1) read
  lex:next(TokenType.SYMBOL, ":=")
  tok = lex:next()

  if tok.type == TokenType.LITERAL and type(tok.value) == "string" then
    val = Exp.new(tok.line, tok.col)
    val:insert(Terminal.new(TerminalType.TEXT, tok))
    dtype = "text"
  elseif tok.type == TokenType.LITERAL and type(tok.value) == "number" then
    val = Exp.new(tok.line, tok.col)
    val:insert(Terminal.new(TerminalType.NUM, tok))
    dtype = "num"
  elseif tok.type == TokenType.KEYWORD and tok.value == "true" then
    val = Exp.new(tok.line, tok.col)
    val:insert(Terminal.new(TerminalType.TRUE, tok))
    dtype = "bool"
  elseif tok.type == TokenType.KEYWORD and tok.value == "false" then
    val = Exp.new(tok.line, tok.col)
    val:insert(Terminal.new(TerminalType.FALSE, tok))
    dtype = "bool"
  else
    error(string.format(
      "on (%s, %s), for infering type, the default value must be a literal: text, num or bool.",
      tok.line,
      tok.col
    ))
  end

  --(2) return
  return val, dtype
end

--Read the function return type.
--
--@return string
function StmtParser:_readFnType()
  local lex = self._.lexer
  local tok, rtype

  --(1) read
  tok = lex:advance()

  if tok.type == TokenType.SYMBOL and tok.value == ":" then
    lex:next()  --:
    rtype = lex:next(TokenType.NAME).value
  end

  --(2) return
  return rtype
end

--Read the function return variable.
--
--@return string
function StmtParser:_readFnReturnVar()
  local lex = self._.lexer
  local tok, rvar

  --(1) read
  tok = lex:advance()

  if tok.type == TokenType.SYMBOL and tok.value == "->" then
    lex:next()  -- ->
    tok = lex:next()

    if tok.type == TokenType.KEYWORD and tok.value == "self" then
      rvar = "self"
    elseif tok.type == TokenType.NAME then
      rvar = tok.value
    else
      error(string.format(
        "on (%s, %s), return value must be 'self' or a name.",
        tok.line,
        tok.col
      ))
    end
  end

  --(2) return
  return rvar
end

--Read a type statement.
--
--@return TypeStmt
function StmtParser:nextType(annots)
  local lexer, parser = self._.lexer, self._.parser
  local tok, ln, col, visib, name, params, btype, bargs, body, catch, fin

  --(1) read visibility
  tok = lexer:advance()
  ln, col = tok.line, tok.col

  if tok.type == TokenType.KEYWORD and (tok.value == "export" or tok.value == "pub") then
    lexer:next()
    visib = tok.value
  end

  --(2) read type name
  lexer:next(TokenType.KEYWORD, "type")
  name = lexer:next(TokenType.NAME).value

  --(3) read parameters
  params = self:_readFnParams()

  --(4) read base type
  tok = lexer:advance()

  if tok.type == TokenType.SYMBOL and tok.value == ":" then
    lexer:next()
    btype = lexer:next(TokenType.NAME).value

    tok = lexer:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "(" then
      lexer:next()
      bargs = {}

      tok = lexer:advance()
      if not (tok.type == TokenType.SYMBOL and tok.value == ")") then
        while true do
          table.insert(bargs, parser:nextExp())

          tok = lexer:advance()
          if not (tok.type == TokenType.SYMBOL and tok.value == ",") then
            break
          end

          lexer:next(TokenType.SYMBOL, ",")
        end
      end

      lexer:next(TokenType.SYMBOL, ")")
    end
  end

  --(5) read body
  lexer:next(TokenType.EOL)
  body = self:_readBody(2, col)

  --(6) read rest
  catch = self:_readCatch(col)
  fin = self:_readFinally(col)

  --(6) return
  return TypeStmt.new(ln, col, annots, visib, name, params, btype, bargs, body, catch, fin)
end

--Read an async statement.
--
--@return AsyncStmt
function StmtParser:nextAsync()
  local lex, parser = self._.lexer, self._.parser
  local tok, ln, col, opts, body, catch

  --(1) read async keyword
  tok = lex:next(TokenType.KEYWORD, "async")
  ln, col = tok.line, tok.col

  --(2) read options
  opts = {}
  tok = lex:advance()

  if tok.type == TokenType.KEYWORD and tok.value == "with" then
    lex:next()
    lex:next(TokenType.SYMBOL, "{")
    lex:next(TokenType.NAME, "delay")
    lex:next(TokenType.SYMBOL, "=")
    opts.delay = parser:nextExp()
    lex:next(TokenType.SYMBOL, "}")
  end

  --(2) read body
  tok = lex:advance()

  if tok.type == TokenType.EOL then
    lex:next()
    body = self:_readBody(2, col)
    catch = self:_readCatch(col)
  else
    body = self:_readBody(1, col)
  end

  --(3) return
  return AsyncStmt.new(ln, col, opts, body, catch)
end

--Read an if statement.
--
--@return IfStmt
function StmtParser:nextIf()
  local lex, parser = self._.lexer, self._.parser
  local tok, ln, col, cond, body, elif, el

  --(1) read if keyword
  tok = lex:next(TokenType.KEYWORD, "if")
  ln, col = tok.line, tok.col

  --.(2) read condition
  cond = parser:nextExp()
  lex:next(TokenType.KEYWORD, "then")

  tok = lex:advance()

  if tok.type ~= TokenType.EOL then
    body = {parser:next()}

    tok = lex:advance()
    if tok and tok.type == TokenType.KEYWORD and tok.value == "else" then
      lex:next()
      el = {parser:next()}
    end
  else
    lex:next(TokenType.EOL)
    body = self:_readBody(2, col)

    while true do
      tok = lex:advance()

      if tok == nil or tok.col ~= col then
        break
      end

      if tok.type == TokenType.KEYWORD and tok.value == "else" then
        tok = lex:advance(2)

        if tok.type == TokenType.KEYWORD and tok.value == "if" then
          local c, b

          lex:next()  --else
          lex:next()  --if
          c = parser:nextExp()
          lex:next(TokenType.KEYWORD, "then")
          lex:next(TokenType.EOL)
          b = self:_readBody(2, col)

          if elif == nil then
            elif = {}
          end

          table.insert(elif, {cond = c, body = b})
        else
          lex:next()  --else
          el = self:_readBody(2, col)
        end
      else
        break
      end
    end
  end

  --(3) return
  return IfStmt.new(ln, col, cond, body, elif, el)
end

--Read a pub statement.
--
--@return PubStmt
function StmtParser:nextPub()
  local lex = self._.lexer
  local tok, ln, col, items, sep

  --(1) read pub keyword
  tok = lex:next(TokenType.KEYWORD, "pub")
  ln, col = tok.line, tok.col

  --(2) set seperator
  tok = lex:advance()

  if tok.type == TokenType.EOL then
    lex:next()
    sep = "\n"
  else
    sep = ","
  end

  --(3) read items
  items = {}

  while true do
    local item

    --item
    tok = lex:advance()

    if sep == "\n" and (not tok or tok.col <= col) then
      break
    end

    if tok and tok.type == TokenType.LITERAL and type(tok.value) == "string" then
      lex:next()
      item = {type = "use", value = tok.value}
    elseif tok and tok.type == TokenType.NAME then
      lex:next()
      item = {type = "pub", value = tok.value}
    else
      error(string.format("on (%s,%s), literal text or name expected.", tok.line, tok.col))
    end

    table.insert(items, item)

    --end or next?
    if sep == "\n" then
      lex:next(TokenType.EOL)
    else
      tok = lex:next()

      if tok.type == TokenType.EOL then
        break
      else
        if tok.type ~= TokenType.SYMBOL or tok.value ~= "," then
          error(string.format("on (%s,%s), comma expected.", tok.line, tok.col))
        end
      end
    end
  end

  --(4) return
  return PubStmt.new(ln, col, items)
end

--Read an export statement.
--
--@return ExportStmt
function StmtParser:nextExport()
  local lex, parser = self._.lexer, self._.parser
  local tok, ln, col, exp

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "export")
  ln, col = tok.line, tok.col

  exp = parser:nextExp()
  lex:next(TokenType.EOL)

  --(2) return
  return ExportStmt.new(ln, col, exp)
end

--Read a with statement.
--
--@return WithStmt
function StmtParser:nextWith()
  local lex, parser = self._.lexer, self._.parser
  local tok, ln, col, val, ifs, els

  --(1) read with
  tok = lex:next(TokenType.KEYWORD, "with")
  ln, col = tok.line, tok.col

  val = parser:nextExp()
  lex:next(TokenType.EOL)

  --(2) read ifs
  ifs = {}

  while true do
    local cond, ifCol, body

    tok = lex:advance()
    if not (tok and tok.type == TokenType.KEYWORD and tok.value == "if" and tok.col > col) then
      break
    end

    lex:next()  --if
    ifCol = tok.col
    cond = parser:nextExp()
    lex:next(TokenType.KEYWORD, "then")
    body = self:_readBody(2, ifCol)

    table.insert(ifs, {cond = cond, body = body})
  end

  --(3) read else
  tok = lex:advance()

  if tok and tok.type == TokenType.KEYWORD and tok.value == "else" and tok.col > col then
    lex:next()
    els = self:_readBody(2, tok.col)
  end

  --(4) return
  return WithStmt.new(ln, col, val, ifs, els)
end
