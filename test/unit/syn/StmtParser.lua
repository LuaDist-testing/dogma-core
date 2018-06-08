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

  -----------------
  -- nextConst() --
  -----------------
  suite("nextConst()", function()
    test("const x - error - = expected", function()
      parser:parse("const x")
      assert(function() parser:next() end):raises("'=' expected on (1, 8).")
    end)

    test("visibility const x = 12", function(params)
      parser:parse(params[1] .. " const x = 12")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST, visib = params[1]})
      assert(stmt.vars):len(1)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("12")
    end):iter(
      {subtitle = " # export", params = "export"},
      {subtitle = " # pub", params = "pub"}
    )

    test("const x = 12 + 34", function()
      parser:parse("const x = 12 + 34")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
      assert(stmt.vars):len(1)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
    end)

    test("const x = 12+34, y = 56 + 78, z = 9", function()
      parser:parse("const x = 12+34, y = 56+78, z = 9")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
      assert(stmt.vars):len(3)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
      assert(stmt.vars[2].name):eq("y")
      assert(stmt.vars[2].value:__tostring()):eq("(+ 56 78)")
      assert(stmt.vars[3].name):eq("z")
      assert(stmt.vars[3].value:__tostring()):eq("9")
    end)

    test("const x = 12 ? y = 34", function()
      parser:parse("const x = 12 ? y = 34")
      assert(function() parser:next() end):raises("comma expected on (1, 14) for separating variables.")
    end)

    test("const\\n  x = 12*34", function()
      parser:parse("const\n  x = 12+34")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
      assert(stmt.vars):len(1)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
    end)

    test("const\\n  x = 12+34\\n  y=56*78\\n  z = 9", function()
      parser:parse("const\n  x = 12+34\n  y = 56*78\n  z = 9")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
      assert(stmt.vars):len(3)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
      assert(stmt.vars[2].name):eq("y")
      assert(stmt.vars[2].value:__tostring()):eq("(* 56 78)")
      assert(stmt.vars[3].name):eq("z")
      assert(stmt.vars[3].value:__tostring()):eq("9")
    end)

    test("const\\nx = 12 + 34", function()
      parser:parse("const\nx = 12 + 34")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.CONST,
        vars = {}
      })
    end)

    test("const\\n  x = 12 + 34\\ny = 56 + 78", function()
      parser:parse("const\n  x = 12 + 34\ny = 56 + 78")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
      assert(stmt.vars):len(1)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
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

  ---------------
  -- nextUse() --
  ---------------
  suite("nextUse()", function()
    test("use LiteralStr", function()
      parser:parse('use "module"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = false, name = "module", path = "module"}
      })
    end)

    test("use\\n LiteralStr", function()
      parser:parse('use\n "module"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = false, name = "module", path = "module"}
      })
    end)

    test("use\\nLiteralStr", function()
      parser:parse('use\n"module"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({})
    end)

    test("use LitealStr, LiteralStr", function()
      parser:parse('use "module1", "module2"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = false, name = "module1", path = "module1"},
        {type = false, name = "module2", path = "module2"}
      })
    end)

    test("use\\n  LiteralStr\\n  LiteralStr", function()
      parser:parse('use\n "module1"\n "module2"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = false, name = "module1", path = "module1"},
        {type = false, name = "module2", path = "module2"}
      })
    end)

    test("use LiteralStr as Name", function()
      parser:parse('use "module" as mod')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = false, name = "mod", path = "module"}
      })
    end)

    test("use\\n LiteralStr as Name", function()
      parser:parse('use\n "module" as mod')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = false, name = "mod", path = "module"}
      })
    end)

    test("use LiteralStr as Name, LiteralStr as Name", function()
      parser:parse('use "module1" as mod1, "module2" as mod2')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = false, name = "mod1", path = "module1"},
        {type = false, name = "mod2", path = "module2"}
      })
    end)

    test("use\\n LiteralStr as Name\\n LiteralStr as Name", function()
      parser:parse('use\n "module1" as mod1\n "module2" as mod2')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = false, name = "mod1", path = "module1"},
        {type = false, name = "mod2", path = "module2"}
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
        {type = false, name = "two", path = "one/two"}
      })
    end)

    test("use type LiteralStr", function()
      parser:parse([[use type "one/two"]])
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = true, name = "two", path = "one/two"}
      })
    end)

    test("use\\n type LiteralStr\\n type LiteralStr", function()
      parser:parse('use\n type "one"\n "two"\n type "three"')
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.USE})
      assert(stmt.modules):eq({
        {type = true, name = "one", path = "one"},
        {type = false, name = "two", path = "two"},
        {type = true, name = "three", path = "three"}
      })
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
          {type = false, name = "FSWatcher", as = "FSWatcher"}
        }
      })
    end)

    test("from LiteralStr use type Name", function()
      parser:parse([[from "fs" use type FSWatcher]])
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.FROM,
        line = 1,
        col = 1,
        module = "fs",
        members = {
          {type = true, name = "FSWatcher", as = "FSWatcher"}
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
          {type = false, name = "FSWatcher", as = "Watcher"}
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
          {type = false, name = "FSWatcher", as = "FSWatcher"},
          {type = false, name = "watch", as = "watch"}
        }
      })
    end)

    test("from LiteralStr use type Name, Name, type Name", function()
      parser:parse([[from "fs" use type FSWatcher, watch, type Other]])
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.FROM,
        line = 1,
        col = 1,
        module = "fs",
        members = {
          {type = true, name = "FSWatcher", as = "FSWatcher"},
          {type = false, name = "watch", as = "watch"},
          {type = true, name = "Other", as = "Other"}
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
          {type = false, name = "FSWatcher", as = "Watcher"},
          {type = false, name = "watch", as = "wtch"}
        }
      })
    end)
  end):tags("from")

  ---------------
  -- nextVar() --
  ---------------
  suite("nextVar()", function()
    test("var x", function()
      parser:parse("var x")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.VAR,
        vars = {{name = "x", value = nil}}
      })
    end)

    test("visibility var x", function(params)
      parser:parse(params[1] .. " var x")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.VAR,
        visib = params[1],
        vars = {{name = "x", value = nil}}
      })
    end):iter(
      {subtitle = " # export", params = "export"},
      {subtitle = " # pub", params = "pub"}
    )

    test("var x = 12 + 34", function()
      parser:parse("var x = 12 + 34")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.vars):len(1)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
    end)

    test("var x = 12+34, y, z = 56*78", function()
      parser:parse("var x = 12+34, y, z = 56*78")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.vars):len(3)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
      assert(stmt.vars[2].name):eq("y")
      assert(stmt.vars[2].value):isNil()
      assert(stmt.vars[3].name):eq("z")
      assert(stmt.vars[3].value:__tostring()):eq("(* 56 78)")
    end)

    test("var x = 12 ? y", function()
      parser:parse("var x = 12 ? y")
      assert(function() parser:next() end):raises("comma expected on (1, 12) for separating variables.")
    end)

    test("var\\n  x", function()
      parser:parse("var\n  x")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.VAR,
        vars = {{name = "x", value = nil}}
      })
    end)

    test("var\\n  x = 12*34", function()
      parser:parse("var\n  x = 12+34")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.vars):len(1)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
    end)

    test("var\\n  x = 12+34\\n  y\\n  z = 56*78", function()
      parser:parse("var\n  x = 12+34\n  y\n  z = 56*78")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.vars):len(3)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
      assert(stmt.vars[2].name):eq("y")
      assert(stmt.vars[2].value):isNil()
      assert(stmt.vars[3].name):eq("z")
      assert(stmt.vars[3].value:__tostring()):eq("(* 56 78)")
    end)

    test("var\\nx = 12 + 34", function()
      parser:parse("var\nx = 12 + 34")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.VAR,
        vars = {}
      })
    end)

    test("var\\n  x = 12 + 34\\ny = 56 + 78", function()
      parser:parse("var\n  x = 12 + 34\ny = 56 + 78")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.vars):len(1)
      assert(stmt.vars[1].name):eq("x")
      assert(stmt.vars[1].value:__tostring()):eq("(+ 12 34)")
    end)
  end)

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

      test("fn Name ( $ Name )", function()
        parser:parse("fn inc($x)")

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
              modifier = "$",
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
            {name = "x", type = "any"}
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
            {name = "x", type = "num"}
          }
        })
      end)

      test("fn Name(Name : {Name, Name})", function()
        parser:parse("fn myfn(p:{x, y})")
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
            {name = "x", type = "any"},
            {name = "y", type = "any"}
          }
        })
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
        optional = false,
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
        optional = false,
        type = "num",
      })
      assert(stmt.params[1].value:__tostring()):eq("123")
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring()):eq("return (+ x 1)")
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
        optional = false,
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
        optional = false,
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
        optional = false,
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
        optional = false,
        type = "bool",
      })
      assert(stmt.params[1].value:__tostring()):eq("false")
      assert(stmt.body):isEmpty()
    end)

    test("fn Name ( Name := [0, 1, 2] ) - error", function()
      parser:parse("fn inc(x := [0, 1, 2])")
      assert(function() parser:next() end):raises("on (1, 13), for infering type, the default value must be a literal: text, num or bool.")
    end)

    test("fn Name . Name () : 123", function()
      parser:parse("fn MyType.method() : 123")
      assert(function() parser:next() end):raises("name expected on (1, 22).")
    end)
  end):tags("pfn")

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
      parser:parse("type Coord2D(x, y)\n  $x = x\n  $y = y")

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
      assert(stmt.body[1]:__tostring()):eq("(= ($ x) x)")
      assert(stmt.body[2]:__tostring()):eq("(= ($ y) y)")
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
      parser:parse("type Coord3D(x, y, $z) : Coord2D(x, y)")

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
      assert(stmt.params[3]):has({name = "z", modifier = "$"})
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
        catch = nil
      })
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
        subtype = StmtType.ASYNC
      })
      assert(stmt.body):len(1)
      assert(stmt.body[1]:__tostring(("+ 1 2")))
      assert(stmt.catch.body):len(1)
      assert(stmt.catch.body[1]:__tostring(("+ 3 4")))
    end)
  end)

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
        elif = nil,
        el = nil
      })
      assert(stmt.cond:__tostring()):eq("(== x 123)")
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
        subtype = StmtType.IF
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
end):tags("stmt")
