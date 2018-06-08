--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Reader = require("dogma.lex._.Reader")

--Suite.
return suite("dogma.lex._.Reader", function()
  -----------------
  -- constructor --
  -----------------
  test("constructor(txt)", function()
    local reader = Reader.new("the text")

    assert(reader._):has({
      text = {"the text"},
      line = 1,
      col = 1,
      char = nil
    })

    assert(reader._.processed):isEmpty()
    assert(reader._.advanced):isEmpty()
  end)

  -----------------------
  -- next() - one line --
  -----------------------
  suite("next() - one line", function()
    local reader

    init("*", function()
      reader = Reader.new("something")
    end):title("Create reader")

    test("next() - has char to shift", function()
      reader:next()
      reader:unshift()

      assert(reader:next()):isTable():has({line = 1, col = 1, char = "s"})
      assert(reader:next()):isTable():has({line = 1, col = 2, char = "o"})
    end)

    test("next() - once", function()
      local ch = reader:next()

      assert(ch):isTable():has({
        line = 1,
        col = 1,
        char = "s"
      })

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 2,
        char = {
          line = 1,
          col = 1,
          char = "s"
        }
      })

      assert(reader._.processed):isEmpty()
      assert(reader._.advanced):isEmpty()
    end)

    test("next() - twice", function()
      local ch

      reader:next()
      ch = reader:next()

      assert(ch):isTable():has({
        line = 1,
        col = 2,
        char = "o"
      })

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 3,
        char = {
          line = 1,
          col = 2,
          char = "o"
        }
      })

      assert(reader._.processed._.items):eq({
        {line = 1, col = 1, char = "s"}
      })

      assert(reader._.advanced):isEmpty()
    end)

    test("next() - three times", function()
      local ch

      reader:next()
      reader:next()
      ch = reader:next()

      assert(ch):isTable():has({
        line = 1,
        col = 3,
        char = "m"
      })

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 4,
        char = {
          line = 1,
          col = 3,
          char = "m"
        }
      })

      assert(reader._.processed._.items):eq({
        {line = 1, col = 1, char = "s"},
        {line = 1, col = 2, char = "o"}
      })

      assert(reader._.advanced):isEmpty()
    end)

    test("next() - four times", function()
      local ch

      reader:next()
      reader:next()
      reader:next()
      ch = reader:next()

      assert(ch):isTable():has({
        line = 1,
        col = 4,
        char = "e"
      })

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 5,
        char = {
          line = 1,
          col = 4,
          char = "e"
        }
      })

      assert(reader._.processed._.items):eq({
        {line = 1, col = 1, char = "s"},
        {line = 1, col = 2, char = "o"},
        {line = 1, col = 3, char = "m"}
      })

      assert(reader._.advanced):isEmpty()
    end)

    test("next() - five times", function()
      local ch

      reader:next()
      reader:next()
      reader:next()
      reader:next()
      ch = reader:next()

      assert(ch):isTable():has({
        line = 1,
        col = 5,
        char = "t"
      })

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 6,
        char = {
          line = 1,
          col = 5,
          char = "t"
        }
      })

      assert(reader._.processed._.items):eq({
        {line = 1, col = 2, char = "o"},
        {line = 1, col = 3, char = "m"},
        {line = 1, col = 4, char = "e"},
      })

      assert(reader._.advanced):isEmpty()
    end)
  end)

  ----------------------------
  -- next() - several lines --
  ----------------------------
  suite("next() - several lines", function()
    test("next() - ending without end of line", function()
      local reader = Reader.new("something\nmore")

      assert(reader._.text):eq({
        "something",
        "more"
      })

      assert(reader:next()):isTable():has({line = 1, col = 1, char = "s"})
      assert(reader:next()):isTable():has({line = 1, col = 2, char = "o"})
      assert(reader:next()):isTable():has({line = 1, col = 3, char = "m"})
      assert(reader:next()):isTable():has({line = 1, col = 4, char = "e"})
      assert(reader:next()):isTable():has({line = 1, col = 5, char = "t"})
      assert(reader:next()):isTable():has({line = 1, col = 6, char = "h"})
      assert(reader:next()):isTable():has({line = 1, col = 7, char = "i"})
      assert(reader:next()):isTable():has({line = 1, col = 8, char = "n"})
      assert(reader:next()):isTable():has({line = 1, col = 9, char = "g"})
      assert(reader:next()):isTable():has({line = 1, col = 10, char = "\n"})
      assert(reader:next()):isTable():has({line = 2, col = 1, char = "m"})
      assert(reader:next()):isTable():has({line = 2, col = 2, char = "o"})
      assert(reader:next()):isTable():has({line = 2, col = 3, char = "r"})
      assert(reader:next()):isTable():has({line = 2, col = 4, char = "e"})
      assert(reader:next()):isTable():has({line = 2, col = 5, char = "\n"})
      assert(reader:next()):isNil()
    end)

    test("next() - ending with end of line", function()
      local reader = Reader.new("something\nmore\n")

      assert(reader._.text):eq({
        "something",
        "more",
        ""
      })

      assert(reader:next()):isTable():has({line = 1, col = 1, char = "s"})
      assert(reader:next()):isTable():has({line = 1, col = 2, char = "o"})
      assert(reader:next()):isTable():has({line = 1, col = 3, char = "m"})
      assert(reader:next()):isTable():has({line = 1, col = 4, char = "e"})
      assert(reader:next()):isTable():has({line = 1, col = 5, char = "t"})
      assert(reader:next()):isTable():has({line = 1, col = 6, char = "h"})
      assert(reader:next()):isTable():has({line = 1, col = 7, char = "i"})
      assert(reader:next()):isTable():has({line = 1, col = 8, char = "n"})
      assert(reader:next()):isTable():has({line = 1, col = 9, char = "g"})
      assert(reader:next()):isTable():has({line = 1, col = 10, char = "\n"})
      assert(reader:next()):isTable():has({line = 2, col = 1, char = "m"})
      assert(reader:next()):isTable():has({line = 2, col = 2, char = "o"})
      assert(reader:next()):isTable():has({line = 2, col = 3, char = "r"})
      assert(reader:next()):isTable():has({line = 2, col = 4, char = "e"})
      assert(reader:next()):isTable():has({line = 2, col = 5, char = "\n"})
      assert(reader:next()):isTable():has({line = 3, col = 1, char = "\n"})
      assert(reader:next()):isNil()
    end)
  end)

  ---------------
  -- unshift() --
  ---------------
  suite("unshift()", function()
    local reader

    init("*", function()
      reader = Reader.new("something")
    end):title("Create reader")

    test("unshift() - ok - once - with no processed char", function()
      reader:next()
      reader:unshift()

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 2,
        char = nil
      })

      assert(reader._.processed):isEmpty()
      assert(reader._.advanced._.items):eq({
        {line = 1, col = 1, char = "s"}
      })
    end)

    test("unshift() - ok - twice with no processed char", function()
      reader:next()
      reader:unshift()
      reader:unshift()

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 2,
        char = nil
      })

      assert(reader._.processed):isEmpty()
      assert(reader._.advanced._.items):eq({
        {line = 1, col = 1, char = "s"}
      })
    end)

    test("unshift() - ok - once - with one previous char", function()
      reader:next() --s
      reader:next() --o
      reader:unshift()  --recover s, advanced o

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 3,
        char = {
          line = 1,
          col = 1,
          char = "s"
        }
      })

      assert(reader._.processed):isEmpty()
      assert(reader._.advanced._.items):eq({
        {line = 1, col = 2, char = "o"}
      })
    end)

    test("unshift() - ok - once - with two previous chars", function()
      reader:next() --s
      reader:next() --o
      reader:next() --m
      reader:unshift()  --recover o, advanced m

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 4,
        char = {
          line = 1,
          col = 2,
          char = "o"
        }
      })

      assert(reader._.processed._.items):eq({
        {line = 1, col = 1, char = "s"}
      })
      assert(reader._.advanced._.items):eq({
        {line = 1, col = 3, char = "m"}
      })
    end)

    test("unshift() - ok - twice - with two previous chars", function()
      reader:next() --s
      reader:next() --o
      reader:next() --m
      reader:unshift()  --recover o, advanced m
      reader:unshift()  --recover s, advanced o

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 4,
        char = {
          line = 1,
          col = 1,
          char = "s"
        }
      })

      assert(reader._.processed._.items):isEmpty()
      assert(reader._.advanced._.items):eq({
        {line = 1, col = 2, char = "o"},
        {line = 1, col = 3, char = "m"}
      })
    end)
  end)

  --------------
  -- _shift() --
  --------------
  suite("_shift()", function()
    local reader

    init("*", function()
      reader = Reader.new("something")
    end):title("Create reader")

    test("_shift()", function()
      assert(function() reader:_shift() end):raises("no advanced char to shift.")
    end)

    test("_shift() - once", function()
      reader:next()
      reader:next()
      reader:unshift()
      reader:unshift()

      reader:_shift()

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 3,
        char = {
          line = 1,
          col = 1,
          char = "s"
        }
      })

      assert(reader._.processed._.items):isEmpty()
      assert(reader._.advanced._.items):eq({
        {line = 1, col = 2, char = "o"}
      })
    end)

    test("_shift() - twice", function()
      reader:next()
      reader:next()
      reader:unshift()
      reader:unshift()

      reader:_shift()
      reader:_shift()

      assert(reader._):has({
        text = {"something"},
        line = 1,
        col = 3,
        char = {
          line = 1,
          col = 2,
          char = "o"
        }
      })

      assert(reader._.processed._.items):eq({
        {line = 1, col = 1, char = "s"}
      })
      assert(reader._.advanced._.items):isEmpty()
    end)
  end)
end):tags("lexer")
