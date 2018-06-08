--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Parser = require("dogma.syn.Parser")

--Suite.
return suite("dogma.syn.Parser", function()
  local parser

  init("*", function()
    parser = Parser.new()
  end):title("Create parser")

  ----------
  -- misc --
  ----------
  suite("misc", function()
    test("export if - error", function()
      parser:parse("export if (x == 7) x += 1")
      assert(function() parser:next() end):raises("invalid export/pub on (1, 8).")
    end)
  end)

  ------------
  -- next() --
  ------------
  suite("next()", function()
    test("Exp", function()
      parser:parse("1+2")
      assert(parser:next():__tostring()):eq("(+ 1 2)")
      assert(parser:next()):isNil()
    end)

    test("Exp\\nExp", function()
      parser:parse("1+2\n3*4")
      assert(parser:next():__tostring()):eq("(+ 1 2)")
      assert(parser:next():__tostring()):eq("(* 3 4)")
      assert(parser:next()):isNil()
    end)

    test("Exp\\nExp\\n", function()
      parser:parse("1+2\n3*4\n5/6")
      assert(parser:next():__tostring()):eq("(+ 1 2)")
      assert(parser:next():__tostring()):eq("(* 3 4)")
      assert(parser:next():__tostring()):eq("(/ 5 6)")
      assert(parser:next()):isNil()
    end)

    test("Exp\\n\\nExp", function()
      parser:parse("1+2\n\n3*4")
      assert(parser:next():__tostring()):eq("(+ 1 2)")
      assert(parser:next():__tostring()):eq("(* 3 4)")
      assert(parser:next()):isNil()
    end)

    test("Exp\\n\\n\\nExp", function()
      parser:parse("1+2\n\n\n3*4")
      assert(parser:next():__tostring()):eq("(+ 1 2)")
      assert(parser:next():__tostring()):eq("(* 3 4)")
      assert(parser:next()):isNil()
    end)
  end)
end)
