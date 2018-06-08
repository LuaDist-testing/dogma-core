--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test = justo.suite, justo.test
local CallOp = require("dogma.syn._.CallOp")

--Suite.
return suite("dogma.syn._.CallOp", function()
  test("insert()", function()
    assert(function()
      local op = CallOp.new({line = 1, col = 2, value = "()"})
      op.finished = true
      op:insert({tok = {line = 123, col = 456}})
    end):raises("(123,456): node can't be inserted to full call.")
  end)

  test("remove()", function()
    assert(function()
      CallOp.new({line = 1, col = 2, value = "()"}):remove()
    end):raises("call operator can't remove children.")
  end)
end)
