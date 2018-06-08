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
    test("[.Name, :Name, Name, Name.Name, Name:Name ...Name] = Exp", function()
      parser:parse("[.a, :b, c, d.e, f:g, ...h] = func()")
      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        subtype = "[]",
        assign = "=",
        vars = {
          {mod = ".", name = "a", value = nil},
          {mod = ":", name = "b", value = nil},
          {mod = nil, name = "c", value = nil},
          {mod = nil, name = "d.e", value = nil},
          {mod = nil, name = "f:g", value = nil},
          {mod = "...", name = "h", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("[.Name, :Name, Name, ...Name] := Exp", function()
      parser:parse("[.a, :b, c, ...d] := func()")
      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "[]",
        assign = ":=",
        vars = {
          {mod = ".", name = "a", value = nil},
          {mod = ":", name = "b", value = nil},
          {mod = nil, name = "c", value = nil},
          {mod = "...", name = "d", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("[.Name, :Name, Name, ...Name] ?= Exp", function()
      parser:parse("[.a, :b, c, ...d] ?= func()")
      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "[]",
        assign = "?=",
        vars = {
          {mod = ".", name = "a", value = nil},
          {mod = ":", name = "b", value = nil},
          {mod = nil, name = "c", value = nil},
          {mod = "...", name = "d", value = nil}
        }
      })
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("[.Name, :Name, Name, ...Name] .= Exp", function()
      parser:parse("[.a, :b, c, ...d] .= func()")
      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "[]",
        assign = ".=",
        vars = {
          {mod = ".", name = "a", value = nil},
          {mod = ":", name = "b", value = nil},
          {mod = nil, name = "c", value = nil},
          {mod = "...", name = "d", value = nil}
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
        subtype = "[]"
      })
      assert(sent.vars):len(3)
      assert(sent.vars[1]):has({mod = nil, name = "a"})
      assert(sent.vars[1].value:__tostring()):eq("1")
      assert(sent.vars[2]):has({mod = nil, name = "b", value = nil})
      assert(sent.vars[3]):has({mod = nil, name = "c"})
      assert(sent.vars[3].value:__tostring()):eq("3")
      assert(sent.exp:__tostring()):eq("(call func)")
    end)

    test("[Name, Name] ; Exp - error", function()
      parser:parse("[x, ...y] ; 1+2")
      assert(function() parser:next() end):raises("on (1,11), '=', '%.=', ':=' or '%?=' expected.")
    end)

    test("[Name{Name}] = Exp", function()
      parser:parse("[opts{host}] = arr")
      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "[]"
      })
      assert(sent.vars):len(1)
      assert(sent.vars[1]):has({mod = nil, name = "opts.host", value = nil})
      assert(sent.exp:__tostring()):eq("arr")
    end)

    test("[Name{Name,:Name}] = Exp", function()
      parser:parse("[opts{host,:port}] = arr")
      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "[]"
      })
      assert(sent.vars):len(2)
      assert(sent.vars[1]):has({mod = nil, name = "opts.host", value = nil})
      assert(sent.vars[2]):has({mod = nil, name = "opts:port", value = nil})
      assert(sent.exp:__tostring()):eq("arr")
    end)

    test("[Name{Name,Name}, Name] = Exp", function()
      parser:parse("[opts{host,port}, db] = arr")
      sent = parser:next()
      assert(sent):isTable():has({
        line = 1,
        col = 1,
        type = SentType.UNPACK,
        visib = nil,
        def = nil,
        subtype = "[]"
      })
      assert(sent.vars):len(3)
      assert(sent.vars[1]):has({mod = nil, name = "opts.host", value = nil})
      assert(sent.vars[2]):has({mod = nil, name = "opts.port", value = nil})
      assert(sent.vars[3]):has({mod = nil, name = "db", value = nil})
      assert(sent.exp:__tostring()):eq("arr")
    end)
  end)

  ---------
  -- map --
  ---------
  suite("map", function()
    test("{Name, Name} ; Exp - error", function()
      parser:parse("{x, y} ; 1+2")
      assert(function() parser:next() end):raises("on (1,8), '=' or ':=' expected.")
    end)

    test("{Name, Name, ...Name} ; Exp - error", function()
      parser:parse("{x, y, ...z} = obj")
      assert(function() parser:next() end):raises("on (1,8), '...' only allowed with list unpack.")
    end)

    test("{Name{...}} = Exp - error", function()
      parser:parse("{opts{host,port}} = obj")
      assert(function() parser:next() end):raises("on (1,6), 'object{}' only allowed with list unpack.")
    end)
  end)
end):tags("unpack")
