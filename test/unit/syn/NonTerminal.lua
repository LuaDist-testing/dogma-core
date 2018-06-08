--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test = justo.suite, justo.test
local NonTerminal = require("dogma.syn._.NonTerminal")
local NonTerminalType = require("dogma.syn.NonTerminalType")

--Suite.
return suite("dogma.syn._.NonTerminal", function()
  test("insert()", function()
    assert(function()
      NonTerminal.new(NonTerminalType.OP, {line = 1, col = 2}):insert()
    end):raises("abstract node.")
  end)

  test("remove()", function()
    assert(function()
      NonTerminal.new(NonTerminalType.OP, {line = 1, col = 2}):remove()
    end):raises("abstract node.")
  end)
end)
