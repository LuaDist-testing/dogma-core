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
        decls = {{type = "std", name = "x", value = nil}}
      })
    end)

    test("visibility var x", function(params)
      parser:parse(params[1] .. " var x")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.VAR,
        visib = params[1],
        decls = {{type = "std", name = "x", value = nil}}
      })
    end):iter(
      {subtitle = " # export", params = "export"},
      {subtitle = " # pub", params = "pub"}
    )

    test("var x = 12 + 34", function()
      parser:parse("var x = 12 + 34")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.decls):len(1)
      assert(stmt.decls[1].type):eq("std")
      assert(stmt.decls[1].name):eq("x")
      assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
    end)

    test("var x = 12+34, y, z = 56*78", function()
      parser:parse("var x = 12+34, y, z = 56*78")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.decls):len(3)
      assert(stmt.decls[1].type):eq("std")
      assert(stmt.decls[1].name):eq("x")
      assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
      assert(stmt.decls[2].type):eq("std")
      assert(stmt.decls[2].name):eq("y")
      assert(stmt.decls[2].value):isNil()
      assert(stmt.decls[3].name):eq("z")
      assert(tostring(stmt.decls[3].value)):eq("(* 56 78)")
    end)

    test("var x = 12 ; y", function()
      parser:parse("var x = 12 ; y")
      assert(function() parser:next() end):raises("anonymous code: ',' expected on (1, 12).")
    end)

    test("var\\n  x", function()
      parser:parse("var\n  x")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.VAR,
        decls = {{type = "std", name = "x", value = nil}}
      })
    end)

    test("var\\n  x = 12*34", function()
      parser:parse("var\n  x = 12+34")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.decls):len(1)
      assert(stmt.decls[1].type):eq("std")
      assert(stmt.decls[1].name):eq("x")
      assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
    end)

    test("var\\n  x = 12+34\\n  y\\n  z = 56*78", function()
      parser:parse("var\n  x = 12+34\n  y\n  z = 56*78")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.decls):len(3)
      assert(stmt.decls[1].type):eq("std")
      assert(stmt.decls[1].name):eq("x")
      assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
      assert(stmt.decls[2].type):eq("std")
      assert(stmt.decls[2].name):eq("y")
      assert(stmt.decls[2].value):isNil()
      assert(stmt.decls[3].type):eq("std")
      assert(stmt.decls[3].name):eq("z")
      assert(tostring(stmt.decls[3].value)):eq("(* 56 78)")
    end)

    test("var\\nx = 12 + 34", function()
      parser:parse("var\nx = 12 + 34")
      stmt = parser:next()
      assert(stmt):isTable():has({
        type = SentType.STMT,
        subtype = StmtType.VAR,
        decls = {}
      })
    end)

    test("var\\n  x = 12 + 34\\ny = 56 + 78", function()
      parser:parse("var\n  x = 12 + 34\ny = 56 + 78")
      stmt = parser:next()
      assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.VAR})
      assert(stmt.decls):len(1)
      assert(stmt.decls[1].type):eq("std")
      assert(stmt.decls[1].name):eq("x")
      assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
    end)
  end):tags("var")

  -----------------
  -- nextConst() --
  -----------------
  suite("nextConst()", function()
    suite("std", function()
      test("const x - error - = expected", function()
        parser:parse("const x")
        assert(function() parser:next() end):raises("'=' expected on (1, 8).")
      end)

      test("visibility const x = 12", function(params)
        parser:parse(params[1] .. " const x = 12")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST, visib = params[1]})
        assert(stmt.decls):len(1)
        assert(stmt.decls[1].type):eq("std")
        assert(stmt.decls[1].name):eq("x")
        assert(tostring(stmt.decls[1].value)):eq("12")
      end):iter(
        {subtitle = " # export", params = "export"},
        {subtitle = " # pub", params = "pub"}
      )

      test("const x = 12 + 34", function()
        parser:parse("const x = 12 + 34")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(1)
        assert(stmt.decls[1].type):eq("std")
        assert(stmt.decls[1].name):eq("x")
        assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
      end)

      test("const x = 12+34, y = 56 + 78, z = 9", function()
        parser:parse("const x = 12+34, y = 56+78, z = 9")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(3)
        assert(stmt.decls[1].type):eq("std")
        assert(stmt.decls[1].name):eq("x")
        assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
        assert(stmt.decls[2].type):eq("std")
        assert(stmt.decls[2].name):eq("y")
        assert(tostring(stmt.decls[2].value)):eq("(+ 56 78)")
        assert(stmt.decls[3].name):eq("z")
        assert(stmt.decls[3].name):eq("z")
        assert(tostring(stmt.decls[3].value)):eq("9")
      end)

      test("const x = 12 ; y = 34", function()
        parser:parse("const x = 12 ; y = 34")
        assert(function() parser:next() end):raises("',' expected on (1, 14).")
      end)

      test("const\\n  x = 12*34", function()
        parser:parse("const\n  x = 12+34")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(1)
        assert(stmt.decls[1].type):eq("std")
        assert(stmt.decls[1].name):eq("x")
        assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
      end)

      test("const\\n  x = 12+34\\n  y=56*78\\n  z = 9", function()
        parser:parse("const\n  x = 12+34\n  y = 56*78\n  z = 9")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(3)
        assert(stmt.decls[1].type):eq("std")
        assert(stmt.decls[1].name):eq("x")
        assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
        assert(stmt.decls[2].type):eq("std")
        assert(stmt.decls[2].name):eq("y")
        assert(tostring(stmt.decls[2].value)):eq("(* 56 78)")
        assert(stmt.decls[3].type):eq("std")
        assert(stmt.decls[3].name):eq("z")
        assert(tostring(stmt.decls[3].value)):eq("9")
      end)

      test("const\\nx = 12 + 34", function()
        parser:parse("const\nx = 12 + 34")
        stmt = parser:next()
        assert(stmt):isTable():has({
          type = SentType.STMT,
          subtype = StmtType.CONST,
          decls = {}
        })
      end)

      test("const\\n  x = 12 + 34\\ny = 56 + 78", function()
        parser:parse("const\n  x = 12 + 34\ny = 56 + 78")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(1)
        assert(stmt.decls[1].type):eq("std")
        assert(stmt.decls[1].name):eq("x")
        assert(tostring(stmt.decls[1].value)):eq("(+ 12 34)")
      end)
    end)

    suite("map", function()
      test("const {x} = 1+2", function()
        parser:parse("const {x} = 1+2")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(1)
        assert(stmt.decls[1].type):eq("map")
        assert(stmt.decls[1].names):eq({"x"})
        assert(tostring(stmt.decls[1].value)):eq("(+ 1 2)")
      end)

      test("const {x, y} = 1+2", function()
        parser:parse("const {x, y} = 1+2")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(1)
        assert(stmt.decls[1].type):eq("map")
        assert(stmt.decls[1].names):eq({"x", "y"})
        assert(tostring(stmt.decls[1].value)):eq("(+ 1 2)")
      end)
    end)

    suite("list", function()
      test("const [x] = 1+2", function()
        parser:parse("const [x] = 1+2")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(1)
        assert(stmt.decls[1].type):eq("list")
        assert(stmt.decls[1].names):eq({"x"})
        assert(tostring(stmt.decls[1].value)):eq("(+ 1 2)")
      end)

      test("const [x, y] = 1+2", function()
        parser:parse("const [x, y] = 1+2")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(1)
        assert(stmt.decls[1].type):eq("list")
        assert(stmt.decls[1].names):eq({"x", "y"})
        assert(tostring(stmt.decls[1].value)):eq("(+ 1 2)")
      end)

      test("const [x, ...y] = 1+2", function()
        parser:parse("const [x, ...y] = 1+2")
        stmt = parser:next()
        assert(stmt):isTable():has({type = SentType.STMT, subtype = StmtType.CONST})
        assert(stmt.decls):len(1)
        assert(stmt.decls[1].type):eq("list")
        assert(stmt.decls[1].names):eq({"x", "...y"})
        assert(tostring(stmt.decls[1].value)):eq("(+ 1 2)")
      end)
    end)
  end):tags("var")
end):tags("stmt")
