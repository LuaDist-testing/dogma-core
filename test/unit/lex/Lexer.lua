--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Lexer = require("dogma.lex.Lexer")
local TokenType = require("dogma.lex.TokenType")
local LiteralType = require("dogma.lex.LiteralType")

--Suite.
return suite("dogma.lex.Lexer", function()
  -----------------
  -- constructor --
  -----------------
  suite("constructor", function()
    test("constructor()", function()
      assert(Lexer.new()._):has({comments = false})
    end)

    test("constructor({})", function()
      assert(Lexer.new({})._):has({comments = false})
    end)

    test("constructor({comments = true})", function()
      assert(Lexer.new({comments = true})._):has({comments = true})
    end)
  end)

  ------------
  -- scan() --
  ------------
  suite("scan()", function()
    test("scan() - error -text expected", function()
      assert(function() Lexer.new():scan() end):raises("text expected.")
    end)

    test("scan(text) - ok", function()
      local lexer = Lexer.new()

      lexer:scan("#comment")
      assert(lexer._):has({
        file = "anonymous code",
        token = nil
      })
      assert(lexer._.reader):isTable()
      assert(lexer._.processed):isTable():isEmpty()
      assert(lexer._.advanced):isTable():isEmpty()
    end)

    test("scan(text, file) - ok", function()
      local lexer = Lexer.new()

      lexer:scan("#comment", "file.dog")
      assert(lexer._):has({
        file = "file.dog",
        token = nil
      })
      assert(lexer._.reader):isTable()
      assert(lexer._.processed):isTable():isEmpty()
      assert(lexer._.advanced):isTable():isEmpty()
    end)
  end)

  --------------
  -- _shift() --
  --------------
  suite("_shift()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("_shift() - ok", function()
      lexer:scan("1+2-3")

      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 1, value = 1})
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 2, value = "+"})
      assert(lexer:next()):isTable():has({type = TokenType.LITEAL, subtype = LiteralType.NUMBER, line = 1, col = 3, value = 2})
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 4, value = "-"})
      lexer:unshift()
      assert(lexer._.token):has({type = TokenType.Literal, subtype = LiteralType.NUMBER, line = 1, col = 3, value = 2})
      assert(lexer._.advanced._.items):eq({
        {type = TokenType.SYMBOL, line = 1, col = 4, value = "-"}
      })
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 4, value = "-"})
    end)

    test("_shift() - error", function()
      lexer:scan("1+2")
      assert(function() lexer:_shift() end):raises("no advanced token to shift.")
    end)
  end)

  ---------------
  -- unshift() --
  ---------------
  suite("unshift()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("unshift() - error - no current token to unshift", function()
      lexer:scan("1+2-3")
      assert(function() lexer:unshift() end):raises("no current token to unshift.")
    end)

    test("unshift() - error", function()
      lexer:scan("1+2-3")
      lexer:next()
      lexer:unshift()
    end)
  end)

  ----------------
  -- _scanEol() --
  ----------------
  suite("_scanEol()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("_scanEol() - several lines", function()
      lexer:scan("\n\n\n")

      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 1})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 2, col = 1})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 3, col = 1})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 4, col = 1})
      assert(lexer:next()):isNil()
    end)
  end)

  -----------------------
  -- _scanAnnotation() --
  -----------------------
  suite("_scanAnnotation()", function()
    local lexer, ann

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("_scanAnnotation() - @name - returning annotations", function()
      lexer:scan("@abstract")
      ann = lexer:next()

      assert(ann):isTable():has({line = 1, col = 1, type = TokenType.ANNOTATION, value = "abstract"})
      assert(lexer._.token):sameAs(ann)
      assert(lexer._.processed):isEmpty()
      assert(lexer._.advanced):isEmpty()
    end)
  end):tags("annotation")

  ----------------------
  -- _scanDirective() --
  ----------------------
  suite("_scanDirective()", function()
    local lexer, dir

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("_scanDirective() - #!if py then", function()
      lexer:scan("#!if py then")
      dir = lexer:next()

      assert(dir):isTable():has({line = 1, col = 1, type = TokenType.DIRECTIVE, value = "if py then"})
      assert(lexer._.token):sameAs(dir)
      assert(lexer._.processed):isEmpty()
      assert(lexer._.advanced):isEmpty()
    end)

    test("_scanDirective() - #!if not py then", function()
      lexer:scan("#!if not py then")
      dir = lexer:next()

      assert(dir):isTable():has({line = 1, col = 1, type = TokenType.DIRECTIVE, value = "if not py then"})
      assert(lexer._.token):sameAs(dir)
      assert(lexer._.processed):isEmpty()
      assert(lexer._.advanced):isEmpty()
    end)

    test("_scanDirective() - error - #!if 123 then", function()
      lexer:scan("#!if 123 then")
      assert(function() lexer:next() end):raises("on (1,1), invalid directive.")
    end)

    test("_scanDirective() - #!else", function()
      lexer:scan("#!else")
      dir = lexer:next()

      assert(dir):isTable():has({line = 1, col = 1, type = TokenType.DIRECTIVE, value = "else"})
      assert(lexer._.token):sameAs(dir)
      assert(lexer._.processed):isEmpty()
      assert(lexer._.advanced):isEmpty()
    end)

    test("_scanDirective() - #!end", function()
      lexer:scan("#!end")
      dir = lexer:next()

      assert(dir):isTable():has({line = 1, col = 1, type = TokenType.DIRECTIVE, value = "end"})
      assert(lexer._.token):sameAs(dir)
      assert(lexer._.processed):isEmpty()
      assert(lexer._.advanced):isEmpty()
    end)
  end):tags("directive")

  ---------------
  -- _scanId() --
  ---------------
  suite("_scanId()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
      lexer:scan("id1 _id2 Id3")
    end):title("Create lexer")

    test("_scanId() - once", function()
      local id = lexer:next()

      assert(id):isTable():has({line = 1, col = 1, type = TokenType.NAME, value = "id1"})
      assert(lexer._.token):sameAs(id)
      assert(lexer._.processed):isEmpty()
      assert(lexer._.advanced):isEmpty()
    end)

    test("_scanId() - twice", function()
      local id

      lexer:next()
      id = lexer:next()

      assert(id):isTable():has({line = 1, col = 5, type = TokenType.NAME, value = "_id2"})
      assert(lexer._.token):sameAs(id)
      assert(lexer._.processed._.items):eq({
        {line = 1, col = 1, type = TokenType.NAME, value = "id1"}
      })
      assert(lexer._.advanced):isEmpty()
    end)

    test("_scanId() - three times", function()
      local id

      lexer:next()
      lexer:next()
      id = lexer:next()

      assert(id):isTable():has({line = 1, col = 10, type = TokenType.NAME, value = "Id3"})
      assert(lexer._.token):sameAs(id)
      assert(lexer._.processed._.items):eq({
        {line = 1, col = 1, type = TokenType.NAME, value = "id1"},
        {line = 1, col = 5, type = TokenType.NAME, value = "_id2"}
      })
      assert(lexer._.advanced):isEmpty()
    end)

    -- test("_scanId() - four times", function()
    --   local id
    --
    --   lexer:next()
    --   lexer:next()
    --   lexer:next()
    --   id = lexer:next()
    --
    --   assert(id):has({
    --
    --   })
    --   assert(lexer._.token):isNil()
    --   assert(lexer._.processed._.items):eq({
    --     {line = 1, col = 1, type = TokenType.NAME, value = "id1"},
    --     {line = 1, col = 5, type = TokenType.NAME, value = "_id2"},
    --     {line = 1, col = 10, type = TokenType.NAME, value = "Id3"}
    --   })
    --   assert(lexer._.advanced):isEmpty()
    -- end)

    test("_scanId() - being keyword", function()
      lexer:scan("if x else y")

      assert(lexer:next()):isTable():has({type = TokenType.KEYWORD, line = 1, col = 1, value = "if"})
      assert(lexer:next()):isTable():has({type = TokenType.NAME, line = 1, col = 4, value = "x"})
      assert(lexer:next()):isTable():has({type = TokenType.KEYWORD, line = 1, col = 6, value = "else"})
      assert(lexer:next()):isTable():has({type = TokenType.NAME, line = 1, col = 11, value = "y"})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 12})
      assert(lexer:next()):isNil()
    end)
  end)

  -----------------
  -- _scanName() --
  -----------------
  suite("_scanName()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("'name'", function()
      lexer:scan("'my name'")
      assert(lexer:next()):has({
        type = TokenType.NAME,
        line = 1,
        col = 1,
        value = "my name"
      })
    end)
  end)

  -------------------
  -- _scanSymbol() --
  -------------------
  suite("_scanSymbol()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("symbol ", function(params)
      local sym

      lexer:scan(params[1] .. " ")
      sym = lexer:next()

      assert(sym):isTable():has({type = TokenType.SYMBOL, line = 1, col = 1, value = params[1]})
      assert(lexer._.token):sameAs(sym)
    end):iter(
      {subtitle = "$", params = "$"},
      {subtitle = "+", params = "+"},
      {subtitle = "+=", params = "+="},
      {subtitle = "-", params = "-"},
      {subtitle = "-=", params = "-="},
      {subtitle = "->", params = "->"},
      {subtitle = "*", params = "*"},
      {subtitle = "*=", params = "*="},
      {subtitle = "**", params = "**"},
      {subtitle = "**=", params = "**="},
      {subtitle = "^", params = "^"},
      {subtitle = "^=", params = "^="},
      {subtitle = "/", params = "/"},
      {subtitle = "/=", params = "/="},
      {subtitle = "%", params = "%"},
      {subtitle = "%=", params = "%="},
      {subtitle = "=", params = "="},
      {subtitle = "==", params = "=="},
      {subtitle = "===", params = "==="},
      {subtitle = "!", params = "!"},
      {subtitle = "!=", params = "!="},
      {subtitle = "!==", params = "!=="},
      {subtitle = "<", params = "<"},
      {subtitle = "<<", params = "<<"},
      {subtitle = "<<=", params = "<<="},
      {subtitle = "<=", params = "<="},
      {subtitle = ">", params = ">"},
      {subtitle = ">>", params = ">>"},
      {subtitle = ">>=", params = ">>="},
      {subtitle = ">=", params = ">="},
      {subtitle = "(", params = "("},
      {subtitle = ")", params = ")"},
      {subtitle = "[", params = "["},
      {subtitle = "]", params = "]"},
      {subtitle = "{", params = "{"},
      {subtitle = "}", params = "}"},
      {subtitle = ":", params = ":"},
      {subtitle = ".", params = "."},
      {subtitle = ".=", params = ".="},
      {subtitle = "?", params = "?"},
      {subtitle = "&", params = "&"},
      {subtitle = "&=", params = "&="},
      {subtitle = "&&", params = "&&"},
      {subtitle = "|", params = "|"},
      {subtitle = "|=", params = "|="},
      {subtitle = "||", params = "||"},
      {subtitle = "~", params = "~"},
      {subtitle = ",", params = ","}
    )

    test("Same symbol several times", function()
      local sym

      lexer:scan("++")
      sym = lexer:next()

      assert(sym):isTable():has({type = TokenType.SYMBOL, line = 1, col = 1, value = "+"})
      assert(lexer._.token):sameAs(sym)

      sym = lexer:next()
      assert(sym):isTable():has({type = TokenType.SYMBOL, line = 1, col = 2, value = "+"})
      assert(lexer._.token):sameAs(sym)
    end)

    test("Several symbols", function()
      local sym

      lexer:scan("+-")
      sym = lexer:next()

      assert(sym):isTable():has({type = TokenType.SYMBOL, line = 1, col = 1, value = "+"})
      assert(lexer._.token):sameAs(sym)

      sym = lexer:next()
      assert(sym):isTable():has({type = TokenType.SYMBOL, line = 1, col = 2, value = "-"})
      assert(lexer._.token):sameAs(sym)
    end)

    test("invalid symbol", function()
      lexer:scan("¿")
      assert(function() lexer:next() end):raises("invalid symbol on (1, 1).")
    end)

    test("invalid symbol after valid symbol", function()
      lexer:scan("+¿")
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 1, value = "+"})
      assert(function() lexer:next() end):raises("invalid symbol on (1, 2).")
    end)
  end)

  --------------------------
  -- _scanLiteralNumber() --
  --------------------------
  suite("_scanLiteralNumber()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("_scanLiteralNumber() - int", function()
      lexer:scan("1 234 567")

      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 1, value = 1234567})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 10})
      assert(lexer:next()):isNil()
    end)

    test("_scanLiteralNumber() - real", function()
      lexer:scan("123.456")

      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 1, value = 123.456})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 8})
      assert(lexer:next()):isNil()
    end)

    test("_scanLiteralNumber() - 123+456", function()
      lexer:scan("123+456")

      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 1, value = 123})
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 4, value = "+"})
      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 5, value = 456})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 8})
      assert(lexer:next()):isNil()
    end)

    test("_scanLiteralNumber() - 123.456 + 789", function()
      lexer:scan("123.456+789")

      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 1, value = 123.456})
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 8, value = "+"})

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.NUMBER,
        line = 1,
        col = 9,
        value = 789
      })

      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 12})
      assert(lexer:next()):isNil()
    end)

    test("_scanLiteralNumber() - 123 + 456", function()
      lexer:scan("123 + 456")

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.NUMBER,
        line = 1,
        col = 1,
        value = 123
      })

      assert(lexer:next()):isTable():has({
        type = TokenType.SYMBOL,
        line = 1,
        col = 5,
        value = "+"
      })

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.NUMBER,
        line = 1,
        col = 7,
        value = 456
      })

      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 10})
      assert(lexer:next()):isNil()
    end)

    test("_scanLiteralNumber() - 123.", function()
      lexer:scan("123.")

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.NUMBER,
        line = 1,
        col = 1,
        value = 123
      })

      assert(lexer:next()):isTable():has({
        type = TokenType.SYMBOL,
        line = 1,
        col = 4,
        value = "."
      })

      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 5})
      assert(lexer:next()):isNil()
    end)

    test("_scanLiteralNumber() - 123.toString()", function()
      lexer:scan("123.toString()")

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.NUMBER,
        line = 1,
        col = 1,
        value = 123
      })

      assert(lexer:next()):isTable():has({
        type = TokenType.SYMBOL,
        line = 1,
        col = 4,
        value = "."
      })

      assert(lexer:next()):isTable():has({
        type = TokenType.NAME,
        line = 1,
        col = 5,
        value = "toString"
      })

      assert(lexer:next()):has({
        type = TokenType.SYMBOL,
        line = 1,
        col = 13,
        value = "("
      })

      assert(lexer:next()):has({
        type = TokenType.SYMBOL,
        line = 1,
        col = 14,
        value = ")"
      })

      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 15})
      assert(lexer:next()):isNil()
    end)
  end)

  --------------------------
  -- _scanLiteralString() --
  --------------------------
  suite("_scanLiteralString()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("_scanLiteralString() - \"\"", function()
      lexer:scan('""')

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.STRING,
        line = 1,
        col = 1,
        value = ""
      })
    end)

    test("_scanLiteralString() - \"txt\"", function()
      lexer:scan('"text1" "text2"')

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.STRING,
        line = 1,
        col = 1,
        value = "text1"
      })

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.STRING,
        line = 1,
        col = 9,
        value = "text2"
      })
    end)

    test("_scanLiteralString() - \"txt1\\ntxt2\"", function()
      lexer:scan('"text1\ntext2"')

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.STRING,
        line = 1,
        col = 1,
        value = "text1\ntext2"
      })
    end)

    test("_scanLiteralString() - \"\"\"txt\"\"\"", function()
      lexer:scan('"""text"""')

      assert(lexer:next()):isTable():has({
        type = TokenType.LITERAL,
        subtype = LiteralType.STRING,
        line = 1,
        col = 1,
        value = "text"
      })
    end)

    test("_scanLiteralString() - error - literal string opened but not closed #1", function()
      lexer:scan('"text')
      assert(function() lexer:next() end):raises("literal string opened but not closed on (1, 1).")
    end)

    test("_scanLiteralString() - error - literal string opened but not closed #2", function()
      lexer:scan('"""text')
      assert(function() lexer:next() end):raises("literal string opened but not closed on (1, 1).")
    end)

    test("_scanLiteralString() - error - literal string opened but not closed #3", function()
      lexer:scan('"""text"')
      assert(function() lexer:next() end):raises("literal string opened but not closed on (1, 1).")
    end)

    test("_scanLiteralString() - error - literal string opened but not closed #4", function()
      lexer:scan('"""text""')
      assert(function() lexer:next() end):raises("literal string opened but not closed on (1, 1).")
    end)

    test("_scanLiteralString() - error - literal string opened but not closed #5", function()
      lexer:scan('"')
      assert(function() lexer:next() end):raises("literal string opened but not closed on (1, 1).")
    end)
  end)

  --------------------
  -- _scanComment() --
  --------------------
  suite("_scanComment()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new({comments = true})
    end):title("Create lexer")

    test("_scanComment() - unique line", function()
      lexer:scan("#this is the comment")

      assert(lexer:next()):isTable():has({type = TokenType.COMMENT, line = 1, col = 1, value = "this is the comment"})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 21})
      assert(lexer:next()):isNil()
    end)

    test("_scanComment() - several lines", function()
      lexer:scan("#this is the first line\n#and this is the second line")

      assert(lexer:next()):isTable():has({type = TokenType.COMMENT, line = 1, col = 1, value = "this is the first line\nand this is the second line"})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 2, col = 29})
      assert(lexer:next()):isNil()
    end)

    test("_scanComment() - at the end of line", function()
      lexer:scan("1+2#my comment")

      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 1, value = 1})
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 2, value = "+"})
      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 3, value = 2})
      assert(lexer:next()):isTable():has({type = TokenType.COMMENT, line = 1, col = 4, value = "my comment"})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 15})
      assert(lexer:next()):isNil()
    end)

    test("_scanComment() - preceding proposition", function()
      lexer:scan("#my comment\n1+2")

      assert(lexer:next()):isTable():has({type = TokenType.COMMENT, line = 1, col = 1, value = "my comment"})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 12})
      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 2, col = 1, value = 1})
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 2, col = 2, value = "+"})
      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 2, col = 3, value = 2})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 2, col = 4})
      assert(lexer:next()):isNil()
    end)

    test("_scanComment() - with comment == false", function()
      lexer:scan("1+2#my comment")

      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 1, value = 1})
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 2, value = "+"})
      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 3, value = 2})
      -- assert(lexer:next()):isTable():has({type = TokenType.COMMENT, line = 1, col = 4, value = "my comment"})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 15})
      assert(lexer:next()):isNil()
    end):init("Set comments to false", function()
      lexer._.comments = false
    end)
  end)

  ---------------
  -- advance() --
  ---------------
  suite("advance()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
      lexer:scan("x += 123")
    end):title("Create lexer")

    test("advance(1..3)", function()
      assert(lexer:advance(1)):isTable():has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(lexer:advance(2)):isTable():has({type = TokenType.SYMBOL, line = 1, col = 3, value = "+="})
      assert(lexer:advance(3)):isTable():has({type = TokenType.LITERAL, line = 1, col = 6, value = 123})
    end)

    test("advance() - as first call", function()
      assert(lexer:advance()):isTable():has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(lexer._.token):isNil()
      assert(lexer._.processed):isEmpty()
      assert(lexer._.advanced._.items):eq({
        {type = TokenType.NAME, line = 1, col = 1, value = "x"}
      })
      assert(lexer:next()):isTable():has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
    end)

    test("advance() - as second call", function()
      assert(lexer:next()):isTable():has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(lexer:advance()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 3, value = "+="})
      assert(lexer._.token):isTable():has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(lexer._.processed):isEmpty()
      assert(lexer._.advanced._.items):eq({
        {type = TokenType.SYMBOL, line = 1, col = 3, value = "+="}
      })
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 3, value = "+="})
    end)

    test("advance() - as end call", function()
      assert(lexer:next()):isTable():has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(lexer:next()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 3, value = "+="})
      assert(lexer:next()):isTable():has({type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 6, value = 123})
      assert(lexer:next()):isTable():has({type = TokenType.EOL, line = 1, col = 9})
      assert(lexer:advance()):isNil()
      assert(lexer._.processed._.items):eq({
        {type = TokenType.SYMBOL, line = 1, col = 3, value = "+="},
        {type = TokenType.LITERAL, subtype = LiteralType.NUMBER, line = 1, col = 6, value = 123}
      })
      assert(lexer._.advanced):isEmpty()
    end)

    test("advance() - with token already advanced", function()
      assert(lexer:next()):isTable():has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(lexer:advance()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 3, value = "+="})
      assert(lexer:advance()):isTable():has({type = TokenType.SYMBOL, line = 1, col = 3, value = "+="})
      assert(lexer._.token):isTable():has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(lexer._.processed):isEmpty()
      assert(lexer._.advanced._.items):eq({
        {type = TokenType.SYMBOL, line = 1, col = 3, value = "+="}
      })
    end)
  end)

  ------------
  -- next() --
  ------------
  suite("next()", function()
    local lexer

    init("*", function()
      lexer = Lexer.new()
    end):title("Create lexer")

    test("next(type, value) - ok", function()
      lexer:scan("x += 123")
      assert(lexer:next()):has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(lexer:next(TokenType.SYMBOL, "+=")):has({type = TokenType.SYMBOL, line = 1, col = 3, value = "+="})
      assert(lexer:next()):has({type = TokenType.LITERAL, line = 1, col = 6, value = 123})
    end)

    test("next(type, value) - error", function()
      lexer:scan("x += 123")
      assert(lexer:next()):has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(function() lexer:next(TokenType.SYMBOL, "+") end):raises("'%+' expected on (1, 3).")
    end)

    test("next(type, value) - error", function()
      lexer:scan("x +=")
      assert(lexer:next()):has({type = TokenType.NAME, line = 1, col = 1, value = "x"})
      assert(lexer:next()):has({type = TokenType.SYMBOL, line = 1, col = 3, value = "+="})
      assert(lexer:next()):has({type = TokenType.EOL, line = 1, col = 5})
      assert(function() lexer:next(TokenType.LITERAL, 123) end):raises("'123' expected at the end of code.")
    end)
  end)
end):tags("lexer")
