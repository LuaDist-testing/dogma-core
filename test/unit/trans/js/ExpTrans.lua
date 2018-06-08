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
        parser:parse("class")
        assert(trans:next()):eq("class_;\n")
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

    suite("text", function()
      test('"text"', function()
        parser:parse('"text"')
        assert(trans:next()):eq('"text";\n')
      end)

      test('"text" - with new lines', function()
        parser:parse('"text1\ntext2"')
        assert(trans:next()):eq('"text1\\ntext2";\n')
      end)
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

      test("{Name = Exp, Name, {Name} = Exp}", function()
        parser:parse("a + {x = 1+2, y, {z} = obj}")
        assert(trans:next()):eq('(a+{["x"]: (1+2), ["y"]: y, ["z"]: obj.z});\n')
      end)
    end):tags("map")

    suite("fn", function()
      test("fn() end", function()
        parser:parse("a + fn() end")
        assert(trans:next()):eq("(a+(() => { {} }));\n")
      end)

      test("fn(Name) end", function()
        parser:parse("a + fn(x) end")
        assert(trans:next()):eq('(a+((x) => { dogma.paramExpected("x", x, null);{} }));\n')
      end)

      test("fn(Name) -> Name end", function()
        parser:parse("a + fn(x) -> x end")
        assert(trans:next()):eq('(a+((x) => { dogma.paramExpected("x", x, null);{} return x; }));\n')
      end)

      test("fn(Name?) end", function()
        parser:parse("a + fn(x?) end")
        assert(trans:next()):eq("(a+((x) => { {} }));\n")
      end)

      test("fn(Name : num) end", function()
        parser:parse("a + fn(x:num) end")
        assert(trans:next()):eq('(a+((x) => { dogma.paramExpected("x", x, num);{} }));\n')
      end)

      test("fn(Name ? : num) end", function()
        parser:parse("a + fn(x?:num) end")
        assert(trans:next()):eq('(a+((x) => { dogma.paramExpectedToBe("x", x, num);{} }));\n')
      end)

      test("fn(Name, Name) = Exp end", function()
        parser:parse("a + fn(x, y) = x - y end")
        assert(trans:next()):eq('(a+((x, y) => { dogma.paramExpected("x", x, null);dogma.paramExpected("y", y, null);{return (x-y);} }));\n')
      end)
    end)

    test("native(literal)", function()
      parser:parse('x = native("new Proxy(target, handler)")')
      assert(trans:next()):eq("(x=new Proxy(target, handler));\n")
    end):tags("native")

    test("await(Exp)", function()
      parser:parse("x = await(1+2)")
      assert(trans:next()):eq("(x=await((1+2)));\n")
    end):tags("await")

    test("pawait(Exp)", function()
      parser:parse("l = pawait(setTimeout(done, 750, 750))")
      assert(trans:next()):eq("(l=dogma.pawait((done) => {setTimeout(done, 750, 750);}));\n")
    end):tags("pawait")

    test("use(Exp)", function()
      parser:parse('l = use("path")')
      assert(trans:next()):eq('(l=dogma.use(require("path")));\n')
    end):tags("use")

    test("peval(Exp)", function()
      parser:parse("x = peval(1+2)")
      assert(trans:next()):eq("(x=dogma.peval(() => {return (1+2);}));\n")
    end)

    suite("iif()", function()
      test("iif(Exp, Exp)", function()
        parser:parse("iif(123+456, abc+def)")
        assert(trans:next()):eq("((123+456) ? (abc+def) : null);\n")
      end)

      test("iif(Exp, Exp, Exp)", function()
        parser:parse("iif(123+456, abc+def, 135+246)")
        assert(trans:next()):eq("((123+456) ? (abc+def) : (135+246));\n")
      end)
    end):tags("iif")

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

      test("if..then..end", function()
        parser:parse([[(if x then x+1 end) + 3]])
        assert(trans:next()):eq("((x ? (x+1) : null)+3);\n")
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
      test("<<<", function()
        parser:parse("<<<args")
        assert(trans:next()):eq("dogma.lshift(args);\n")
      end)

      test(">>>", function()
        parser:parse(">>>args")
        assert(trans:next()):eq("dogma.rshift(args);\n")
      end)

      test("...", function()
        parser:parse("...args")
        assert(trans:next()):eq("...(args);\n")
      end)

      test(". Name", function()
        parser:parse(".x")
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

      test("=~", function()
        parser:parse("status =~ FAILED")
        assert(trans:next()):eq('dogma.enumEq(status, "FAILED");\n')
      end)

      test("!~", function()
        parser:parse("status !~ FAILED")
        assert(trans:next()):eq('(!dogma.enumEq(status, "FAILED"));\n')
      end)

      suite("?=", function()
        test("Name ?= Exp", function()
          parser:parse("x ?= 123")
          assert(trans:next()):eq("(x = coalesce(x, 123));\n")
        end)

        test("Name.Name ?= Exp", function()
          parser:parse("x.y ?= 123")
          assert(trans:next()):eq("(x.y = coalesce(x.y, 123));\n")
        end)

        test("Name:Name ?= Exp", function()
          parser:parse("x:y ?= 123")
          assert(trans:next()):eq("(x._y = coalesce(x._y, 123));\n")
        end)

        test("Name[Ix] ?= Exp", function()
          parser:parse("x[y] ?= 123")
          assert(trans:next()):eq('dogma.setItem("=", x, y, coalesce(dogma.getItem(x, y), 123));\n')
        end)
      end)

      suite(":=", function()
        test(".Name := Exp", function()
          parser:parse(".x := 123")
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
          assert(trans:next()):eq('Object.defineProperty(this, "_x", {value: 123, writable: true});Object.defineProperty(this, "x", {enum: true, get() { return this._x; }});\n')
        end)
      end)

      test(">>>", function()
        parser:parse("x >>> y")
        assert(trans:next()):eq("dogma.rshift(x, y);\n")
      end)

      test("<<<", function()
        parser:parse("x <<< y")
        assert(trans:next()):eq("dogma.lshift(x, y);\n")
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

        test("super.method()", function()
          parser:parse("super.m()")
          assert(trans:next()):eq('dogma.super(this, "m")();\n')
        end)

        test("write", function()
          parser:parse("x.y=z")
          assert(trans:next()):eq("(x.y=z);\n")
        end)
      end)

      test("?", function()
        parser:parse("x?y")
        assert(trans:next()):eq("(x != null ? x.y : null);\n")
      end)

      suite(":", function()
        test("super:method()", function()
          parser:parse("super:m()")
          assert(trans:next()):eq('dogma.super(this, "_m")();\n')
        end)

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
          assert(trans:next()):eq("dogma.includes(array, x);\n")
        end)

        test("not in", function()
          parser:parse("x not in array")
          assert(trans:next()):eq("!dogma.includes(array, x);\n")
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
  -- pack --
  ----------
  suite("pack", function()
    test("pack{*}", function()
      parser:parse("x{*}")
      assert(trans:next()):eq("dogma.clone(x);\n")
    end)

    test("pack{*,f1=val1}", function()
      parser:parse("x{*,f1=1+2}")
      assert(trans:next()):eq('dogma.clone(x, {"f1": (1+2)});\n')
    end)

    test("pack{*,f1=val1,f2=val2}", function()
      parser:parse("x{*,f1=val1,f2=val2}")
      assert(trans:next()):eq('dogma.clone(x, {"f1": val1, "f2": val2});\n')
    end)

    test("pack{}", function()
      parser:parse("x{}")
      assert(trans:next()):eq("dogma.pack(x);\n")
    end)

    test("pack{name}", function()
      parser:parse("x{name}")
      assert(trans:next()):eq('dogma.pack(x, "name");\n')
    end)

    test("pack{name, name=value}", function()
      parser:parse("x{f1,f2=val}")
      assert(trans:next()):eq('dogma.pack(x, "f1", {name: "f2", value: val});\n')
    end)

    test("pack{name, name=value, name=value}", function()
      parser:parse("x{f1,f2=123,f3=456}")
      assert(trans:next()):eq('dogma.pack(x, "f1", {name: "f2", value: 123}, {name: "f3", value: 456});\n')
    end)

    test("pack{name, .name, :name}", function()
      parser:parse("x{a,.b,:c}")
      assert(trans:next()):eq('dogma.pack(x, "a", "b", "_c");\n')
    end)
  end):tags("pack")

  ------------
  -- update --
  ------------
  suite("update", function()
    test("update.{a}", function()
      parser:parse("x.{a}")
      assert(trans:next()):eq('dogma.update(x, {name: "a", visib: ".", assign: "=", value: a});\n')
    end)

    test("update:{a}", function()
      parser:parse("x:{a}")
      assert(trans:next()):eq('dogma.update(x, {name: "a", visib: ":", assign: "=", value: a});\n')
    end)

    test("update:{{a} = exp}", function()
      parser:parse("x:{{a} = 1+2}")
      assert(trans:next()):eq('dogma.update(x, {name: ["a"], visib: ":", assign: "=", value: (1+2), type: "mapped"});\n')
    end)

    test("update:{{a, b} = exp}", function()
      parser:parse("x:{{a, b} = 1+2}")
      assert(trans:next()):eq('dogma.update(x, {name: ["a", "b"], visib: ":", assign: "=", value: (1+2), type: "mapped"});\n')
    end)

    test("update:{(a, b) = exp}", function()
      parser:parse("x:{(a, b) = 1+2}")
      assert(trans:next()):eq('dogma.update(x, {name: ["a", "b"], visib: ":", assign: "=", value: (1+2), type: "extended"});\n')
    end)

    test("update.{a=exp, b:=exp, c?=exp, d.=exp}", function()
      parser:parse("x.{a=1+2, b:=3+4, c?=5+6, d.=7+8}")
      assert(trans:next()):eq('dogma.update(x, {name: "a", visib: ".", assign: "=", value: (1+2)}, {name: "b", visib: ".", assign: ":=", value: (3+4)}, {name: "c", visib: ".", assign: "?=", value: (5+6)}, {name: "d", visib: ".", assign: ".=", value: (7+8)});\n')
    end)
  end):tags("update")

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
