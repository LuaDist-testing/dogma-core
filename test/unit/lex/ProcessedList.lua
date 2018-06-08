--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local List = require("dogma.lex._.ProcessedList")

--Suite.
return suite("dogma.lex._.ProcessedList", function()
  -----------------
  -- constructor --
  -----------------
  suite("constructor()", function()
    test("constructor() - error - max expected", function()
      assert(function() List.new() end):raises("max expected.")
    end)

    test("constructor(max) - ok", function()
      assert(List.new(123)):has({
        _ = {
          max = 123,
          items = {}
        }
      })
    end)
  end)

  --------------
  -- insert() --
  --------------
  suite("insert()", function()
    local list

    init("*", function()
      list = List.new(2)
    end):title("Create list")

    test("insert(item) - once", function()
      list:insert("one")

      assert(#list):eq(1)
      assert(list._):has({
        max = 2,
        items = {"one"}
      })
    end)

    test("insert(item) - twice", function()
      list:insert("one")
      list:insert("two")

      assert(#list):eq(2)
      assert(list._):has({
        max = 2,
        items = {"one", "two"}
      })
    end)

    test("insert(item) - three times", function()
      list:insert("one")
      list:insert("two")
      list:insert("three")

      assert(#list):eq(2)
      assert(list._):has({
        max = 2,
        items = {"two", "three"}
      })
    end)
  end)

  --------------
  -- remove() --
  --------------
  suite("remove()", function()
    local list

    init("*", function()
      list = List.new(2)
      list:insert("one")
      list:insert("two")
    end):title("Create list with items")

    test("remove() - once", function()
      assert(list:remove()):eq("two")
      assert(#list):eq(1)
      assert(list._):has({
        max = 2,
        items = {"one"}
      })
    end)

    test("remove() - twice", function()
      assert(list:remove()):eq("two")
      assert(list:remove()):eq("one")
      assert(list):isEmpty()
      assert(list._):has({
        max = 2,
        items = {}
      })
    end)

    test("remove() - three times", function()
      assert(list:remove()):eq("two")
      assert(list:remove()):eq("one")
      assert(function() list:remove() end):raises("internal error: invalid remove from previous list.")
      assert(list):isEmpty()
      assert(list._):has({
        max = 2,
        items = {}
      })
    end)
  end)
end):tags("lexer")
