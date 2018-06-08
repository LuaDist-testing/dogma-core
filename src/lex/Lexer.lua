--imports
local stringx = require("pl.stringx")
local Reader = require("dogma.lex._.Reader")
local ProcessedList = require("dogma.lex._.ProcessedList")
local AdvancedList = require("dogma.lex._.AdvancedList")
local Eol = require("dogma.lex._.Eol")
local Annotation = require("dogma.lex._.Annotation")
local Comment = require("dogma.lex._.Comment")
local Directive = require("dogma.lex._.Directive")
local Name = require("dogma.lex._.Name")
local Keyword = require("dogma.lex._.Keyword")
local Literal = require("dogma.lex._.Literal")
local LiteralType = require("dogma.lex.LiteralType")
local Symbol = require("dogma.lex._.Symbol")
local TokenType = require("dogma.lex.TokenType")

--A lexer os scanner.
local Lexer = {}
Lexer.__index = Lexer
package.loaded[...] = Lexer

--Constructor.
--
--@param props:object Lexer properties.
function Lexer.new(props)
  local self

  --(1) arguments
  if not props then props = {} end

  --(2) create
  self = setmetatable({
    _ = {
      comments = not not props.comments
    }
  }, Lexer)

  --(3) return
  return self
end

--Raises an error.
--
--@param msg:string
function Lexer:throw(msg)
  error(string.format("%s: %s", self._.file, msg))
end

--Scan a text.
--
--@param text:string  Text to analyze.
--@param file?:string File path.
--
--@return self
function Lexer:scan(text, file)
  --(1) arguments
  if not text then self:throw("text expected.") end

  --(2) init
  self._.reader = Reader.new(text)
  self._.file = file or "anonymous code"
  self._.processed = ProcessedList.new(3)
  self._.token = nil
  self._.advanced = AdvancedList.new(3)

  --(3) return
  return self
end

--Return the last token that has been read.
--
--@return Token
function Lexer:_getLastReadToken()
  return self._.token
end

--Scan the next token.
--
--@overload
--@return Token
--
--@overload
--@param typ:TokenType  Token type to read.
--@param val:string     Token value to read.
--@return Token
function Lexer:next(typ, val)
  local reader = self._.reader
  local tok

  --(1) get token to return
  if self:_hasTokenToShift() then
    self:_shift()
  else
    local ch

    --get next char
    ch = reader:next()

    while ch ~= nil and (ch.char == " " or ch.char == "\t") do
      ch = reader:next()
    end

    if ch ~= nil then
      ch = ch.char

      --analyze token
      reader:unshift()

      if ch == "\n" then
        tok = self:_scanEol()
      elseif ch == "@" then
        tok = self:_scanAnnotation()
      elseif ch == "_" or stringx.isalpha(ch) then
        tok = self:_scanId()
      elseif ch == "'" then
        tok = self:_scanName()
      elseif stringx.isdigit(ch) then
        tok = self:_scanLiteralNumber()
      elseif ch == '"' then
        tok = self:_scanLiteralString()
      elseif ch == "#" then
        reader:next()
        ch = reader:next().char

        reader:unshift()
        reader:unshift()

        if ch == "!" then
          tok = self:_scanDirective()
        else
          tok = self:_scanComment()

          if not self._.comments then
            return self:next()
          end
        end
      else
        tok = self:_scanSymbol()
      end

      self:_backUpToken()
      self._.token = tok
    else
      self:_backUpToken()
      self._.token = nil
    end
  end

  --(2) check
  if typ then
    tok = self._.token

    if tok == nil then
      self:throw(string.format("'%s' expected at the end of code.", val))
    end

    if tok.type ~= typ or (val ~= nil and tok.value ~= val) then
      if typ == TokenType.EOL then
        self:throw(string.format(
          "end of line expected on (%s, %s).",
          tok.line,
          tok.col
        ))
      elseif typ == TokenType.NAME then
        self:throw(string.format(
          "name expected on (%s, %s).",
          tok.line,
          tok.col
        ))
      elseif typ == TokenType.LITERAL then
        self:throw(string.format(
          "literal expected on (%s, %s).",
          tok.line,
          tok.col
        ))
      else
        self:throw(string.format(
          "'%s' expected on (%s, %s).",
          val,
          tok.line,
          tok.col
        ))
      end
    end
  end

  --(3) return
  return self._.token
end

--Return the next token that must be an end of line.
--
--@return Eol
function Lexer:nextEol()
  return self:next(TokenType.EOL)
end

--Return the next token that must be an id: keyword or name.
--
--@return Id
function Lexer:nextId()
  local tok = self:advance()

  if tok.type == TokenType.KEYWORD or tok.type == TokenType.NAME then
    return self:next()
  else
    self:throw(string.format("on (%s, %s), id expected.", tok.line, tok.col))
  end
end

--Return the next token that must be a name.
--
--@return Name
function Lexer:nextName()
  return self:next(TokenType.NAME)
end

--Return the next token that must be a symbol.
--
--@return Symbol
function Lexer:nextSymbol(val)
  return self:next(TokenType.SYMBOL, val)
end

--Return the next token that must be a keyword.
--
--@return Keyword
function Lexer:nextKeyword(val)
  return self:next(TokenType.KEYWORD, val)
end

--Advance the next token.
--
--@return Token
function Lexer:advance(i)
  local tok

  --(1) arguments
  if i == nil then
    i = 1
  end

  --(2) get token
  if #self._.advanced >= i then
    tok = self._.advanced._.items[i]
  else
    if i == 1 then
      tok = self:next()
      self:unshift()
    elseif i == 2 then
      self:next()
      tok = self:next()
      self:unshift()
      self:unshift()
    elseif i == 3 then
      self:next()
      self:next()
      tok = self:next()
      self:unshift()
      self:unshift()
      self:unshift()
    end
  end

  --(3) return
  return tok
end

--Check whether the lexer has some token to shift.
--
--@return bool
function Lexer:_hasTokenToShift()
  return #self._.advanced > 0
end

--Shift a token: <- processed <- current <- advanced
function Lexer:_shift()
  --(1) pre
  if #self._.advanced == 0 then
    self:throw("no advanced token to shift.")
  end

  --(2) current to processed
  if self._.token then
    self._.processed:insert(self._.token)
  end

  --(3) advanced to current
  self._.token = self._.advanced:remove()
end

--Unshift a char: processed -> current -> advanced
function Lexer:unshift()
  --(1) pre
  if not self._.token and #self._.processed == 0 then
    self:throw("no current token to unshift.")
  end

  --(2) current to advanced
  self._.advanced:insert(self._.token)

  --(3) last processed to current
  if #self._.processed == 0 then
    self._.token = nil
  else
    self._.token = self._.processed:remove()
  end
end

--Shift current token to processed tokens: processed <- token.
function Lexer:_backUpToken()
  if self._.token then
    self._.processed:insert(self._.token)
  end
end

--Scan an end of line.
--
--@return Eol
function Lexer:_scanEol()
  local reader = self._.reader
  local ch = reader:next()

  return Eol.new(ch.line, ch.col)
end

--Scan an annotation.
--
--@return Annotation
function Lexer:_scanAnnotation()
  local rdr = self._.reader
  local state, ln, col, val
  local State = {
    START = 1,
    VALUE = 2,
    END = 3
  }

  --(1) state machine
  state = State.START

  while state ~= State.END do
    local ch = rdr:next()

    if state == State.START then
      ln, col, val = ch.line, ch.col, ""
      state = State.VALUE
    elseif state == State.VALUE then
      ch = ch.char

      if not (stringx.isalnum(ch) or ch == "_") then
        rdr:unshift()
        state = State.END
      else
        val = val .. ch
      end
    end
  end

  --(2) return
  return Annotation.new(ln, col, val)
end

--Scan a directive.
--
--@return Directive
function Lexer:_scanDirective()
  local rdr = self._.reader
  local state, ln, col, val
  local State = {
    START1 = 1,
    START2 = 2,
    VALUE = 3,
    END = 4
  }

  --(1) state machine
  state = State.START1

  while state ~= State.END do
    local ch = rdr:next()

    if state == State.START1 then
      ln, col, val = ch.line, ch.col, ""
      state = State.START2
    elseif state == State.START2 then
      state = State.VALUE
    elseif state == State.VALUE then
      ch = ch.char

      if ch == "\n" then
        state = State.END
      else
        val = val .. ch
      end
    end
  end

  if not (val:find("^if [a-zA-Z]+ then$") or val:find("^if not [a-zA-Z]+ then$") or val:find("^/") or val == "end" or val == "else") then
    self:throw(string.format("on (%s,%s), invalid directive.", ln, col))
  end

  --(2) return
  return Directive.new(ln, col, val)
end

--Scan a comment.
--
--@return Comment
function Lexer:_scanComment()
  local reader = self._.reader
  local state, ln, col, comm
  local State = {
    START = 1,
    TEXT = 2,
    POSSIBLE_END = 3,
    END = 4
  }

  --(1) state machine
  state = State.START

  while state ~= State.END do
    local ch = reader:next()

    if state == State.START then
      ln, col, comm = ch.line, ch.col, ""
      state = State.TEXT
    elseif state == State.TEXT then
      ch = ch.char

      if ch == "\n" then
        state = State.POSSIBLE_END
      else
        comm = comm .. ch
      end
    else  --POSSIBLE_END
      if ch == nil then
        reader:unshift()  --current: nil
        reader:unshift()  --end of line
        state = State.END
      else
        ch = ch.char

        if ch == "#" then
          comm = comm .. "\n"
          state = State.TEXT
        else
          reader:unshift()  --current char
          reader:unshift()  --eol
          state = State.END
        end
      end
    end
  end

  --(2) return
  return Comment.new(ln, col, comm)
end

--Scan an identifier.
--
--@return Id
function Lexer:_scanId()
  local reader = self._.reader
  local state, ln, col, id
  local State = {
    START = 1,
    MIDDLE = 2,
    END = 3
  }

  --(1) state machine
  state = State.START

  while state ~= State.END do
    local ch = reader:next()

    if state == State.START then
      ln, col = ch.line, ch.col
      id = ch.char
      state = State.MIDDLE
    else
      ch = ch.char

      if ch == "_" or stringx.isalnum(ch) then
        id = id .. ch
      else
        state = State.END
        reader:unshift()
      end
    end
  end

  --(2) return
  local last = self:_getLastReadToken()

  if (last and last.type == TokenType.SYMBOL and (last.value == "." or last.value == ":" or last.value == "?")) or
     not Keyword.isKeyword(id) then
    return Name.new(ln, col, id)
  else
    return Keyword.new(ln, col, id)
  end
end

--Scan a name.
--
--@return Name
function Lexer:_scanName()
  local reader = self._.reader
  local state, ln, col, id, ch
  local State = {
    START = 1,
    ID = 2,
    END = 3
  }

  --(1) state machine
  state = State.START
  ch = reader:next()  --'
  ln, col = ch.line, ch.col

  while state ~= State.END do
    ch = reader:next()

    if state == State.START then
      id = ch.char
      state = State.ID
    else --State.ID
      ch = ch.char

      if ch == "'" then
        state = State.END
      else
        id = id .. ch
      end
    end
  end

  --(2) return
  return Name.new(ln, col, id)
end

--Scan a symbol.
--
--@return Symbol
function Lexer:_scanSymbol()
  local reader = self._.reader
  local state, ln, col, sym
  local State = {
    START = 1,
    MIDDLE = 2,
    END = 3
  }
  local SYMBOLS = {
    ["+"] = true,
    ["+="] = true,
    ["-"] = true,
    ["-="] = true,
    ["->"] = true,
    ["*"] = true,
    ["*="] = true,
    ["**"] = true,
    ["**="] = true,
    ["/"] = true,
    ["/="] = true,
    ["%"] = true,
    ["%="] = true,
    ["="] = true,
    ["=="] = true,
    ["==="] = true,
    ["=~"] = true,
    ["!"] = true,
    ["!="] = true,
    ["!=="] = true,
    ["!~"] = true,
    ["<"] = true,
    ["<<"] = true,
    ["<<<"] = true,
    ["<<="] = true,
    ["<="] = true,
    [">"] = true,
    [">>"] = true,
    [">>>"] = true,
    [">>="] = true,
    [">="] = true,
    ["^"] = true,
    ["^="] = true,
    ["~"] = true,
    ["~="] = true,
    ["("] = true,
    [")"] = true,
    ["["] = true,
    ["]"] = true,
    ["{"] = true,
    ["}"] = true,
    [";"] = true,
    [":"] = true,
    [":="] = true,
    [":=|"] = true,
    ["."] = true,
    [".."] = true,
    ["..."] = true,
    [".="] = true,
    ["?"] = true,
    ["?="] = true,
    ["&"] = true,
    ["&="] = true,
    ["&&"] = true,
    ["|"] = true,
    ["|="] = true,
    ["||"] = true,
    [","] = true
  }

  --(1) state machine
  state = State.START

  while state ~= State.END do
    local ch = reader:next()

    if state == State.START then
      if SYMBOLS[ch.char] then
        ln, col, sym = ch.line, ch.col, ch.char
        state = State.MIDDLE
      else
        reader:unshift()
        state = State.END
      end
    else
      if SYMBOLS[sym .. ch.char] then
        sym = sym .. ch.char
      else
        reader:unshift()
        state = State.END
      end
    end
  end

  --(2) return
  if sym == nil then
    self:throw(string.format("invalid symbol on (%s, %s).", reader._.line, reader._.col - 1))
  end

  return Symbol.new(ln, col, sym)
end

--Scan a literal hnumber.
--
--@return Literal
function Lexer:_scanLiteralNumber()
  local reader = self._.reader
  local state, ln, col, lit
  local State = {
    START = 1,
    INT = 2,
    DOT = 3,
    DECIMAL = 4,
    END = 5
  }

  --(1) state machine
  state = State.START

  while state ~= State.END do
    local ch = reader:next()

    if state == State.START then
      ln, col, lit = ch.line, ch.col, ch.char
      state = State.INT
    elseif state == State.INT then
      ch = ch.char

      if stringx.isdigit(ch) then
        lit = lit .. ch
      elseif ch == " " then
        lit = lit --nothing to do
      elseif ch == "." then
        state = State.DOT
      else
        reader:unshift()
        state = State.END
      end
    elseif state == State.DOT then
      ch = ch.char

      if stringx.isdigit(ch) then
        lit = lit .. "." .. ch
        state = State.DECIMAL
      else
        reader:unshift() --current
        reader:unshift() --dot
        state = State.END
      end
    else  --DECIMAL
      ch = ch.char

      if stringx.isdigit(ch) then
        lit = lit .. ch
      else
        reader:unshift()
        state = State.END
      end
    end
  end

  --(2) return
  return Literal.new(ln, col, LiteralType.NUMBER, tonumber(lit))
end

--Scan a literal string.
--
--@return Literal
function Lexer:_scanLiteralString()
  local reader = self._.reader
  local state, ln, col, lit
  local State = {
    START = 1,
    START1 = 2,
    START2 = 3,
    TEXT1 = 4,
    TEXT3 = 5,
    END1 = 6,
    END2 = 7,
    END = 8,
    TEXT3_START = 9
  }

  --(1) state machine
  state = State.START

  while state ~= State.END do
    local ch = reader:next()

    ::START::if state == State.START then
      ln, col, lit = ch.line, ch.col, ""
      state = State.START1
    elseif state == State.START1 then
      ch = ch.char

      if ch == '"' then
        state = State.START2
      else
        lit = lit .. ch
        state = State.TEXT1
      end
    elseif state == State.START2 then
      ch = ch.char

      if ch == '"' then
        state = State.TEXT3_START
      else
        reader:unshift()
        state = State.END
      end
    elseif state == State.TEXT1 then  --"literal"
      if ch == nil then
        self:throw(string.format("literal string opened but not closed on (%s, %s).", ln, col))
      end

      ch = ch.char

      if ch == '"' then
        state = State.END
      else
        lit = lit .. ch
      end
    elseif state == State.TEXT3_START then
      state = State.TEXT3
      if ch.char ~= "\n" then goto START end
    elseif state == State.TEXT3 then  --"""literal"""
      if ch == nil then
        self:throw(string.format("literal string opened but not closed on (%s, %s).", ln, col))
      end

      if ch.col >= col or ch.char ~= " " then
        ch = ch.char

        if ch == '"' then
          state = State.END1
        else
          lit = lit .. ch
        end
      end
    elseif state == State.END1 then
      ch = ch.char

      if ch == '"' then
        state = State.END2
      else
        lit = lit .. '"' .. ch
        state = State.TEXT3
      end
    else  --State.END2
      if ch == nil then
        self:throw(string.format("literal string opened but not closed on (%s, %s).", ln, col))
      end

      ch = ch.char

      if ch == '"' then
        state = State.END

        if lit:sub(-1) == "\n" then
          lit = lit:sub(1, -2)
        end
      else
        lit = lit .. '""' .. ch
      end
    end
  end

  --(2) return
  return Literal.new(ln, col, LiteralType.STRING, lit)
end
