--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Parser = require("dogma.syn.Parser")
local SentType = require("dogma.syn.SentType")
local StmtType = require("dogma.syn.StmtType")

--Suite.
return suite("dogma.syn.StmtParser", function()
  local parser, stmt

  ----------
  -- init --
  ----------
  init("*", function()
    parser = Parser.new()
  end):title("Create parser")

  -----------------
  -- nextBreak() --
  -----------------
  suite("nextBreak()", function()
    test("break", function()
      parser:parse("break")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.BREAK})
    end)

    test("break x - error", function()
      parser:parse("break x")
      assert(function() parser:next() end):raises("end of line expected on (1, 7).")
    end)
  end)

  ----------------
  -- nextNext() --
  ----------------
  suite("nextNext()", function()
    test("next", function()
      parser:parse("next")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.NEXT})
    end)

    test("next x - error", function()
      parser:parse("next x")
      assert(function() parser:next() end):raises("end of line expected on (1, 6).")
    end)
  end)

  ------------------
  -- nextReturn() --
  ------------------
  suite("nextReturn()", function()
    test("return", function()
      parser:parse("return")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.RETURN})
      assert(stmt):len(0)
    end)

    test("return x+y", function()
      parser:parse("return x+y")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.RETURN})
      assert(stmt):len(1)
      assert(stmt.values[1]:__tostring()):eq("(+ x y)")
    end)
  end)

  -----------------
  -- nextYield() --
  -----------------
  suite("nextYield()", function()
    test("yield x+y", function()
      parser:parse("yield x+y")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.YIELD})
      assert(tostring(stmt.value)):eq("(+ x y)")
    end)
  end):tags("yield")

  ---------------
  -- nextUse() --
  ---------------
  suite("nextUse()", function()
    test("use LiteralStr", function()
      parser:parse('use "module"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "module", path = "module"}
      })
    end)

    test("use\\n LiteralStr", function()
      parser:parse('use\n "module"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "module", path = "module"}
      })
    end)

    test("use\\nLiteralStr", function()
      parser:parse('use\n"module"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({})
    end)

    test('use "justo.assert"', function()
      parser:parse('use "justo.assert"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "assert", path = "justo.assert"}
      })
    end)

    test('use "redispark-connector-redis"', function()
      parser:parse('use "redispark-connector-redis"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "redis", path = "redispark-connector-redis"}
      })
    end)

    test("use LitealStr, LiteralStr", function()
      parser:parse('use "module1", "module2"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "module1", path = "module1"},
        {name = "module2", path = "module2"}
      })
    end)

    test("use\\n  LiteralStr\\n  LiteralStr", function()
      parser:parse('use\n "module1"\n "module2"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "module1", path = "module1"},
        {name = "module2", path = "module2"}
      })
    end)

    test("use LiteralStr as Name", function()
      parser:parse('use "module" as mod')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "mod", path = "module"}
      })
    end)

    test("use\\n LiteralStr as Name", function()
      parser:parse('use\n "module" as mod')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "mod", path = "module"}
      })
    end)

    test("use LiteralStr as Name, LiteralStr as Name", function()
      parser:parse('use "module1" as mod1, "module2" as mod2')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "mod1", path = "module1"},
        {name = "mod2", path = "module2"}
      })
    end)

    test("use\\n LiteralStr as Name\\n LiteralStr as Name", function()
      parser:parse('use\n "module1" as mod1\n "module2" as mod2')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "mod1", path = "module1"},
        {name = "mod2", path = "module2"}
      })
    end)

    test([[use "module1"! "module2" - error - comma expected]], function()
      parser:parse([[use "module1"! "module2"]])
      assert(function() parser:next() end):raises("comma expected on (1, 14) for separating modules.")
    end)

    test([[use "~module" - error - invalid module path format]], function()
      parser:parse([[use "~module"]])
      assert(function() parser:next() end):raises("invalid module path format: '~module'.")
    end)

    test([[use "one/two"]], function()
      parser:parse([[use "one/two"]])
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "two", path = "one/two"}
      })
    end)

    test("use Literal, Name", function()
      parser:parse('use "one", two')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {name = "one", path = "one"},
        {name = "two", path = "./two"}
      })
    end)

    test("use Number - error", function()
      parser:parse("use 123")
      assert(function() parser:next() end):raises("on (1,5), literal string or name expected.")
    end)
  end):tags("use")

  ----------------
  -- nextFrom() --
  ----------------
  suite("nextFrom()", function()
    test("from LiteralStr use Name", function()
      parser:parse([[from "fs" use FSWatcher]])
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.FROM,
        line = 1,
        col = 1,
        module = "fs",
        members = {
          {name = "FSWatcher", as = "FSWatcher"}
        }
      })
    end)

    test("from LiteralStr use Name as Name", function()
      parser:parse([[from "fs" use FSWatcher as Watcher]])
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.FROM,
        line = 1,
        col = 1,
        module = "fs",
        members = {
          {name = "FSWatcher", as = "Watcher"}
        }
      })
    end)

    test("from LiteralStr use Name, Name", function()
      parser:parse([[from "fs" use FSWatcher, watch]])
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.FROM,
        line = 1,
        col = 1,
        module = "fs",
        members = {
          {name = "FSWatcher", as = "FSWatcher"},
          {name = "watch", as = "watch"}
        }
      })
    end)

    test("from LiteralStr use Name as Name, Name as Name", function()
      parser:parse([[from "fs" use FSWatcher as Watcher, watch as wtch]])
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.FROM,
        line = 1,
        col = 1,
        module = "fs",
        members = {
          {name = "FSWatcher", as = "Watcher"},
          {name = "watch", as = "wtch"}
        }
      })
    end)
  end):tags("from")

  ----------------
  -- nextEnum() --
  ----------------
  suite("nextEnum()", function()
    test("enum - error", function()
      parser:parse("enum")
      assert(function() parser:next() end):raises("name expected on (1, 5).")
    end)

    test("visibility enum Color", function(params)
      parser:parse(params[1] .. " enum Color")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        visib = params[1],
        name = "Color",
        items = {}
      })
    end):iter(
      {subtitle = " # export", params = "export"},
      {subtitle = " # pub", params = "pub"}
    )

    test("enum Color", function()
      parser:parse("enum Color")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        visib = nil,
        name = "Color",
        items = {}
      })
    end)

    test("enum Color RED - error", function()
      parser:parse("enum Color RED")
      assert(function() parser:next() end):raises("invalid token on (1, 12).")
    end)

    test("visibility enum Color", function(params)
      parser:parse(params[1] .. " enum Color")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        visib = params[1],
        name = "Color",
        items = {}
      })
    end):iter(
      {subtitle = "# export", params = "export"},
      {subtitle = "# pub", params = "pub"}
    )

    test("pub enum Color", function()
      parser:parse("pub enum Color")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        visib = "pub",
        name = "Color",
        items = {}
      })
    end)

    test("enum Color {RED}", function()
      parser:parse("enum Color {RED}")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {{name = "RED", value = 1}}
      })
    end)

    test("enum Color {RED, GREEN}", function()
      parser:parse("enum Color {RED, GREEN}")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {{name = "RED", value = 1}, {name = "GREEN", value = 2}}
      })
    end)

    test("enum Color {RED, GREEN, BLUE}", function()
      parser:parse("enum Color {RED, GREEN, BLUE}")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {
          {name = "RED", value = 1},
          {name = "GREEN", value = 2},
          {name = "BLUE", value = 3}
        }
      })
    end)

    test("enum Color {RED = 12}", function()
      parser:parse("enum Color {RED = 12}")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {{name = "RED", value = 12}}
      })
    end)

    test("enum Color {RED = 12, GREEN = 34}", function()
      parser:parse("enum Color {RED = 12, GREEN = 34}")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {{name = "RED", value = 12}, {name = "GREEN", value = 34}}
      })
    end)

    test("enum Color {RED = 12, GREEN = 34, BLUE = 56}", function()
      parser:parse("enum Color {RED = 12, GREEN = 34, BLUE = 56}")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {
          {name = "RED", value = 12},
          {name = "GREEN", value = 34},
          {name = "BLUE", value = 56}
        }
      })
    end)

    test("enum Color {RED,", function()
      parser:parse("enum Color {RED,")
      assert(function()parser:next() end):raises("name expected on (1, 17).")
    end)

    test("enum Color\\n  RED", function()
      parser:parse("enum Color\n  RED")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {{name = "RED", value = 1}}
      })
    end)

    test("enum Color\\nRED", function()
      parser:parse("enum Color\nRED")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {}
      })
    end)

    test("enum Color\\n  RED\\n  GREEN", function()
      parser:parse("enum Color\n  RED\n  GREEN")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {{name = "RED", value = 1}, {name = "GREEN", value = 2}}
      })
    end)

    test("enum Color\\n  RED\\nGREEN", function()
      parser:parse("enum Color\n  RED\nGREEN")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {{name = "RED", value = 1}}
      })
    end)

    test("enum Color\\n  RED\\n  GREEN\\n  BLUE", function()
      parser:parse("enum Color\n  RED\n  GREEN\n  BLUE")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {
          {name = "RED", value = 1},
          {name = "GREEN", value = 2},
          {name = "BLUE", value = 3}
        }
      })
    end)

    test("enum Color\\n  RED = 12", function()
      parser:parse("enum Color\n  RED = 12")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {{name = "RED", value = 12}}
      })
    end)

    test("enum Color\\n  RED = 12\\n  GREEN = 34", function()
      parser:parse("enum Color\n  RED = 12\n  GREEN = 34")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {{name = "RED", value = 12}, {name = "GREEN", value = 34}}
      })
    end)

    test("enum Color\\n  RED = 12\\n  GREEN = 34\\n  BLUE = 56", function()
      parser:parse("enum Color\n  RED = 12\n  GREEN = 34\n  BLUE = 56")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {},
        name = "Color",
        items = {
          {name = "RED", value = 12},
          {name = "GREEN", value = 34},
          {name = "BLUE", value = 56}
        }
      })
    end)

    test("@annot1 @annot2\\nenum Color\\n  RED = 12\\n  GREEN = 34\\n  BLUE = 56", function()
      parser:parse("@annot1 @annot2\nenum Color\n  RED = 12\n  GREEN = 34\n  BLUE = 56")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {"annot1", "annot2"},
        name = "Color",
        items = {
          {name = "RED", value = 12},
          {name = "GREEN", value = 34},
          {name = "BLUE", value = 56}
        }
      })
    end)

    test("@annot1\\n@annot2\\nenum Color\\n  RED = 12\\n  GREEN = 34\\n  BLUE = 56", function()
      parser:parse("@annot1\n@annot2\nenum Color\n  RED = 12\n  GREEN = 34\n  BLUE = 56")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.ENUM,
        annots = {"annot1", "annot2"},
        name = "Color",
        items = {
          {name = "RED", value = 12},
          {name = "GREEN", value = 34},
          {name = "BLUE", value = 56}
        }
      })
    end)
  end):tags("enum")

  -----------------
  -- nextWhile() --
  -----------------
  suite("nextWhile()", function()
    test("while Exp do Exp", function()
      parser:parse("while true do print(x)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isNil()
      assert(stmt.finally):isNil()

      assert(parser:next()):isNil()
    end)

    test("while Exp; Exp do Exp", function()
      parser:parse("while x < 100; x += 1 do print(x)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("(< x 100)")
      assert(stmt.iter:__tostring()):eq("(+= x 1)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isNil()
      assert(stmt.finally):isNil()

      assert(parser:next()):isNil()
    end)

    test("while Exp do", function()
      parser:parse("while true do")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):isEmpty()
      assert(stmt.catch):isNil()
      assert(stmt.finally):isNil()

      assert(parser:next()):isNil()
    end)

    test("while Exp do\\n Sentence", function()
      parser:parse("while true do\n print(x)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isNil()
      assert(stmt.finally):isNil()

      assert(parser:next()):isNil()
    end)

    test("while Exp; Exp do\\n Sentence", function()
      parser:parse("while x < 100; x += 1 do\n print(x)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("(< x 100)")
      assert(stmt.iter:__tostring()):eq("(+= x 1)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isNil()
      assert(stmt.finally):isNil()

      assert(parser:next()):isNil()
    end)

    test("while Exp do\\n Sentence\\n Sentence", function()
      parser:parse("while true do\n print(x)\n print(y)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):len(2)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.body[2]:__tostring()):eq("(call print y)")
      assert(stmt.catch):isNil()
      assert(stmt.finally):isNil()

      assert(parser:next()):isNil()
    end)

    test("while Exp do\\n Sentence\\nSentence", function()
      parser:parse("while true do\n print(x)\nprint(y)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isNil()
      assert(stmt.finally):isNil()

      assert(parser:next():__tostring()):eq("(call print y)")
      assert(parser:next()):isNil()
    end)

    test("while Exp do\\n Sentence\\ncatch\\n  Sentence", function()
      parser:parse("while true do\n print(x)\ncatch\n  print(e)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isTable()
      assert(stmt.catch.var):isNil()
      assert(stmt.catch.body):len(1)
      assert(stmt.catch.body[1]:__tostring()):eq("(call print e)")
      assert(stmt.finally):isNil()

      assert(parser:next()):isNil()
    end)

    test("while Exp do\\n print(x)\\ncatch\\nprint(e)", function()
      parser:parse("while true do\n print(x)\ncatch\nprint(e)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isTable()
      assert(stmt.catch.var):isNil()
      assert(stmt.catch.body):len(0)
      assert(stmt.finally):isNil()

      assert(parser:next():__tostring()):eq("(call print e)")
      assert(parser:next()):isNil()
    end)

    test("while Exp do\\n print(x)\\ncatch e\\n  print(e)", function()
      parser:parse("while true do\n  print(x)\ncatch e\n  print(e)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isTable()
      assert(stmt.catch.var):eq("e")
      assert(stmt.catch.body):len(1)
      assert(stmt.catch.body[1]:__tostring()):eq("(call print e)")
      assert(stmt.finally):isNil()

      assert(parser:next()):isNil()
    end)

    test("while Exp do\\n print(x)\\nfinally\\n  print(y)", function()
      parser:parse("while true do\n print(x)\nfinally\n print(y)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isNil()
      assert(stmt.finally):isTable()
      assert(stmt.finally.body):len(1)
      assert(stmt.finally.body[1]:__tostring()):eq("(call print y)")

      assert(parser:next()):isNil()
    end)

    test("while Exp do\\n print(x)\\ncatch e\\n print(y)\\nfinally\\n print(z)", function()
      parser:parse("while true do\n print(x)\ncatch e\n print(y)\nfinally\n print(z)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.WHILE
      })
      assert(stmt.cond:__tostring()):eq("true")
      assert(stmt.iter):isNil()
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isTable()
      assert(stmt.catch.var):eq("e")
      assert(stmt.catch.body):len(1)
      assert(stmt.catch.body[1]:__tostring()):eq("(call print y)")
      assert(stmt.finally):isTable()
      assert(stmt.finally.body):len(1)
      assert(stmt.finally.body[1]:__tostring()):eq("(call print z)")

      assert(parser:next()):isNil()
    end)
  end):tags("while")

  --------------
  -- nextDo() --
  --------------
  suite("nextDo()", function()
    test("do\\n Sentence", function()
      parser:parse("do\n print(x)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.DO,
        cond = nil,
        catch = nil,
        finally = nil
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
    end)

    test("do\\n Sentence\\ncatch\\n Sentence", function()
      parser:parse("do\n print(x)\ncatch\n x += 1")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.DO,
        cond = nil,
        finally = nil
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isTable():has({
        var = nil
      })
      assert(stmt.catch.body):len(1)
      assert(stmt.catch.body[1]:__tostring()):eq("(+= x 1)")
    end)

    test("do\\n Sentence\\nfinally\\n Sentence", function()
      parser:parse("do\n print(x)\nfinally\n x += 1")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.DO,
        cond = nil,
        catch = nil
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.finally):isTable()
      assert(stmt.finally.body):len(1)
      assert(stmt.finally.body[1]:__tostring()):eq("(+= x 1)")
    end)

    test("do\\n Sentence\\ncatch\\n Sentence\\nfinally\\n Sentence", function()
      parser:parse("do\n print(x)\ncatch\n a += 1\nfinally\n b += 1")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.DO,
        cond = nil,
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.catch):isTable():has({
        var = nil
      })
      assert(stmt.catch.body):len(1)
      assert(stmt.catch.body[1]:__tostring()):eq("(+= a 1)")
      assert(stmt.finally):isTable()
      assert(stmt.finally.body):len(1)
      assert(stmt.finally.body[1]:__tostring()):eq("(+= b 1)")
    end)

    test("do\\n Sentence\\nwhile Exp", function()
      parser:parse("do\n print(x)\nwhile x == 1")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.DO,
        catch = nil,
        finally = nil
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.cond:__tostring()):eq("(== x 1)")
    end)

    test("do\\n Sentence\\nwhile Exp\\ncatch\\n Sentence\\nfinally\\n Sentence", function()
      parser:parse("do\n print(x)\nwhile x == 123\ncatch\n a += 1\nfinally\n b += 1")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.DO,
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print x)")
      assert(stmt.cond:__tostring()):eq("(== x 123)")
      assert(stmt.catch):isTable():has({
        var = nil
      })
      assert(stmt.catch.body):len(1)
      assert(stmt.catch.body[1]:__tostring()):eq("(+= a 1)")
      assert(stmt.finally):isTable()
      assert(stmt.finally.body):len(1)
      assert(stmt.finally.body[1]:__tostring()):eq("(+= b 1)")
    end)
  end)

  ---------------
  -- nextFor() --
  ---------------
  suite("nextFor()", function()
    test("for Name ; Exp do Exp", function()
      parser:parse("for i; i < 10 do print(i)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR,
        def = {
          {name = "i", value = nil}
        },
        iter = nil,
        catch = nil,
        finally = nil
      })
      assert(tostring(stmt.cond)):eq("(< i 10)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i)")
    end)

    test("for Name = Exp ; Exp do Exp", function()
      parser:parse("for i = 0; i < 10 do print(i)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR,
        iter = nil,
        catch = nil,
        finally = nil
      })
      assert(stmt.def):len(1)
      assert(stmt.def[1].name):eq("i")
      assert(tostring(stmt.def[1].value)):eq("0")
      assert(tostring(stmt.cond)):eq("(< i 10)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i)")
    end)

    test("for Name, Name ; Exp do Exp", function()
      parser:parse("for i, j; i < 10 do print(i)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR,
        def = {
          {name = "i", value = nil},
          {name = "j", value = nil}
        },
        iter = nil,
        catch = nil,
        finally = nil
      })
      assert(tostring(stmt.cond)):eq("(< i 10)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i)")
    end)

    test("for Name = Exp, Name = Exp ; Exp do Exp", function()
      parser:parse("for i = 0, j = 1; i < 10 do print(i)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR,
        iter = nil,
        catch = nil,
        finally = nil
      })
      assert(stmt.def):len(2)
      assert(stmt.def[1].name):eq("i")
      assert(tostring(stmt.def[1].value)):eq("0")
      assert(stmt.def[2].name):eq("j")
      assert(tostring(stmt.def[2].value)):eq("1")
      assert(tostring(stmt.cond)):eq("(< i 10)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i)")
    end)

    test("for Variable; Exp; Exp do Exp", function()
      parser:parse("for i = 0; i < 10; i += 1 do print(i)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR,
        catch = nil,
        finally = nil
      })
      assert(stmt.def):len(1)
      assert(stmt.def[1].name):eq("i")
      assert(tostring(stmt.def[1].value)):eq("0")
      assert(tostring(stmt.cond)):eq("(< i 10)")
      assert(tostring(stmt.iter)):eq("(+= i 1)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i)")
    end)
  end):tags("for")

  -------------------
  -- nextForEach() --
  -------------------
  suite("nextForEach()", function()
    test("for each Name in Exp do Sentence", function()
      parser:parse("for each i in list do print(i)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR_EACH,
        key = nil,
        value = "i",
        catch = nil,
        finally = nil
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i)")
    end)

    test("for each Name, Name in Exp do Sentence", function()
      parser:parse("for each i, j in list do print(i, j)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR_EACH,
        key = "i",
        value = "j",
        catch = nil,
        finally = nil
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i j)")
    end)

    test("for each Name in Exp do\\n Sentence", function()
      parser:parse("for each i in list do\n print(i)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR_EACH,
        key = nil,
        value = "i",
        catch = nil,
        finally = nil
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i)")
    end)

    test("for each Name, Name in Exp do\\n Sentence", function()
      parser:parse("for each i, j in list do\n print(i, j)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR_EACH,
        key = "i",
        value = "j",
        catch = nil,
        finally = nil
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i j)")
    end)

    test("for each Name in Exp do\\n Sentence\\ncatch\\n Sentece\\nfinally\\n Sentence", function()
      parser:parse("for each i in list do\n print(i)\ncatch\n print(c)\nfinally\n print(f)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        type = SentType.STMT,
        subtype = StmtType.FOR_EACH,
        key = nil,
        value = "i",
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(call print i)")
      assert(stmt.catch):isTable():has({
        var = nil
      })
      assert(stmt.catch.body):len(1)
      assert(stmt.catch.body[1]:__tostring()):eq("(call print c)")
      assert(stmt.finally.body):len(1)
      assert(stmt.finally.body[1]:__tostring()):eq("(call print f)")
    end)
  end):tags("foreach")

  --------------
  -- nextFn() --
  --------------
  suite("nextFn()", function()
    suite("parameters", function()
      test("fn Name ( Name )", function()
        parser:parse("fn inc(x)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          params = {
            {
              const = false,
              modifier = nil,
              name = "x",
              optional = false,
              type = nil,
              value = nil
            }
          }
        })
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( const Name )", function()
        parser:parse("fn inc(const x)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          params = {
            {
              const = true,
              modifier = nil,
              name = "x",
              optional = false,
              type = nil,
              value = nil
            }
          }
        })
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name ? )", function()
        parser:parse("fn inc(x?)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          params = {
            {
              const = false,
              modifier = nil,
              name = "x",
              optional = true,
              type = nil,
              value = nil
            }
          }
        })
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name : Name )", function()
        parser:parse("fn inc(x:num)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          params = {
            {
              const = false,
              modifier = nil,
              name = "x",
              optional = false,
              type = "num",
              value = nil
            }
          }
        })
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name ?: Name )", function()
        parser:parse("fn inc(x?:num)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          params = {
            {
              const = false,
              modifier = nil,
              name = "x",
              optional = true,
              type = "num",
              value = nil
            }
          }
        })
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name ? : Name )", function()
        parser:parse("fn inc(x? :num)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          rtype = nil,
          rvar = nil,
          accessor = nil,
          params = {
            {
              const = false,
              modifier = nil,
              name = "x",
              optional = true,
              type = "num",
              value = nil
            }
          }
        })
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( . Name )", function()
        parser:parse("fn inc(.x)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          params = {
            {
              const = false,
              modifier = ".",
              name = "x",
              optional = false,
              type = nil,
              value = nil
            }
          }
        })
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( : Name )", function()
        parser:parse("fn inc(:x)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          params = {
            {
              const = false,
              modifier = ":",
              name = "x",
              optional = false,
              type = nil,
              value = nil
            }
          }
        })
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( ... Name )", function()
        parser:parse("fn inc(...x)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          rtype = nil,
          rvar = nil,
          accessor = nil,
          params = {
            {
              const = false,
              modifier = "...",
              name = "x",
              optional = false,
              type = nil,
              value = nil
            }
          }
        })
        assert(stmt.body):isEmpty()
      end)

      test("fn Name(Name : {})", function()
        parser:parse("fn myfn(p:{})")
        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "myfn",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          body = {}
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "p",
          optional = false,
          type = {}
        })
      end)

      test("fn Name(Name : {Name})", function()
        parser:parse("fn myfn(p:{x})")
        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "myfn",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          body = {}
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "p",
          optional = false,
          type = {
            {name = "x", type = "any", mandatory = true}
          }
        })
      end)

      test("fn Name(Name : {Name : Name})", function()
        parser:parse("fn myfn(p:{x:num})")
        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "myfn",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          body = {}
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "p",
          optional = false,
          type = {
            {name = "x", type = "num", mandatory = true}
          }
        })
      end)

      test("fn Name(Name : {Name ? : Name})", function()
        parser:parse("fn myfn(p:{x?:num})")
        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "myfn",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          body = {}
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "p",
          optional = false,
          type = {
            {name = "x", type = "num", mandatory = false}
          }
        })
      end)

      test("fn Name(Name : {Name, Name?:Name})", function()
        parser:parse("fn myfn(p:{x, y?:text})")
        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "myfn",
          accessor = nil,
          rtype = nil,
          rvar = nil,
          body = {}
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "p",
          optional = false,
          type = {
            {name = "x", type = "any", mandatory = true},
            {name = "y", type = "text", mandatory = false}
          }
        })
      end)

      test("fn Name ( Name ? = Exp ) = Exp - error", function()
        parser:parse("fn inc(x ? = 123) = x + 1")
        assert(function() parser:next() end):raises("')' expected on (1, 12).")
      end)

      test("fn Name ( Name = Exp ) = Exp", function()
        parser:parse("fn inc(x = 123) = x + 1")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "x",
          optional = true,
          type = nil,
        })
        assert(stmt.params[1].value:__tostring()):eq("123")
        assert(stmt.body):len(1)
        assert(stmt.body[1]:__tostring()):eq("return (+ x 1)")
      end)

      test("fn Name ( Name : Name = Exp ) = Exp", function()
        parser:parse("fn inc(x : num = 123) = x + 1")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "x",
          optional = true,
          type = "num",
        })
        assert(stmt.params[1].value:__tostring()):eq("123")
        assert(stmt.body):len(1)
        assert(stmt.body[1]:__tostring()):eq("return (+ x 1)")
      end)

      test("fn Name ( Name ? := Exp ) = Exp - error", function()
        parser:parse("fn inc(x ? := 123) = x + 1")
        assert(function() parser:next() end):raises("')' expected on (1, 12).")
      end)

      test("fn Name ( Name := LiteralNum )", function()
        parser:parse("fn inc(x := 123)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "x",
          optional = true,
          type = "num",
        })
        assert(stmt.params[1].value:__tostring()):eq("123")
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name := LiteralText )", function()
        parser:parse('fn inc(x := "texto")')

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "x",
          optional = true,
          type = "text",
        })
        assert(stmt.params[1].value:__tostring()):eq("texto")
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name := true )", function()
        parser:parse("fn inc(x := true)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "x",
          optional = true,
          type = "bool",
        })
        assert(stmt.params[1].value:__tostring()):eq("true")
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name := false )", function()
        parser:parse("fn inc(x := false)")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "x",
          optional = true,
          type = "bool",
        })
        assert(stmt.params[1].value:__tostring()):eq("false")
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name := list )", function()
        parser:parse("fn inc(x := [])")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "x",
          optional = true,
          type = "list",
        })
        assert(tostring(stmt.params[1].value)):eq("[]")
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name := map )", function()
        parser:parse("fn inc(x := {})")

        stmt = parser:next()
        assert(stmt):isTable():has({
          line = 1,
          col = 1,
          annots = {},
          visib = nil,
          itype = nil,
          name = "inc",
          accessor = nil,
          rtype = nil,
          rvar = nil
        })
        assert(stmt.params):len(1)
        assert(stmt.params[1]):has({
          const = false,
          modifier = nil,
          name = "x",
          optional = true,
          type = "map",
        })
        assert(tostring(stmt.params[1].value)):eq("{}")
        assert(stmt.body):isEmpty()
      end)

      test("fn Name ( Name := nil ) - error", function()
        parser:parse("fn inc(x := nil)")
        assert(function() parser:next() end):raises("on (1, 13), for infering type, the default value must be a literal: bool, list, map, num or text.")
      end)

      test("fn Name . Name () : 123", function()
        parser:parse("fn MyType.method() : 123")
        assert(function() parser:next() end):raises("name expected on (1, 22).")
      end)
    end)

    test("visibility fn Name ()", function(params)
      parser:parse(params[1] .. " fn myfn()")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = params[1],
        async = false,
        itype = nil,
        name = "myfn",
        accessor = nil,
        rtype = nil,
        rvar = nil,
        params = {},
        body = {}
      })
    end):iter(
      {subtitle = " # export", params = "export"},
      {subtitle = " # pub", params = "pub"},
      {subtitle = " # pvt", params = "pvt"}
    )

    test("fn Name ()", function()
      parser:parse("fn myfn()")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        async = false,
        itype = nil,
        name = "myfn",
        accessor = nil,
        rtype = nil,
        rvar = nil,
        params = {},
        body = {}
      })
    end)

    test("@annot1\\nfn Name ()", function()
      parser:parse("@annot1\nfn myfn()")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 2,
        col = 1,
        annots = {"annot1"},
        visib = nil,
        async = false,
        itype = nil,
        name = "myfn",
        accessor = nil,
        rtype = nil,
        rvar = nil,
        params = {},
        body = {}
      })
    end)

    test("fn Name () -> self", function()
      parser:parse("fn myfn() -> self")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        async = false,
        itype = nil,
        name = "myfn",
        accessor = nil,
        rtype = nil,
        rvar = "self",
        params = {},
        body = {}
      })
    end)

    test("fn Name () -> Name", function()
      parser:parse("fn myfn() -> num")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        async = false,
        itype = nil,
        name = "myfn",
        accessor = nil,
        rtype = nil,
        rvar = "num",
        params = {},
        body = {}
      })
    end)

    test("fn Name () -> keyword", function()
      parser:parse("fn myfn() -> type")
      assert(function() parser:next() end):raises("on (1, 14), return value must be 'self' or a name.")
    end)

    test("fn Name () -> Name : Name", function()
      parser:parse("fn myfn() -> res:num")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        async = false,
        itype = nil,
        name = "myfn",
        accessor = nil,
        rtype = "num",
        rvar = "res",
        params = {},
        body = {}
      })
    end)

    test("fn Name . Name ()", function()
      parser:parse("fn MyType.myfn()")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = "pub",
        async = false,
        itype = "MyType",
        name = "myfn",
        accessor = nil,
        rtype = nil,
        rvar = nil,
        params = {},
        body = {}
      })
    end)

    test("fn Name : Name ()", function()
      parser:parse("fn MyType:myfn()")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = "pvt",
        async = false,
        itype = "MyType",
        name = "myfn",
        accessor = nil,
        rtype = nil,
        rvar = nil,
        params = {},
        body = {}
      })
    end)

    test("fn Name () = Exp", function()
      parser:parse("fn myfn() = 12 * 34")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        async = false,
        itype = nil,
        name = "myfn",
        accessor = nil,
        rtype = nil,
        rvar = nil,
        params = {}
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("return (* 12 34)")
    end)

    test("fn Name () : Name = Exp", function()
      parser:parse("fn myfn() : num = 12 * 34")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        async = false,
        itype = nil,
        name = "myfn",
        rtype = "num",
        rvar = nil,
        accessor = nil,
        params = {}
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("return (* 12 34)")
    end)

    test("fn Name ( Name , Name ) = Exp", function()
      parser:parse("fn sum(x, y) = x + y")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        async = false,
        itype = nil,
        name = "sum",
        accessor = nil,
        rtype = nil,
        rvar = nil,
        params = {
          {
            const = false,
            modifier = nil,
            name = "x",
            optional = false,
            type = nil,
            value = nil
          },
          {
            const = false,
            modifier = nil,
            name = "y",
            optional = false,
            type = nil,
            value = nil
          }
        }
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("return (+ x y)")
    end)

    test("async fn Name() Body", function()
      parser:parse("async fn sum(x, y) = x + y")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        async = true,
        itype = nil,
        name = "sum",
        accessor = nil,
        rtype = nil,
        rvar = nil,
        params = {
          {
            const = false,
            modifier = nil,
            name = "x",
            optional = false,
            type = nil,
            value = nil
          },
          {
            const = false,
            modifier = nil,
            name = "y",
            optional = false,
            type = nil,
            value = nil
          }
        }
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("return (+ x y)")
    end)
  end)

  ----------------
  -- nextType() --
  ----------------
  suite("nextType()", function()
    test("@annot1\\ntype Name()", function()
      parser:parse("@annot1\ntype Coord2D()")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 2,
        col = 1,
        annots = {"annot1"},
        visib = nil,
        name = "Coord2D",
        params = {},
        base = nil,
        bargs = nil,
        body = {},
        catch = nil,
        finally = nil
      })
    end)

    test("type Name()", function()
      parser:parse("type Coord2D()")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        name = "Coord2D",
        params = {},
        base = nil,
        bargs = nil,
        body = {},
        catch = nil,
        finally = nil
      })
    end)

    test("visibility type Name()", function(params)
      parser:parse(params[1] .. " type Coord2D()")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = params[1],
        name = "Coord2D",
        params = {},
        base = nil,
        bargs = nil,
        body = {},
        catch = nil,
        finally = nil
      })
    end):iter(
      {subtitle = " # export", params = "export"},
      {subtitle = " # pub", params = "pub"}
    )

    test("type Name(params)", function()
      parser:parse("type Coord2D(x, y)\n  .x = x\n  .y = y")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        name = "Coord2D",
        base = nil,
        bargs = nil,
        catch = nil,
        finally = nil
      })
      assert(stmt.params):len(2)
      assert(stmt.params[1]):has({name = "x"})
      assert(stmt.params[2]):has({name = "y"})
      assert(stmt.body):len(2)
      assert(stmt.body[1]:__tostring()):eq("(= (. x) x)")
      assert(stmt.body[2]:__tostring()):eq("(= (. y) y)")
    end)

    test("type Name() : Name", function()
      parser:parse("type Coord3D() : Coord2D")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        name = "Coord3D",
        params = {},
        base = "Coord2D",
        bargs = nil,
        body = {},
        catch = nil,
        finally = nil
      })
    end)

    test("type Name(params) : Name(args)", function()
      parser:parse("type Coord3D(x, y, .z) : Coord2D(x, y)")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        annots = {},
        visib = nil,
        name = "Coord3D",
        base = "Coord2D",
        body = {},
        catch = nil,
        finally = nil
      })
      assert(stmt.params):len(3)
      assert(stmt.params[1]):has({name = "x", modifier = nil})
      assert(stmt.params[2]):has({name = "y", modifier = nil})
      assert(stmt.params[3]):has({name = "z", modifier = "."})
      assert(stmt.bargs):len(2)
      assert(stmt.bargs[1]:__tostring()):eq("x")
      assert(stmt.bargs[2]:__tostring()):eq("y")
    end)
  end)

  -----------------
  -- nextAsync() --
  -----------------
  suite("nextAsync()", function()
    test("async Exp", function()
      parser:parse("async 1+2")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.ASYNC,
        opts = {},
        catch = nil
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring(("+ 1 2")))
    end)

    test("async with {delay=Exp} Exp", function()
      parser:parse("async with {delay=250+250} 1+2")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.ASYNC,
        catch = nil
      })
      assert(tostring(stmt.opts.delay)):eq("(+ 250 250)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring(("+ 1 2")))
    end)

    test("async\\n Exp\\n Exp", function()
      parser:parse("async\n 1+2\n 3+4")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.ASYNC,
        opts = {},
        catch = nil
      })
      assert(stmt.body):len(2)
      assert(stmt.body[1]:__tostring(("+ 1 2")))
      assert(stmt.body[2]:__tostring(("+ 3 4")))
    end)

    test("async\\n Exp\\ncatch\\n Exp", function()
      parser:parse("async\n 1+2\ncatch\n 3+4")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.ASYNC,
        opts = {}
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring(("+ 1 2")))
      assert(stmt.catch.body):len(1)
      assert(stmt.catch.body[1]:__tostring(("+ 3 4")))
    end)
  end):tags("async")

  --------------
  -- nextIf() --
  --------------
  suite("nextIf()", function()
    test("if Exp then Exp", function()
      parser:parse("if x == 123 then x = 321")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = nil,
        elif = nil,
        el = nil
      })
      assert(stmt.cond:__tostring()):eq("(== x 123)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 321)")
    end)

    test("if var Exp then Exp", function()
      parser:parse("if var x == 123 then x = 321")
      assert(function() parser:next() end):raises("anonymous code: ';' expected on (1, 17).")
    end)

    test("if var Exp; then Exp", function()
      parser:parse("if var x = 123; x then x = 321")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = "var",
        elif = nil,
        el = nil
      })
      assert(tostring(stmt.value)):eq("(= x 123)")
      assert(tostring(stmt.cond)):eq("x")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 321)")
    end)

    test("if const Exp; then Exp", function()
      parser:parse("if const x = 123; x then x = 321")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = "const",
        elif = nil,
        el = nil
      })
      assert(tostring(stmt.value)):eq("(= x 123)")
      assert(tostring(stmt.cond)):eq("x")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 321)")
    end)

    test("if Exp; Exp then Exp", function()
      parser:parse("if x == 123; x then x = 321")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = nil,
        elif = nil,
        el = nil
      })
      assert(tostring(stmt.value)):eq("(== x 123)")
      assert(tostring(stmt.cond)):eq("x")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 321)")
    end)

    test("if Exp then Stmt", function()
      parser:parse("if x == 123 then return 1+2")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = nil,
        elif = nil,
        el = nil
      })
      assert(stmt.cond:__tostring()):eq("(== x 123)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("return (+ 1 2)")
    end)

    test("if Exp then Exp else Exp", function()
      parser:parse("if x == 123 then x = 321 else x = 135")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = nil,
        elif = nil,
      })
      assert(stmt.cond:__tostring()):eq("(== x 123)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 321)")
      assert(stmt.el):len(1)
      assert(stmt.el[1]:__tostring()):eq("(= x 135)")
    end)

    test("if Exp then\\n Exp", function()
      parser:parse("if x == 123 then\n x = 321")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = nil,
        elif = nil,
        el = nil
      })
      assert(stmt.cond:__tostring()):eq("(== x 123)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 321)")
    end)

    test("if Exp then\\n Exp\\nelse\\n Exp", function()
      parser:parse("if x == 123 then\n x = 321\nelse\n x = 135")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = nil,
        elif = nil,
      })
      assert(stmt.cond:__tostring()):eq("(== x 123)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 321)")
      assert(stmt.el):len(1)
      assert(stmt.el[1]:__tostring()):eq("(= x 135)")
    end)

    test("if Exp then\\n Exp\\nelse if Exp then\\n Exp", function()
      parser:parse("if x == 111 then\n x = 222\nelse if x == 333 then\n x = 444")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = nil,
        el = nil
      })
      assert(stmt.cond:__tostring()):eq("(== x 111)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 222)")
      assert(stmt.elif):len(1)
      assert(stmt.elif[1].cond:__tostring()):eq("(== x 333)")
      assert(stmt.elif[1].body):len(1)
      assert(stmt.elif[1].body[1]:__tostring()):eq("(= x 444)")
    end)

    test("if Exp then\\n Exp\\nelse if Exp then\\n Exp\\nelse if Exp then\\n Exp", function()
      parser:parse("if x == 111 then\n x = 222\nelse if x == 333 then\n x = 444\nelse if x == 555 then\n x = 666")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = nil,
        el = nil
      })
      assert(stmt.cond:__tostring()):eq("(== x 111)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 222)")
      assert(stmt.elif):len(2)
      assert(stmt.elif[1].cond:__tostring()):eq("(== x 333)")
      assert(stmt.elif[1].body):len(1)
      assert(stmt.elif[1].body[1]:__tostring()):eq("(= x 444)")
      assert(stmt.elif[2].cond:__tostring()):eq("(== x 555)")
      assert(stmt.elif[2].body):len(1)
      assert(stmt.elif[2].body[1]:__tostring()):eq("(= x 666)")
    end)

    test("if Exp then\\n Exp\\nelse if Exp then\\n Exp\\nelse\\n Exp", function()
      parser:parse("if x == 111 then\n x = 222\nelse if x == 333 then\n x = 444\nelse x = 555")

      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.IF,
        decl = nil

      })
      assert(stmt.cond:__tostring()):eq("(== x 111)")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("(= x 222)")
      assert(stmt.elif):len(1)
      assert(stmt.elif[1].cond:__tostring()):eq("(== x 333)")
      assert(stmt.elif[1].body):len(1)
      assert(stmt.elif[1].body[1]:__tostring()):eq("(= x 444)")
      assert(stmt.el):len(1)
      assert(stmt.el[1]:__tostring()):eq("(= x 555)")
    end)
  end):tags("if")

  ---------------
  -- nextPub() --
  ---------------
  suite("nextPub()", function()
    test("pub", function()
      parser:parse("pub")
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.PUB,
        items = {}
      })
    end)

    test("pub Name", function()
      parser:parse("pub Item")
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.PUB,
        items = {{type = "pub", value = "Item"}}
      })
    end)

    test("pub Text", function()
      parser:parse('pub "Item"')
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.PUB,
        items = {{type = "use", value = {path = "Item", name = "Item"}}}
      })
    end)

    test("pub Name, Text", function()
      parser:parse('pub Item1, "Item2"')
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.PUB,
        items = {{type = "pub", value = "Item1"}, {type = "use", value = {path = "Item2", name = "Item2"}}}
      })
    end)

    test("pub\\n Name\\n Text", function()
      parser:parse('pub\n Item1\n "Item2"')
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.PUB,
        items = {{type = "pub", value = "Item1"}, {type = "use", value = {path = "Item2", name = "Item2"}}}
      })
    end)

    test("pub Name Name - error", function()
      parser:parse("pub Item1 Item2")
      assert(function() parser:next() end):raises("on (1,11), comma expected.")
    end)

    test("pub 123 - error", function()
      parser:parse("pub 123")
      assert(function() parser:next() end):raises("on (1,5), literal text or name expected.")
    end)
  end):tags("pub")

  ------------------
  -- nextExport() --
  ------------------
  suite("nextExport()", function()
    test("export", function()
      parser:parse("export")
      assert(function() parser:next() end):raises("incomplete expression started on (1, 7).")
    end)

    test("export Exp", function()
      parser:parse("export 1+2")
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.EXPORT
      })
      assert(tostring(stmt.exp)):eq("(+ 1 2)")
    end)
  end):tags("export")

  ----------------
  -- nextWith() --
  ----------------
  suite("nextWith()", function()
    test("with", function()
      parser:parse("with")
      assert(function() parser:next() end):raises("incomplete expression started on (1, 5).")
    end)

    test("with Exp", function()
      parser:parse("with 1+2")
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.WITH,
        ifs = {},
        els = nil
      })
      assert(parser:next()):isNil()
    end)

    test("with Exp if Exp then - with one sentence", function()
      parser:parse("with 1+2\n  if 1 then x")
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.WITH,
        els = nil
      })
      assert(tostring(stmt.value)):eq("(+ 1 2)")
      assert(stmt.ifs):len(1)
      assert(tostring(stmt.ifs[1].cond)):eq("1")
      assert(stmt.ifs[1].body):len(1)
      assert(tostring(stmt.ifs[1].body[1])):eq("x")
      assert(parser:next()):isNil()
    end)

    test("with Exp if Exp then - with several sentences", function()
      parser:parse("with 1+2\n  if 1 then x\n    y")
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.WITH,
        els = nil
      })
      assert(tostring(stmt.value)):eq("(+ 1 2)")
      assert(stmt.ifs):len(1)
      assert(tostring(stmt.ifs[1].cond)):eq("1")
      assert(stmt.ifs[1].body):len(2)
      assert(tostring(stmt.ifs[1].body[1])):eq("x")
      assert(tostring(stmt.ifs[1].body[2])):eq("y")
      assert(parser:next()):isNil()
    end)

    test("with Exp - with several if", function()
      parser:parse("with 1+2\n  if 1 then x\n  if 2 then y")
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.WITH,
        els = nil
      })
      assert(tostring(stmt.value)):eq("(+ 1 2)")
      assert(stmt.ifs):len(2)
      assert(tostring(stmt.ifs[1].cond)):eq("1")
      assert(stmt.ifs[1].body):len(1)
      assert(tostring(stmt.ifs[1].body[1])):eq("x")
      assert(tostring(stmt.ifs[2].cond)):eq("2")
      assert(stmt.ifs[2].body):len(1)
      assert(tostring(stmt.ifs[2].body[1])):eq("y")
      assert(parser:next()):isNil()
    end)

    test("with Exp - with if and else", function()
      parser:parse("with 1+2\n  if 1 then x\n  if 2 then y\n  else z\n")
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.WITH
      })
      assert(tostring(stmt.value)):eq("(+ 1 2)")
      assert(stmt.ifs):len(2)
      assert(tostring(stmt.ifs[1].cond)):eq("1")
      assert(stmt.ifs[1].body):len(1)
      assert(tostring(stmt.ifs[1].body[1])):eq("x")
      assert(tostring(stmt.ifs[2].cond)):eq("2")
      assert(stmt.ifs[2].body):len(1)
      assert(tostring(stmt.ifs[2].body[1])):eq("y")
      assert(stmt.els):isNotNil()
      assert(stmt.els):len(1)
      assert(tostring(stmt.els[1])):eq("z")
      assert(parser:next()):isNil()
    end)

    test("full with", function()
      parser:parse("with 1+2\n  if 1 then x\n    y\n  if 2 then a\n    b\n  else 1\n    2\nnop")
      stmt = parser:next()
      assert(stmt):isTable():has({
        line = 1,
        col = 1,
        subtype = StmtType.WITH
      })
      assert(tostring(stmt.value)):eq("(+ 1 2)")
      assert(stmt.ifs):len(2)
      assert(tostring(stmt.ifs[1].cond)):eq("1")
      assert(stmt.ifs[1].body):len(2)
      assert(tostring(stmt.ifs[1].body[1])):eq("x")
      assert(tostring(stmt.ifs[1].body[2])):eq("y")
      assert(tostring(stmt.ifs[2].cond)):eq("2")
      assert(stmt.ifs[2].body):len(2)
      assert(tostring(stmt.ifs[2].body[1])):eq("a")
      assert(tostring(stmt.ifs[2].body[2])):eq("b")
      assert(stmt.els):isNotNil()
      assert(stmt.els):len(2)
      assert(tostring(stmt.els[1])):eq("1")
      assert(tostring(stmt.els[2])):eq("2")
      assert(parser:next()):isTable():has({
        line = 8,
        col = 1,
        type = StmtType.EXP
      })
    end)
  end):tags("with")
end):tags("stmt")
