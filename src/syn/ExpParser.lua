--imports
local tablex = require("pl.tablex")
local TokenType = require("dogma.lex.TokenType")
local Keyword = require("dogma.lex._.Keyword")
local SubParser = require("dogma.syn._.SubParser")
local Terminal = require("dogma.syn._.Terminal")
local TerminalType = require("dogma.syn.TerminalType")
local SubExp = require("dogma.syn._.SubExp")
local IfSubExp = require("dogma.syn._.IfSubExp")
local UnaryOp = require("dogma.syn._.UnaryOp")
local BinOp = require("dogma.syn._.BinOp")
local SliceOp = require("dogma.syn._.SliceOp")
local CallOp = require("dogma.syn._.CallOp")
local Exp = require("dogma.syn._.Exp")
local LiteralList = require("dogma.syn._.LiteralList")
local LiteralMap = require("dogma.syn._.LiteralMap")
local LiteralFn = require("dogma.syn._.LiteralFn")
local PevalFn = require("dogma.syn._.PevalFn")
local NativeFn = require("dogma.syn._.NativeFn")
local ThrowFn = require("dogma.syn._.ThrowFn")
local ReturnStmt = require("dogma.syn._.ReturnStmt")
local PackOp = require("dogma.syn._.PackOp")
local AwaitFn = require("dogma.syn._.AwaitFn")
local PawaitFn = require("dogma.syn._.PawaitFn")
local UseFn = require("dogma.syn._.UseFn")
local IifFn = require("dogma.syn._.IifFn")
local UpdateOp = require("dogma.syn._.UpdateOp")
local Params = require("dogma.syn._.Params")

--An expression parser.
local ExpParser = {}
ExpParser.__index = ExpParser
setmetatable(ExpParser, {__index = SubParser})
package.loaded[...] = ExpParser

--Constructor.
--
--@param parser:Parser  Parser to use.
function ExpParser.new(parser)
  local self

  --(1) create
  self = setmetatable(SubParser.new(parser), ExpParser)
  self._.stmtParser = parser._.stmtParser

  --(2) return
  return self
end

--Read an expression.
--
--@return Exp
function ExpParser:next()
  return self:_readExp()
end

function ExpParser:_readExp()
  local lex = self._.lexer
  local tok, node, exp

  --(1) init expression
  tok = lex:advance()
  exp = Exp.new(tok.line, tok.col)

  --(2) read
  while true do
    tok = lex:next()

    if tok == nil then
      if exp.tree:isWellFormed() then
        break
      else
        error(string.format(
          "incomplete expression started on (%s, %s).",
          exp.line,
          exp.col
        ))
      end
    end

    if tok.type == TokenType.EOL then
      if exp.tree:isWellFormed() then
        lex:unshift()
        break
      end
    elseif tok.type == TokenType.SYMBOL and tok.value == "(" then
      lex:unshift()

      if exp.tree:isWellFormed() then
        self:_readCallArgs(exp)
      else
        exp:insert(self:_readSubExp())
      end
    elseif tok.type == TokenType.SYMBOL and tok.value == "[" then
      lex:unshift()

      if exp.tree:isWellFormed() then
        self:_readIndexOp(exp)
      else
        exp:insert(self:_readLiteralList())
      end
    elseif tok.type == TokenType.SYMBOL and tok.value == "{" then
      lex:unshift()

      if exp.tree:isWellFormed() then
        self:_readPackOp(exp)
      else
        exp:insert(self:_readLiteralMap())
      end
    elseif tok.type == TokenType.SYMBOL and (tok.value == "." or tok.value == ":") and lex:advance().type == TokenType.SYMBOL and lex:advance().value == "{" then
      lex:unshift() --the dot

      if exp.tree:isWellFormed() then
        self:_readUpdateOp(exp)
      else
        error(string.format("on (%s,%s), '.{' and ':{' are not unary ops.", tok.line, tok.col))
      end
    elseif tok.type == TokenType.KEYWORD and tok.value == "await" then
      lex:unshift()
      exp:insert(self:_readAwait())
    elseif tok.type == TokenType.KEYWORD and tok.value == "fn" then
      lex:unshift()
      exp:insert(self:_readFn())
    elseif tok.type == TokenType.KEYWORD and tok.value == "if" then
      lex:unshift()
      exp:insert(self:_readIfSubExp())
    elseif tok.type == TokenType.KEYWORD and tok.value == "iif" then
      lex:unshift()
      exp:insert(self:_readIif())
    elseif tok.type == TokenType.KEYWORD and tok.value == "native" then
      lex:unshift()
      exp:insert(self:_readNative())
    elseif tok.type == TokenType.KEYWORD and tok.value == "pawait" then
      lex:unshift()
      exp:insert(self:_readPawait())
    elseif tok.type == TokenType.KEYWORD and tok.value == "peval" then
      lex:unshift()
      exp:insert(self:_readPeval())
    elseif tok.type == TokenType.KEYWORD and tok.value == "throw" then
      lex:unshift()
      exp:insert(self:_readThrow())
    elseif tok.type == TokenType.KEYWORD and tok.value == "use" then
      lex:unshift()
      exp:insert(self:_readUse())
    else
      if tok.type == TokenType.KEYWORD and tok.value == "not" then
        local aux = lex:advance()

        if aux.type == TokenType.KEYWORD and aux.value == "in" then
          lex:next()
          node = BinOp.new(Keyword.new(tok.line, tok.col, "notin"))
        elseif aux.type == TokenType.KEYWORD and aux.value == "like" then
          lex:next()
          node = BinOp.new(Keyword.new(tok.line, tok.col, "notlike"))
        else
          node = UnaryOp.new(tok)
        end
      elseif tok.type == TokenType.KEYWORD and tok.value == "is" then
        local aux = lex:advance()

        if aux.type == TokenType.KEYWORD and aux.value == "not" then
          lex:next()
          node = BinOp.new(Keyword.new(tok.line, tok.col, "isnot"))
        else
          node = self:_getNodeOf(tok)
        end
      elseif tok.type == TokenType.SYMBOL and tablex.find({"+", "-", "<<<", ">>>"}, tok.value) then
        if exp.tree:isWellFormed() then
          node = BinOp.new(tok)
        else
          node = UnaryOp.new(tok)
        end
      elseif tok.type == TokenType.SYMBOL and tok.value == ":" then
        if exp.tree:isWellFormed() then
          node = BinOp.new(tok)
        else
          node = UnaryOp.new(tok)
        end
      elseif tok.type == TokenType.SYMBOL and tok.value == "." then
        if exp.tree:isWellFormed() then
          node = BinOp.new(tok)
        else
          node = UnaryOp.new(tok)
        end
      else
        node = self:_getNodeOf(tok)
      end

      if node == nil then
        if exp.tree:isWellFormed() then
          lex:unshift()
          break
        else
          error(string.format(
            "invalid expression node on (%s, %s).",
            tok.line,
            tok.col
          ))
        end
      else
        exp:insert(node)
      end
    end
  end

  --(3) return
  return exp
end

--Return a node for a given token.
--
--@param tok:Token  The token.
--@return Node
function ExpParser:_getNodeOf(tok)
  local node

  --(1) create node
  if tok.type == TokenType.NAME then
    node = Terminal.new(TerminalType.NAME, tok)
  elseif tok.type == TokenType.LITERAL then
    if type(tok.value) == "string" then
      node = Terminal.new(TerminalType.TEXT, tok)
    elseif type(tok.value) == "number" then
      node = Terminal.new(TerminalType.NUM, tok)
    end
  elseif tok.type == TokenType.KEYWORD then
    local kw = tok.value

    if kw == "nop" then
      node = Terminal.new(TerminalType.NOP, tok)
    elseif kw == "false" then
      node = Terminal.new(TerminalType.FALSE, tok)
    elseif kw == "nil" then
      node = Terminal.new(TerminalType.NIL, tok)
    elseif kw == "self" then
      node = Terminal.new(TerminalType.SELF, tok)
    elseif kw == "super" then
      node = Terminal.new(TerminalType.SUPER, tok)
    elseif kw == "true" then
      node = Terminal.new(TerminalType.TRUE, tok)
    elseif tablex.find({"and", "in", "is", "like", "or"}, kw) then
      node = BinOp.new(tok)
    end
  elseif tok.type == TokenType.SYMBOL then
    local sym = tok.value

    if tablex.find({"!", "~", "..."}, sym) then
      node = UnaryOp.new(tok)
    elseif tablex.find({
                          "+=", "-=", "*", "*=", "**", "**=", "/", "/=", "%", "%=",
                          "=", ".=", ":=", "?=", "==", "===", "=~", "!=", "!==", "!~",
                          "<", "<<", "<<<", "<<=", "<=", ">", ">>", ">>>", ">>=", ">=",
                          "^", "^=", ".", "?", ":", "&", "&=", "&&", "|", "|=", "||"
                       }, sym) then
      node = BinOp.new(tok)
    end
  end

  --(2) return
  return node
end

--Read (expr).
--
--@return Exp
function ExpParser:_readSubExp()
  local lex = self._.lexer
  local term, tok, ln, col

  --(1) read
  tok = lex:next(TokenType.SYMBOL, "(")
  ln, col = tok.line, tok.col
  term = SubExp.new(ln, col, self:_readExp())
  lex:next(TokenType.SYMBOL, ")")

  --(2) return
  return term
end

--Read if then else end.
--
--@return IfSubExp
function ExpParser:_readIfSubExp()
  local lex = self._.lexer
  local tok, ln, col, cond, tcase, fcase

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "if")
  ln, col = tok.line, tok.col
  cond = self:_readExp()
  lex:next(TokenType.KEYWORD, "then")
  tcase = self:_readExp()

  tok = lex:advance()
  if tok.type == TokenType.KEYWORD and tok.value == "else" then
    lex:next(TokenType.KEYWORD, "else")
    fcase = self:_readExp()
  end

  lex:next(TokenType.KEYWORD, "end")

  --(2) return
  return IfSubExp.new(ln, col, cond, tcase, fcase)
end

--Read an iif() terminal.
--
--@return IifFn
function ExpParser:_readIif()
  local lex = self._.lexer
  local tok, ln, col, cond, onTrue, onFalse

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "iif")
  ln, col = tok.line, tok.col
  lex:next(TokenType.SYMBOL, "(")
  cond = self:_readExp()
  lex:next(TokenType.SYMBOL, ",")
  onTrue = self:_readExp()
  tok = lex:advance()
  if tok.type == TokenType.SYMBOL and tok.value == "," then
    lex:next(TokenType.SYMBOL, ",")
    onFalse = self:_readExp()
  end
  lex:next(TokenType.SYMBOL, ")")

  --(2) return
  return IifFn.new(ln, col, cond, onTrue, onFalse)
end

--Read a native(code) terminal.
--
--@return NativeFn
function ExpParser:_readNative()
  local lex = self._.lexer
  local tok, ln, col, code

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "native")
  ln, col = tok.line, tok.col
  lex:next(TokenType.SYMBOL, "(")
  code = lex:next(TokenType.LITERAL).value
  lex:next(TokenType.SYMBOL, ")")

  --(2) return
  return NativeFn.new(ln, col, code)
end

--Read an await(Exp) terminal.
--
--@return AwaitFn
function ExpParser:_readAwait()
  local lex = self._.lexer
  local tok, ln, col, exp

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "await")
  ln, col = tok.line, tok.col
  lex:next(TokenType.SYMBOL, "(")
  exp = self:_readExp()
  lex:next(TokenType.SYMBOL, ")")

  --(2) return
  return AwaitFn.new(ln, col, exp)
end

--Read a pawait(Exp) terminal.
--
--@return PawaitFn
function ExpParser:_readPawait()
  local lex = self._.lexer
  local tok, ln, col, exp

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "pawait")
  ln, col = tok.line, tok.col
  lex:next(TokenType.SYMBOL, "(")
  self:_nextEols()
  exp = self:_readExp()
  self:_nextEols()
  lex:next(TokenType.SYMBOL, ")")

  --(2) return
  return PawaitFn.new(ln, col, exp)
end

--Read a use(Exp) terminal.
--
--@return UseFn
function ExpParser:_readUse()
  local lex = self._.lexer
  local tok, ln, col, exp

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "use")
  ln, col = tok.line, tok.col
  lex:next(TokenType.SYMBOL, "(")
  exp = self:_readExp()
  lex:next(TokenType.SYMBOL, ")")

  --(2) return
  return UseFn.new(ln, col, exp)
end

--Read a peval(Exp) terminal.
--
--@return PevalFn
function ExpParser:_readPeval()
  local lex = self._.lexer
  local tok, ln, col, exp

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "peval")
  ln, col = tok.line, tok.col
  lex:next(TokenType.SYMBOL, "(")
  exp = self:_readExp()
  lex:next(TokenType.SYMBOL, ")")

  --(2) return
  return PevalFn.new(ln, col, exp)
end

--Read a throw(Exp [, Exp]) terminal.
--
--@return ThrowFn
function ExpParser:_readThrow()
  local lex = self._.lexer
  local tok, ln, col, args

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "throw")
  ln, col = tok.line, tok.col
  lex:next(TokenType.SYMBOL, "(")

  args = {}
  while true do
    table.insert(args, self:_readExp())

    tok = lex:advance()
    if not (tok.type == TokenType.SYMBOL and tok.value == ",") then
      break
    end

    lex:next(TokenType.SYMBOL, ",")
  end

  lex:next(TokenType.SYMBOL, ")")

  --(2) return
  return ThrowFn.new(ln, col, args)
end

--Read a call arguments.
--
--@param exp:Exp  Current expression.
function ExpParser:_readCallArgs(exp)
  local lex = self._.lexer
  local tok, call

  --(1) pre: read (
  tok = lex:next(TokenType.SYMBOL, "(")
  tok.value = "()"

  --(2) create operator
  call = CallOp.new(tok)
  exp:insert(call)

  --(3) read arguments
  tok = lex:advance()

  if tok.type == TokenType.SYMBOL and tok.value == ")" then
    lex:next()
    call.finished = true
  else
    local sep = ","

    if tok.type == TokenType.EOL then
      lex:next()
      sep = "\n"
    end

    while true do
      call:insert(self:_readExp())

      tok = lex:next()

      if tok.type == TokenType.SYMBOL and tok.value == ")" then
        call.finished = true
        break
      end

      if sep == "," then
        if tok.type ~= TokenType.SYMBOL and tok.value ~= "," then
          error(string.format(
            "on (%s, %s), comma expected for argument end or ) for call end.",
            tok.line,
            tok.col
          ))
        end
      elseif sep == "\n" then
        if tok.type ~= TokenType.EOL then
          error(string.format(
            "on (%s, %s), end of line expected for argument end.",
            tok.line,
            tok.col
          ))
        end

        tok = lex:advance()

        if tok.type == TokenType.SYMBOL and tok.value == ")" then
          lex:next()
          call.finished = true
          break
        end
      end
    end
  end
end

--Read a literal list: [...].
--
--@return LiteralList
function ExpParser:_readLiteralList()
  local lex = self._.lexer
  local tok, ln, col, items

  --(1) read [
  tok = lex:next(TokenType.SYMBOL, "[")
  ln, col = tok.line, tok.col

  --(2) read items]
  items = {}

  tok = lex:advance()
  if not (tok.type == TokenType.SYMBOL and tok.value == ']') then
    local sep

    if tok.type == TokenType.EOL then
      lex:next()
      sep = "\n"
    else
      sep = ","
    end

    while true do
      --skip ends of line
      if sep == "\n" then
        self:_nextEols()

        tok = lex:advance()
        if tok.type == TokenType.SYMBOL and tok.value == "]" then
          break
        end
      end

      table.insert(items, self:_readExp())

      if sep == "," then
        tok = lex:advance()

        if tok.type == TokenType.SYMBOL and tok.value == "," then
          lex:next()
        else
          break
        end
      end
    end
  end

  lex:next(TokenType.SYMBOL, "]")

  --(4) return
  return LiteralList.new(ln, col, items)
end

--Read a literal map: {...}.
--
--@return LiteralMap
function ExpParser:_readLiteralMap()
  local lex = self._.lexer
  local tok, ln, col, entries

  --(1) read {
  tok = lex:next(TokenType.SYMBOL, "{")
  ln, col = tok.line, tok.col

  --(2) read entries}
  entries = {}

  tok = lex:advance()
  if not (tok.type == TokenType.SYMBOL and tok.value == '}') then
    local sep

    if tok.type == TokenType.EOL then
      lex:next()
      sep = "\n"
    else
      sep = ","
    end

    while true do
      local name, val, brackets

      --skip ends of line
      if sep == "\n" then
        self:_nextEols()

        tok = lex:advance()
        if tok.type == TokenType.SYMBOL and tok.value == "}" then
          break
        end
      end

      --read item
      tok = lex:advance()

      if tok.type == TokenType.SYMBOL and tok.value == "{" then
        lex:next(TokenType.SYMBOL, "{")
        name = lex:nextId().value
        brackets = true
        lex:next(TokenType.SYMBOL, "}")
      else
        name = lex:nextId().value
        brackets = false
      end

      tok = lex:advance()
      if tok.type == TokenType.SYMBOL and tok.value == "=" then
        lex:next(TokenType.SYMBOL, "=")
        val = self:_readExp()
        if brackets then
          local op = BinOp.new({line = tok.line, col = tok.col, value = "."})
          val:insert(op)
          op:insert(Terminal.new(TerminalType.NAME, {line = tok.line, col = tok.col, value = name}))
        end
      else
        val = Exp.new(tok.line, tok.col)
        val:insert(Terminal.new(TerminalType.NAME, {line = tok.line, col = tok.col, value = name}))
      end

      table.insert(entries, {name = name, value = val})

      --read sep
      if sep == "," then
        tok = lex:advance()

        if tok.type == TokenType.SYMBOL and tok.value == "," then
          lex:next()
        else
          break
        end
      end
    end
  end

  lex:next(TokenType.SYMBOL, "}")

  --(4) return
  return LiteralMap.new(ln, col, entries)
end

--Read a fn.
--
--@return LiteralFn
function ExpParser:_readFn()
  local lex, stmt = self._.lexer, self._.stmtParser
  local tok, ln, col, params, rtype, rvar, body

  --(1) read
  tok = lex:next(TokenType.KEYWORD, "fn")
  ln, col = tok.line, tok.col

  tok = lex:advance()
  if tok.type == TokenType.SYMBOL and tok.value == "{" then
    lex:nextSymbol("{")
    params = Params.new()

    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "}" then
      body = {}
    else
      body = {self:_readExp()}
    end
    
    lex:nextSymbol("}")
  else
    params = stmt:_readFnParams()
    rvar = stmt:_readFnReturnVar()
    rtype = stmt:_readFnType()

    tok = lex:advance()
    if tok.type == TokenType.SYMBOL and tok.value == "=" then
      lex:next()
      body = self:_readExp()
      body = {ReturnStmt.new(body.ln, body.col, body)}
      lex:next(TokenType.KEYWORD, "end")
    else
      body = stmt:_readBody(3)
    end
  end

  --(2) return
  return LiteralFn.new(ln, col, params, rtype, rvar, body)
end

--Read an indexing operator.
--
--@param exp:Exp  Expression to update.
function ExpParser:_readIndexOp(exp)
  local lex = self._.lexer
  local tok, ln, col, init, fin

  --(1) read [Exp
  tok = lex:next(TokenType.SYMBOL, "[")
  ln, col = tok.line, tok.col
  init = self:next()

  --(2) read "", Exp" if existing
  tok = lex:advance()

  if tok.type == TokenType.SYMBOL and tok.value == "," then
    lex:next()
    fin = self:next()
  end

  --(3) read ]
  lex:next(TokenType.SYMBOL, "]")

  --(4) add
  local op

  if fin == nil then
    op = BinOp.new({line = ln, col = col, value = "[]"})
    exp:insert(op)
    op:insert(init.tree.root)
  else
    op = SliceOp.new({line = ln, col = col, value = "[]"})
    exp:insert(op)
    op:insert(init.tree.root)
    op:insert(fin.tree.root)
  end
end

--Read the next {name,name...} op.
--
--@param exp:Exp  Expression to update.
function ExpParser:_readPackOp(exp)
  local lex = self._.lexer
  local tok, op

  --(1) read {
  tok = lex:next(TokenType.SYMBOL, "{")

  --(2) create op
  tok.value = "{}"
  op = PackOp.new(tok)
  exp:insert(op)

  --(3) read fields
  tok = lex:advance()
  if not (tok.type == TokenType.SYMBOL and tok.value == "}") then
    local all = false

    while true do
      local visib, name, value

      --read
      tok = lex:advance()

      if tok.type == TokenType.SYMBOL and tok.value == "*" then
        if #op.children > 1 then
          error(string.format("on (%s,%s), '*' only allowed as first item.", tok.line, tok.col))
        end

        lex:next()
        visib = "."
        name = "*"
        all = true
      elseif tok.type == TokenType.SYMBOL and (tok.value == "." or tok.value == ":") then
        lex:next()
        visib = tok.value
        name = ""
      else
        visib = "."
        name = ""
      end

      value = nil

      if name ~= "*" then
        name = lex:nextId().value

        if all then
          lex:next(TokenType.SYMBOL, "=")
          value = self:_readExp()
        else
          tok = lex:advance()

          if tok.type == TokenType.SYMBOL and tok.value == "=" then
            lex:next()
            value = self:_readExp()
          end
        end
      end

      table.insert(op.children, {visib = visib, name = name, value = value})

      --end?
      tok = lex:advance()

      if tok.type == TokenType.SYMBOL and tok.value == "}" then
        break
      end

      lex:next(TokenType.SYMBOL, ",")
    end
  end

  --(4) read }
  lex:next(TokenType.SYMBOL, "}")
  op.finished = true
end

--Read an update op: Exp.{} or Exp:{}.
function ExpParser:_readUpdateOp(exp)
  local lex = self._.lexer
  local tok, op, sep

  --(1) read .{ or :{
  tok = lex:next()

  if tok.value == "." then
    tok.value = ".{}"
    op = UpdateOp.new(tok, ".")
  else
    tok.value = ".{}"
    op = UpdateOp.new(tok, ":")
  end

  lex:nextSymbol("{")

  --(2) insert op in exp
  exp:insert(op)

  --(3) read separator
  tok = lex:advance()

  if tok.type == TokenType.EOL then
    lex:next()
    sep = "\n"
  else
    sep = ","
  end

  --(4) read fields
  while true do
    local name, type, value, assign

    --id, {id...} or (id...)
    tok = lex:advance()

    if tok.type == TokenType.SYMBOL and (tok.value == "{" or tok.value == "(") then
      type = (tok.value == "{" and "mapped" or "extended")
      lex:next()
      name = {}

      while true do
        table.insert(name, lex:nextId().value)

        tok = lex:advance()
        if tok.type == TokenType.SYMBOL and tok.value == "," then
          lex:next()
        else
          break
        end
      end

      lex:nextSymbol(type == "mapped" and "}" or ")")
    else
      type = nil
      name = lex:nextId().value
    end

    --=, :=, .=, ?=
    tok = lex:advance()

    if tok.type == TokenType.SYMBOL and tablex.find({"=", ":=", ".=", "?="}, tok.value) then
      lex:next()
      assign = tok.value
      value = self:_readExp()
    else
      value, assign = nil, nil
    end

    --add field
    table.insert(op.children, {name = name, type = type, assign = assign, value = value})

    --end or next?
    if sep == "," then
      tok = lex:advance()

      if tok.type == TokenType.SYMBOL and tok.value == "," then
        lex:next()
      elseif tok.type == TokenType.SYMBOL and tok.value == "}" then
        break
      else
        error(string.format("on (%s,%s), ',' or '}' expected.", tok.line, tok.col))
      end
    else
      self:_nextEols()
      tok = lex:advance()
      if tok.type == TokenType.SYMBOL and tok.value == "}" then
        break
      end
    end
  end

  --(5) read }
  lex:nextSymbol("}")
  op.finished = true
end
