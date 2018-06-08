--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Parser = require("dogma.syn.Parser")
local SentType = require("dogma.syn.SentType")
local DirectiveType = require("dogma.syn.DirectiveType")

--Suite.
return suite("dogma.syn.DirectiveParser", function()
  local parser, dir

  ----------
  -- init --
  ----------
  init("*", function()
    parser = Parser.new()
  end):title("Create parser")

  --------------
  -- nextIf() --
  --------------
  suite("nextIf()", function()
    test("#!if name then - without else", function()
      parser:parse([[
#!if py then
print("one!")
print("two!")
#!end
]])
      dir = parser:next()
      assert(dir):isTable():has({
        line = 1,
        col = 1,
        type = SentType.DIRECTIVE,
        subtype = DirectiveType.IF,
        cond = "py",
        el = nil
      })
      assert(dir.body):len(2)
      assert(tostring(dir.body[1])):eq("(call print one!)")
      assert(tostring(dir.body[2])):eq("(call print two!)")
    end)

    test("#!if not name then - without else", function()
      parser:parse([[
#!if not py then
print("one!")
print("two!")
#!end
]])
      dir = parser:next()
      assert(dir):isTable():has({
        line = 1,
        col = 1,
        type = SentType.DIRECTIVE,
        subtype = DirectiveType.IF,
        cond = "not py",
        el = nil
      })
      assert(dir.body):len(2)
      assert(tostring(dir.body[1])):eq("(call print one!)")
      assert(tostring(dir.body[2])):eq("(call print two!)")
    end)

    test("#!if name then - without end", function()
      parser:parse([[
#!if py then
print("one!")
print("two!")
]])
      assert(function() parser:next() end):raises("'end' expected at the end of code.")
    end)

    test("#!if name then - with else", function()
      parser:parse([[
#!if py then
print("one!")
print("two!")
#!else
print("three!")
print("four!")
#!end
]])
      dir = parser:next()
      assert(dir):isTable():has({
        line = 1,
        col = 1,
        type = SentType.DIRECTIVE,
        subtype = DirectiveType.IF,
        cond = "py"
      })
      assert(dir.body):len(2)
      assert(tostring(dir.body[1])):eq("(call print one!)")
      assert(tostring(dir.body[2])):eq("(call print two!)")
      assert(dir.el):len(2)
      assert(tostring(dir.el[1])):eq("(call print three!)")
      assert(tostring(dir.el[2])):eq("(call print four!)")
    end)

    test("#!if name then - error - nested directive", function()
      parser:parse([[
#!if py then
print("one!")
print("two!")
#!if py then
print("three!")
print("four!")
#!end
#!end
]])
      assert(function() parser:next() end):raises("on (4,1), if directive can't be nested.")
    end)

    test("#!if name then - error - nested else", function()
      parser:parse([[
#!if py then
print("one!")
print("two!")
#!else
#!if py then
print("three!")
print("four!")
#!end
#!end
]])
      assert(function() parser:next() end):raises("on (5,1), else directive can't be nested.")
    end):tags("123")
  end)

  -------------------
  -- nextRunWith() --
  -------------------
  suite("nextRunWith()", function()
    test("#!/usr/bin/env node", function()
      parser:parse("#!/usr/bin/env node")
      dir = parser:next()
      assert(dir):isTable():has({
        line = 1,
        col = 1,
        type = SentType.DIRECTIVE,
        subtype = DirectiveType.RUNWITH,
        cmd = "/usr/bin/env node"
      })
    end)
  end)
end):tags("directive")
