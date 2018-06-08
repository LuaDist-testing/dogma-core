--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Parser = require("dogma.syn.Parser")
local SentType = require("dogma.syn.SentType")

--Suite.
return suite("dogma.syn.ExpParser", function()
  local parser, exp

  ----------
  -- init --
  ----------
  init("*", function()
    parser = Parser.new()
  end):title("Create parser")

  --------------
  -- terminal --
  --------------
  suite("terminal", function()
    suite("(Exp)", function()
      test("(Exp)", function()
        parser:parse("(1+2)")
        exp = parser:next()
        assert(tostring(exp)):eq("(+ 1 2)")
      end)

      test("(Exp) + ...", function()
        parser:parse("(1+2)+3")
        exp = parser:next()
        assert(tostring(exp)):eq("(+ (+ 1 2) 3)")
      end)

      test("(Exp", function()
        parser:parse("(1+2")
        assert(function() parser:next() end):raises("')' expected on (1, 5).")
      end)
    end)

    suite("if..then..else..end", function()
      test("if Exp then Exp else Exp end", function()
        parser:parse("x + if x == true then a+b else c+d end")
        exp = parser:next()
        assert(tostring(exp)):eq("(+ x (if (== x true) (+ a b) (+ c d)))")
      end)

      test("if Exp else Exp - error - then expected", function()
        parser:parse("x + if a else b")
        assert(function() parser:nextExp() end):raises("'then' expected on (1, 10).")
      end)

      test("if Exp then Exp else Exp - error - end expected", function()
        parser:parse("x + if a then b else c")
        assert(function() parser:nextExp() end):raises("'end' expected on (1, 23).")
      end)

      test("a + if Exp then Exp else Exp end + e", function()
        parser:parse("a + if b then c else d end + e")
        assert(tostring(parser:nextExp())):eq("(+ (+ a (if b c d)) e)")
      end)
    end)

    test("self", function()
      parser:parse("self")
      exp = parser:next()
      assert(exp):isTable():has({
        line = 1,
        col = 1,
        type = SentType.EXP
      })
      assert(exp.tree.root):isNotNil()
      assert(tostring(exp)):eq("self")
    end)

    test("x", function()
      parser:parse("x")
      exp = parser:next()
      assert(exp):isTable():has({
        line = 1,
        col = 1,
        type = SentType.EXP
      })
      assert(exp.tree.root):isNotNil()
      assert(tostring(exp)):eq("x")
    end)

    suite("fn", function()
      test("x + fn() = Exp end", function()
        parser:parse("x + fn() = 1+2 end")

        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x fn(){return (+ 1 2)})")
      end)

      test("x + fn(a,b) end", function()
        parser:parse("x + fn(a,b) end")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x fn(a, b){})")
      end)

      test("x + fn()\\nSent\\nend", function()
        parser:parse("x + fn(a, b)\nreturn a+b\nend")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x fn(a, b){return (+ a b)})")
      end)

      test("x + fn()\\nSent\\nSent\\n end", function()
        parser:parse("x + fn()\n1\n2\nend")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x fn(){1; 2})")
      end)
    end)

    suite("list", function()
      test("x + []", function()
        parser:parse("x + []")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x [])")
      end)

      test("x + [123]", function()
        parser:parse("x + [123]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x [123])")
      end)

      test("x + [\\n123\\n]", function()
        parser:parse("x + [\n123\n]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x [123])")
      end)

      test("x + [123, 456]", function()
        parser:parse("x + [123, 456]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x [123, 456])")
      end)

      test("x + [\\n123\\n456\\n]", function()
        parser:parse("x + [\n123\n456\n]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x [123, 456])")
      end)

      test("x + [123, 456, 789]", function()
        parser:parse("x + [123, 456, 789]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x [123, 456, 789])")
      end)

      test("x + [\\n123\\n456\\n789\\n]", function()
        parser:parse("x + [\n123\n456\n789\n]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x [123, 456, 789])")
      end)

      test("x + [123, 456, 789] + y", function()
        parser:parse("x + [123, 456, 789] + y")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ (+ x [123, 456, 789]) y)")
      end)
    end)

    suite("map", function()
      test("x + {}", function()
        parser:parse("x + {}")

        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()

        assert(tostring(exp)):eq("(+ x {})")
        assert(parser:next()):isNil()
      end)

      test("x + {one = 1}", function()
        parser:parse("x + {one = 1}")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x {one = 1})")
      end)

      test("x + {\\none = 1\\n}", function()
        parser:parse("x + {\none = 1\n}")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x {one = 1})")
      end)

      test("x + {one = 1, two = 2}", function()
        parser:parse("x + {one = 1, two = 2}")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x {one = 1, two = 2})")
      end)

      test("x + {\\none = 1\\ntwo = 2\\n}", function()
        parser:parse("x + {\none = 1\ntwo = 2\n}")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x {one = 1, two = 2})")
      end)

      test("x + {\\none = 1\\n\\ntwo = 2\\n}", function()
        parser:parse("x + {\none = 1\n\ntwo = 2\n}")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x {one = 1, two = 2})")
      end)

      test("x + {one = 1, two = 2, three = 3}", function()
        parser:parse("x + {one = 1, two = 2, three = 3}")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x {one = 1, two = 2, three = 3})")
      end)

      test("x + {\\none = 1\\ntwo = 2\\nthree = 3\\n}", function()
        parser:parse("x + {\none = 1\ntwo = 2\nthree = 3\n}")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(exp.tree.root):isNotNil()
        assert(tostring(exp)):eq("(+ x {one = 1, two = 2, three = 3})")
      end)
    end)
  end)

  --------------
  -- unary op --
  --------------
  suite("unary op", function()
    test("...", function()
      parser:parse("...args")
      assert(tostring(parser:next())):eq("(... args)")
    end)

    suite("+", function()
      test("+x", function()
        parser:parse("+x")
        assert(tostring(parser:next())):eq("(+ x)")
      end)

      test("x + +y", function()
        parser:parse("x + +y")
        assert(tostring(parser:next())):eq("(+ x (+ y))")
      end)

      test("x + +y + z", function()
        parser:parse("x + +y + z")
        assert(tostring(parser:next())):eq("(+ (+ x (+ y)) z)")
      end)
    end)

    suite("-", function()
      test("-x", function()
        parser:parse("-x")
        assert(tostring(parser:next())):eq("(- x)")
      end)

      test("x + -y", function()
        parser:parse("x + -y")
        assert(tostring(parser:next())):eq("(+ x (- y))")
      end)

      test("x + -y + z", function()
        parser:parse("x + -y + z")
        assert(tostring(parser:next())):eq("(+ (+ x (- y)) z)")
      end)
    end)

    test("not x", function()
      parser:parse("not x")
      assert(tostring(parser:next())):eq("(not x)")
    end)

    test("!x", function()
      parser:parse("!x")
      assert(tostring(parser:next())):eq("(! x)")
    end)

    test(". Name", function()
      parser:parse(".x")
      assert(tostring(parser:nextExp())):eq("(. x)")
    end)

    test(": Name", function()
      parser:parse(":x")
      assert(tostring(parser:nextExp())):eq("(: x)")
    end)

    test(":123 - error", function()
      parser:parse(":123")
      assert(function()
        parser:nextExp()
      end):raises("on (1, 2), '.' and ':' must be followed by identifier.")
    end)
  end):tags("unaryop")

  ------------
  -- bin op --
  ------------
  suite("bin op", function()
    test("x = 123", function()
      parser:parse("x = 123")
      assert(tostring(parser:next())):eq("(= x 123)")
    end)

    test("x ?= 123", function()
      parser:parse("x ?= 123")
      assert(tostring(parser:next())):eq("(?= x 123)")
    end)

    test(":x .= 123", function()
      parser:parse(":x .= 123")
      assert(tostring(parser:next())):eq("(.= (: x) 123)")
    end)

    test("x := 123", function()
      parser:parse("x := 123")
      assert(tostring(parser:next())):eq("(:= x 123)")
    end)

    test("x += 123", function()
      parser:parse("x += 123")
      assert(tostring(parser:next())):eq("(+= x 123)")
    end)

    suite(".", function()
      test("x.y", function()
        parser:parse("x.y")
        assert(tostring(parser:next())):eq("(. x y)")
      end)

      test("(x+y).z", function()
        parser:parse("(x+y).z")
        assert(tostring(parser:next())):eq("(. (+ x y) z)")
      end)

      test("a+(b+c).d", function()
        parser:parse("a+(b+c).d")
        assert(tostring(parser:next())):eq("(+ a (. (+ b c) d))")
      end)
    end)

    suite(":", function()
      test("x:y", function()
        parser:parse("x:y")
        assert(tostring(parser:next())):eq("(: x y)")
      end)

      test("(x+y):z", function()
        parser:parse("(x+y):z")
        assert(tostring(parser:next())):eq("(: (+ x y) z)")
      end)

      test("a+(b+c):d", function()
        parser:parse("a+(b+c):d")
        assert(tostring(parser:next())):eq("(+ a (: (+ b c) d))")
      end)
    end)

    test("x + y", function()
      parser:parse("x+y")
      assert(tostring(parser:next())):eq("(+ x y)")
    end)

    test("1+2*3 - different precedence", function()
      parser:parse("1 + 2 * 3")
      exp = parser:nextExp()
      assert(tostring(exp)):eq("(+ 1 (* 2 3))")
    end)

    test("1+2*3 - different precedence", function()
      parser:parse("1 + 2 * 3")
      exp = parser:nextExp()
      assert(tostring(exp)):eq("(+ 1 (* 2 3))")
    end)

    test("1*2+3 - different precedence", function()
      parser:parse("1 * 2 + 3")
      exp = parser:nextExp()
      assert(tostring(exp)):eq("(+ (* 1 2) 3)")
    end)

    test("1+2-3 - same precedence and left assoc", function()
      parser:parse("1 + 2 - 3")
      exp = parser:nextExp()
      assert(tostring(exp)):eq("(- (+ 1 2) 3)")
    end)

    test("a in b", function()
      parser:parse("a in b")
      assert(tostring(parser:nextExp())):eq("(in a b)")
    end)

    test("a not in b", function()
      parser:parse("a not in b")
      assert(tostring(parser:nextExp())):eq("(notin a b)")
    end)

    test("a like b", function()
      parser:parse("a like b")
      assert(tostring(parser:nextExp())):eq("(like a b)")
    end)

    test("a not like b", function()
      parser:parse("a not like b")
      assert(tostring(parser:nextExp())):eq("(notlike a b)")
    end)

    test("a is b", function()
      parser:parse("a is b")
      assert(tostring(parser:nextExp())):eq("(is a b)")
    end)

    test("a is not b", function()
      parser:parse("a is not b")
      assert(tostring(parser:nextExp())):eq("(isnot a b)")
    end)

    suite("indexing", function()
      test("a[b]", function()
        parser:parse("a[b]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(tostring(exp)):eq("([] a b)")
      end)

      test("a[b + c]", function()
        parser:parse("a[b + c]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(tostring(exp)):eq("([] a (+ b c))")
      end)

      test("a + b[c]", function()
        parser:parse("a + b[c]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(tostring(exp)):eq("(+ a ([] b c))")
      end)

      test("a + b[c + d]", function()
        parser:parse("a + b[c + d]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(tostring(exp)):eq("(+ a ([] b (+ c d)))")
      end)

      test("a[b, c]", function()
        parser:parse("a[b, c]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(tostring(exp)):eq("([] a b c)")
      end)

      test("a[b + c, d]", function()
        parser:parse("a[b + c, d]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(tostring(exp)):eq("([] a (+ b c) d)")
      end)

      test("a + b[c, d]", function()
        parser:parse("a + b[c, d]")
        exp = parser:next()
        assert(exp):isTable():has({
          line = 1,
          col = 1,
          type = SentType.EXP
        })
        assert(tostring(exp)):eq("(+ a ([] b c d))")
      end)
    end)
  end)

  ----------
  -- misc --
  ----------
  suite("misc", function()
    test("not .value.includes(val)", function()
      parser:parse("not .value.includes(val)")
      assert(tostring(parser:next())):eq("(not (call (. (. value) includes) val))")
    end)

    test("x and y", function()
      parser:parse("x and y")
      assert(tostring(parser:next())):eq("(and x y)")
    end)

    test("x && y", function()
      parser:parse("x && y")
      assert(tostring(parser:next())):eq("(&& x y)")
    end)

    test("x and not y", function()
      parser:parse("x and not y")
      assert(tostring(parser:next())):eq("(and x (not y))")
    end)
  end)

  test("a=b=c - same precedence and right assoc", function()
    parser:parse("a = b = c")
    exp = parser:nextExp()
    assert(tostring(exp)):eq("(= a (= b c))")
  end)

  suite("(Exp)", function()
    test("(1 + 2 * 3)", function()
      parser:parse("(1 + 2 * 3)")
      exp = parser:nextExp()
      assert(tostring(exp)):eq("(+ 1 (* 2 3))")
    end)

    test("(1 + 2 * 3 - error - missing last )", function()
      parser:parse("(1 + 2 * 3")
      assert(function()
        parser:nextExp()
      end):raises("')' expected on (1, 11).")
    end)

    test("(1 + 2 * 3 a - error", function()
      parser:parse("(1 + 2 * 3 a")
      assert(function()
        parser:nextExp()
      end):raises("on (1,12), invalid terminal node for well-formed expression.")
    end)
  end)

  test("1 + 2\\n*3", function()
    parser:parse("1 + 2\n* 3")
    assert(tostring(parser:nextExp())):eq("(+ 1 2)")
  end)

  test("1 + 2 -\\n3", function()
    parser:parse("1 + 2 -\n3")
    assert(tostring(parser:nextExp())):eq("(- (+ 1 2) 3)")
  end)

  test("1 + 2 -\\n - error", function()
    parser:parse("1 + 2 -\n")
    assert(function()
      parser:nextExp()
    end):raises("incomplete expression started on (1, 1).")
  end)

  ----------
  -- call --
  ----------
  suite("call", function()
    test("a()", function()
      parser:parse("a()")
      assert(tostring(parser:nextExp())):eq("(call a)")
    end)

    test(".a()", function()
      parser:parse(".a()")
      assert(tostring(parser:next())):eq("(call (. a))")
    end)

    test("a(b)", function()
      parser:parse("a(b)")
      assert(tostring(parser:nextExp())):eq("(call a b)")
    end)

    test("a(b\\n) - error - comma expected", function()
      parser:parse("a(b\n)")
      assert(function()
        parser:nextExp()
      end):raises("on (1, 4), comma expected for argument end or ) for call end.")
    end)

    test("a(\\nb,c) - error - end of line expected", function()
      parser:parse("a(\nb,c)")
      assert(function() parser:next() end):raises("on (2, 2), end of line expected for argument end.")
    end)

    test("a(b,c)", function()
      parser:parse("a(b, c)")
      assert(tostring(parser:nextExp())):eq("(call a b c)")
    end)

    test("a(\\nb\\n)", function()
      parser:parse("a(\nb\n)")
      assert(tostring(parser:nextExp())):eq("(call a b)")
    end)

    test("a(\\nb)", function()
      parser:parse("a(\nb)")
      assert(tostring(parser:nextExp())):eq("(call a b)")
    end)

    test("a(\\nb\\nc\\n)", function()
      parser:parse("a(\nb\nc\n)")
      assert(tostring(parser:nextExp())):eq("(call a b c)")
    end)

    test("a(\\nb\\nc)", function()
      parser:parse("a(\nb\nc)")
      assert(tostring(parser:nextExp())):eq("(call a b c)")
    end)

    test("a+b()", function()
      parser:parse("a + b()")
      assert(tostring(parser:nextExp())):eq("(+ a (call b))")
    end)

    test("a+b(c)", function()
      parser:parse("a + b(c)")
      assert(tostring(parser:nextExp())):eq("(+ a (call b c))")
    end)

    test("a+b()+c", function()
      parser:parse("a + b() + c")
      assert(tostring(parser:nextExp())):eq("(+ (+ a (call b)) c)")
    end)

    test("a+b()*c", function()
      parser:parse("a + b() * c")
      assert(tostring(parser:nextExp())):eq("(+ a (* (call b) c))")
    end)

    test("a+b()*c+d", function()
      parser:parse("a + b() * c + d")
      assert(tostring(parser:nextExp())):eq("(+ (+ a (* (call b) c)) d)")
    end)
  end)

  --------------
  -- native() --
  --------------
  suite("native()", function()
    test("native(Literal)", function()
      parser:parse('native("new Proxy(target, handler)")')
      assert(tostring(parser:next())):eq('(native "new Proxy(target, handler)")')
    end)

    test("native() - error", function()
      parser:parse("native()")
      assert(function() parser:next() end):raises("literal expected on (1, 8).")
    end)
  end):tags("native")

  -------------
  -- peval() --
  -------------
  suite("peval()", function()
    test("peval(Exp)", function()
      parser:parse("peval(1+2)")
      assert(tostring(parser:next())):eq("(peval (+ 1 2))")
    end)

    test("peval() - error", function()
      parser:parse("peval()")
      assert(function() parser:next() end):raises("invalid expression node on (1, 7).")
    end)

    test("peval(1+2 - error", function()
      parser:parse("peval(1+2")
      assert(function() parser:next() end):raises("')' expected on (1, 10).")
    end)
  end)

  -------------
  -- throw() --
  -------------
  suite("throw()", function()
    test("throw(Exp)", function()
      parser:parse("throw(1+2)")
      assert(tostring(parser:next())):eq("(throw (+ 1 2))")
    end)

    test("throw(Exp, Exp)", function()
      parser:parse("throw(1+2, 3+4)")
      assert(tostring(parser:next())):eq("(throw (+ 1 2) (+ 3 4))")
    end)

    test("throw(Exp, Exp, Exp)", function()
      parser:parse("throw(1+2, 3+4, 5+6)")
      assert(tostring(parser:next())):eq("(throw (+ 1 2) (+ 3 4) (+ 5 6))")
    end)
  end):tags("throw")
end):tags("exp")
