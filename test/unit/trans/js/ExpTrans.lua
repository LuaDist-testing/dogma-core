--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Trans = require("dogma.trans.js.Trans")
local Parser = require("dogma.syn.Parser")

--Suite.
return suite("dogma.trans.js._.ExpTrans", function()
  local trans, parser

  ----------
  -- init --
  ----------
  init("*", function()
    parser = Parser.new()
    trans = Trans.new()
    trans:transform(parser)
  end):title("Create transformer")

  --------------
  -- terminal --
  --------------
  suite("terminal", function()
    test("nop", function()
      parser:parse("nop")
      assert(trans:next()):eq("dogma.nop();\n")
    end):tags("nop")

    suite("name", function()
      test("name", function()
        parser:parse("x")
        assert(trans:next()):eq("x;\n")
      end)

      test("keyword", function()
        parser:parse("default")
        assert(trans:next()):eq("default_;\n")
      end)
    end)


    test("123", function()
      parser:parse("123")
      assert(trans:next()):eq("123;\n")
    end)

    test("true", function()
      parser:parse("true")
      assert(trans:next()):eq("true;\n")
    end)

    test("false", function()
      parser:parse("false")
      assert(trans:next()):eq("false;\n")
    end)

    test("nil", function()
      parser:parse("nil")
      assert(trans:next()):eq("null;\n")
    end)

    test([["text"]], function()
      parser:parse([["text"]])
      assert(trans:next()):eq('"text";\n')
    end)

    test("self", function()
      parser:parse("self")
      assert(trans:next()):eq("this;\n")
    end)

    test("(1+2)", function()
      parser:parse("(1+2)")
      assert(trans:next()):eq("(1+2);\n")
    end)

    test("super", function()
      parser:parse("super")
      assert(trans:next()):eq("super;\n")
    end)

    suite("list", function()
      test("[]", function()
        parser:parse("a + [] + b")
        assert(trans:next()):eq("((a+[])+b);\n")
      end)

      test("[Exp]", function()
        parser:parse("a + [123] + b")
        assert(trans:next()):eq("((a+[123])+b);\n")
      end)

      test("[Exp, Exp]", function()
        parser:parse("a + [123, 456] + b")
        assert(trans:next()):eq("((a+[123, 456])+b);\n")
      end)
    end)

    suite("map", function()
      test("{}", function()
        parser:parse("a + {}")
        assert(trans:next()):eq("(a+{});\n")
      end)

      test("{Name = Exp}", function()
        parser:parse("a + {x = 1+2}")
        assert(trans:next()):eq('(a+{["x"]: (1+2)});\n')
      end)

      test("{Name = Exp, Name = Exp}", function()
        parser:parse("a + {x = 1+2, y = 3+4}")
        assert(trans:next()):eq('(a+{["x"]: (1+2), ["y"]: (3+4)});\n')
      end)
    end):tags("map")

    suite("fn", function()
      test("fn() end", function()
        parser:parse("a + fn() end")
        assert(trans:next()):eq("(a+() => { {} });\n")
      end)

      test("fn(Name) end", function()
        parser:parse("a + fn(x) end")
        assert(trans:next()):eq('(a+(x) => { dogma.paramExpected("x", x, null);{} });\n')
      end)

      test("fn(Name) -> Name end", function()
        parser:parse("a + fn(x) -> x end")
        assert(trans:next()):eq('(a+(x) => { dogma.paramExpected("x", x, null);{} return x; });\n')
      end)

      test("fn(Name?) end", function()
        parser:parse("a + fn(x?) end")
        assert(trans:next()):eq("(a+(x) => { {} });\n")
      end)

      test("fn(Name : num) end", function()
        parser:parse("a + fn(x:num) end")
        assert(trans:next()):eq('(a+(x) => { dogma.paramExpected("x", x, num);{} });\n')
      end)

      test("fn(Name ? : num) end", function()
        parser:parse("a + fn(x?:num) end")
        assert(trans:next()):eq('(a+(x) => { dogma.paramExpectedToBe("x", x, num);{} });\n')
      end)

      test("fn(Name, Name) = Exp end", function()
        parser:parse("a + fn(x, y) = x - y end")
        assert(trans:next()):eq('(a+(x, y) => { dogma.paramExpected("x", x, null);dogma.paramExpected("y", y, null);{return (x-y);} });\n')
      end)
    end)

    test("native(literal)", function()
      parser:parse('x = native("new Proxy(target, handler)")')
      assert(trans:next()):eq("(x=new Proxy(target, handler));\n")
    end):tags("native")

    test("peval(Exp)", function()
      parser:parse("x = peval(1+2)")
      assert(trans:next()):eq("(x=dogma.peval(() => {return (1+2);}));\n")
    end)

    suite("throw", function()
      test("throw(Exp)", function()
        parser:parse([[throw("my error.")]])
        assert(trans:next()):eq('dogma.raise("my error.");\n')
      end)

      test("throw(Exp, Exp)", function()
        parser:parse([[throw("%s", "my error.")]])
        assert(trans:next()):eq('dogma.raise("%s", "my error.");\n')
      end)

      test("throw(Exp, Exp, Exp)", function()
        parser:parse([[throw("%s: %s", "internal error", "my message.")]])
        assert(trans:next()):eq('dogma.raise("%s: %s", "internal error", "my message.");\n')
      end)
    end):tags("throw")

    suite("if..then..else..end", function()
      test("if..then..else..end", function()
        parser:parse([[(if x then x+1 else x+2 end) + 3]])
        assert(trans:next()):eq("((x ? (x+1) : (x+2))+3);\n")
      end)
    end)
  end)

  ------------------
  -- non-terminal --
  ------------------
  suite("non-terminal", function()
    --------------
    -- unary op --
    --------------
    suite("unary op", function()
      test("...", function()
        parser:parse("...args")
        assert(trans:next()):eq("...(args);\n")
      end)

      test("$ Name", function()
        parser:parse("$x")
        assert(trans:next()):eq("this.x;\n")
      end)

      test(": Name", function()
        parser:parse(":x")
        assert(trans:next()):eq("this._x;\n")
      end)

      test("!x", function()
        parser:parse("!x")
        assert(trans:next()):eq("!(x);\n")
      end)

      test("not x", function()
        parser:parse("not x")
        assert(trans:next()):eq("!(x);\n")
      end)

      test("~x", function()
        parser:parse("~x")
        assert(trans:next()):eq("~(x);\n")
      end)

      test("+x", function()
        parser:parse("+x")
        assert(trans:next()):eq("+(x);\n")
      end)

      test("-x", function()
        parser:parse("-x")
        assert(trans:next()):eq("-(x);\n")
      end)
    end):tags("unaryop")

    ------------
    -- bin op --
    ------------
    suite("bin op", function()
      test("op", function(params)
        parser:parse("x " .. params[1] .. " y")
        assert(trans:next()):eq(("(x" .. params[1] .. "y);\n"))
      end):iter(
        {subtitle = "+", params = "+"},
        {subtitle = "-", params = "-"},
        {subtitle = "*", params = "*"},
        {subtitle = "**", params = "**"},
        {subtitle = "/", params = "/"},
        {subtitle = "%", params = "%"},
        {subtitle = "==", params = "=="},
        {subtitle = "!=", params = "!="},
        {subtitle = "===", params = "==="},
        {subtitle = "!==", params = "!=="},
        {subtitle = "<", params = "<"},
        {subtitle = "<=", params = "<="},
        {subtitle = ">", params = ">"},
        {subtitle = ">=", params = ">="},
        {subtitle = "<<", params = "<<"},
        {subtitle = ">>", params = ">>"},
        {subtitle = "=", params = "="},
        {subtitle = "+=", params = "+="},
        {subtitle = "-=", params = "-="},
        {subtitle = "*=", params = "*="},
        {subtitle = "**=", params = "**="},
        {subtitle = "/=", params = "/="},
        {subtitle = "%=", params = "%="},
        {subtitle = ">>=", params = ">>="},
        {subtitle = "<<=", params = "<<="},
        {subtitle = "|=", params = "|="},
        {subtitle = "&=", params = "&="},
        {subtitle = "^=", params = "^="},
        {subtitle = "||", params = "||"},
        {subtitle = "&&", params = "&&"}
      )

      suite(":=", function()
        test("$Name := Exp", function()
          parser:parse("$x := 123")
          assert(trans:next()):eq('Object.defineProperty(this, "x", {value: 123, enum: true});\n')
        end)

        test(":Name := Exp", function()
          parser:parse(":x := 123")
          assert(trans:next()):eq('Object.defineProperty(this, "_x", {value: 123});\n')
        end)

        test("Name . Name := Exp", function()
          parser:parse("x.y := 123")
          assert(trans:next()):eq('Object.defineProperty(x, "y", {value: 123, enum: true});\n')
        end)

        test("Name : Name := Exp", function()
          parser:parse("x:y := 123")
          assert(trans:next()):eq('Object.defineProperty(x, "_y", {value: 123});\n')
        end)

        test("x[y]:=z", function()
          parser:parse("x[y]:=z")
          assert(trans:next()):eq('dogma.setItem("=", x, y, z);\n')
        end)
      end)

      suite(".=", function()
        test(":Name .= Exp", function()
          parser:parse(":x .= 123")
          assert(trans:next()):eq('Object.defineProperty(this, "_x", {value: 123});Object.defineProperty(this, "x", {enum: true, get() { return this._x; }});\n')
        end)
      end)

      test("and", function()
        parser:parse("x and y")
        assert(trans:next()):eq("(x&&y);\n")
      end)

      test("or", function()
        parser:parse("x or y")
        assert(trans:next()):eq("(x||y);\n")
      end)

      suite(".", function()
        test("read", function()
          parser:parse("x.y")
          assert(trans:next()):eq("x.y;\n")
        end)

        test("write", function()
          parser:parse("x.y=z")
          assert(trans:next()):eq("(x.y=z);\n")
        end)
      end)

      suite(":", function()
        test("x:y", function()
          parser:parse("x:y")
          assert(trans:next()):eq("x._y;\n")
        end)

        test("x:keyword", function()
          parser:parse("x:default")
          assert(trans:next()):eq("x._default;\n")
        end)

        test("x:y=z", function()
          parser:parse("x:y=z")
          assert(trans:next()):eq("(x._y=z);\n")
        end)

        test("x:keyword=y", function()
          parser:parse("x:default=y")
          assert(trans:next()):eq("(x._default=y);\n")
        end)
      end)

      suite("[]", function()
        test("Exp [ Name ]", function()
          parser:parse("x[y]")
          assert(trans:next()):eq("dogma.getItem(x, y);\n")
        end)

        test("Exp [ Name ] = Exp", function()
          parser:parse("x[y] = z")
          assert(trans:next()):eq('dogma.setItem("=", x, y, z);\n')
        end)

        test("Exp [ num ]", function()
          parser:parse("x[123]")
          assert(trans:next()):eq("dogma.getItem(x, 123);\n")
        end)

        test("Exp [ text ]", function()
          parser:parse('x["id"]')
          assert(trans:next()):eq('dogma.getItem(x, "id");\n')
        end)
      end)

      test("is", function()
        parser:parse("x is text")
        assert(trans:next()):eq("dogma.is(x, text);\n")
      end)

      test("is not", function()
        parser:parse("x is not text")
        assert(trans:next()):eq("dogma.isNot(x, text);\n")
      end)

      suite("in", function()
        test("in", function()
          parser:parse("x in array")
          assert(trans:next()):eq("(array).includes(x);\n")
        end)

        test("not in", function()
          parser:parse("x not in array")
          assert(trans:next()):eq("!(array).includes(x);\n")
        end)
      end)

      test("like", function()
        parser:parse("x like y")
        assert(trans:next()):eq("dogma.like(x, y);\n")
      end)

      test("notLike", function()
        parser:parse("x not like y")
        assert(trans:next()):eq("dogma.notLike(x, y);\n")
      end)
    end):tags("binop")

    ----------------
    -- ternary op --
    ----------------
    suite("ternary op", function()
      test("x[y, z]", function()
        parser:parse("x[y, z]")
        assert(trans:next()):eq("dogma.getSlice(x, y, z);\n")
      end)

      test("o.m[x, y]", function()
        parser:parse("o.m()[123, 456]")
        assert(trans:next()):eq("dogma.getSlice(o.m(), 123, 456);\n")
      end)
    end):tags("ternaryop")
  end)

  ----------
  -- misc --
  ----------
  suite("misc", function()
    test("terminal terminal - error", function()
      parser:parse("x y")
      assert(function() parser:next() end):raises("(1,3): terminal can't follow to other terminal.")
    end):tags("xyz")
  end)
end):tags("exp")
