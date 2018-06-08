--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Parser = require("dogma.syn.Parser")
local SentType = require("dogma.syn.SentType")

--Suite.
return suite("dogma.syn.UnpackParser", function()
  local parser, sent

  ----------
  -- init --
  ----------
  init("*", function()
    parser = Parser.new()
  end):title("Create parser")

  ----------
  -- list --
  ----------
  suite("list", function()
    test("export var [Name, Name, Name] = Exp", function()
      parser:parse("export var [a, b, c] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = "export",
        def = "var",
        subtype = "[]",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("pub var [Name, Name, Name] = Exp", function()
      parser:parse("pub var [a, b, c] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = "pub",
        def = "var",
        subtype = "[]",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("var [Name, Name, Name] = Exp", function()
      parser:parse("var [a, b, c] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = "var",
        subtype = "[]",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("var [$Name, :Name, Name] = Exp", function()
      parser:parse("var [$a, :b, c] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = "var",
        subtype = "[]",
        vars = {
          {rest = false, name = "$a", value = nil},
          {rest = false, name = ":b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("const [Name, Name, Name] = Exp", function()
      parser:parse("const [a, b, c] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = "const",
        subtype = "[]",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("export const [Name, Name, Name] = Exp", function()
      parser:parse("export const [a, b, c] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = "export",
        def = "const",
        subtype = "[]",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("pub const [Name, Name, Name] = Exp", function()
      parser:parse("pub const [a, b, c] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = "pub",
        def = "const",
        subtype = "[]",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("[Name, Name, Name] = Exp", function()
      parser:parse("[a, b, c] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "[]",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("[Name, Name, ...Name] = Exp", function()
      parser:parse("[a, b, ...c] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "[]",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = true, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("[Name = Exp, Name, Name = Exp] = Exp", function()
      parser:parse("[a = 1, b, c = 3] = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "[]",
      })
      assert(sent.vars):len(3)
      assert(sent.vars[1]):has({rest = false, name = "a"})
      assert(sent.vars[1].value:__tostring()):eq("1")
      assert(sent.vars[2]):has({rest = false, name = "b", value = nil})
      assert(sent.vars[3]):has({rest = false, name = "c"})
      assert(sent.vars[3].value:__tostring()):eq("3")
      assert(sent.exp:__tostring()):eq("(call func)")
    end)
  end)

  ---------
  -- map --
  ---------
  suite("map", function()
    test("export var {Name, Name, Name} = Exp", function()
      parser:parse("export var {a, b, c} = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = "export",
        def = "var",
        subtype = "{}",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("pub var {Name, Name, Name} = Exp", function()
      parser:parse("pub var {a, b, c} = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = "pub",
        def = "var",
        subtype = "{}",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("var {Name, Name, Name} = Exp", function()
      parser:parse("var {a, b, c} = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = "var",
        subtype = "{}",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("{Name, Name, Name} = Exp", function()
      parser:parse("{a, b, c} = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "{}",
        vars = {
          {rest = false, name = "a", value = nil},
          {rest = false, name = "b", value = nil},
          {rest = false, name = "c", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("{Name = Exp, Name, Name = Exp} = Exp", function()
      parser:parse("{a = 1, b, c = 3} = func()")

      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "{}",
      })
      assert(sent.vars):len(3)
      assert(sent.vars[1]):has({rest = false, name = "a"})
      assert(sent.vars[1].value:__tostring()):eq("1")
      assert(sent.vars[2]):has({rest = false, name = "b", value = nil})
      assert(sent.vars[3]):has({rest = false, name = "c"})
      assert(sent.vars[3].value:__tostring()):eq("3")
      assert(sent.exp:__tostring()):eq("(call func)")
    end)
  end)
end):tags("unpack")
