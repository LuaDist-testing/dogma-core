--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test = justo.suite, justo.test
local Trans = require("dogma.trans.Trans")

--Suite.
return suite("Trans", function()
  ------------
  -- next() --
  ------------
  test("next() - abstract method", function()
    assert(function() Trans.new():next() end):raises("abstract method.")
  end)
end)
