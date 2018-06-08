--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Trans = require("dogma.trans.js.Trans")
local Parser = require("dogma.syn.Parser")

--Suite.
return suite("dogma.trans.js._.DirectiveTrans", function()
  local trans, parser

  ----------
  -- init --
  ----------
  init("*", function()
    parser = Parser.new()
    trans = Trans.new()
    trans:transform(parser)
  end):title("Create transformer")

  --------
  -- if --
  --------
  suite("if", function()
    test("if js then - with else", function()
      parser:parse([[
#!if js then
print("ok!")
#!else
print("wrong!")
#!end
]])
      assert(trans:next()):eq('print("ok!")\n')
    end)

    test("if not js then - without else", function()
      parser:parse([[
#!if not js then
print("wrong!")
#!end
]])
      assert(trans:next()):eq("\n")
    end)

    test("if not js then - with else", function()
      parser:parse([[
#!if not js then
print("wrong!")
#!else
print("ok!")
#!end
]])
      assert(trans:next()):eq('print("ok!")\n')
    end)

    test("if js then - without else", function()
      parser:parse([[
#!if js then
print("ok!")
#!end
]])
      assert(trans:next()):eq('print("ok!")\n')
    end)

    test("if py then - with else", function()
      parser:parse([[
#!if py then
print("wrong!")
#!else
print("ok!")
#!end
]])
      assert(trans:next()):eq('print("ok!")\n')
    end)

    test("if py then - without else", function()
      parser:parse([[
#!if py then
print("wrong!")
#!end
]])
      assert(trans:next()):eq("\n")
    end)

    test("if not py then - with else", function()
      parser:parse([[
#!if not py then
print("ok!")
#!else
print("wrong!")
#!end
]])
      assert(trans:next()):eq('print("ok!")\n')
    end)

    test("if not py then - without else", function()
      parser:parse([[
#!if not py then
print("ok!")
#!end
]])
      assert(trans:next()):eq('print("ok!")\n')
    end)
  end)

  -------------
  -- runWith --
  -------------
  suite("runWith", function()
    test("/usr/bin/env node", function()
      parser:parse("#!/usr/bin/env node")
      assert(trans:next()):eq('#!/usr/bin/env node\n')
    end)
  end)
end):tags("directive")
