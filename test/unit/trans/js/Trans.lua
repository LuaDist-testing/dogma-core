--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Trans = require("dogma.trans.js.Trans")
local Parser = require("dogma.syn.Parser")

--Suite.
return suite("dogma.trans.js.Trans", function()
  local trans, parser

  suite("import dogmalang", function()
    init("*", function()
      parser = Parser.new()
      trans = Trans.new()
      trans:transform(parser)
    end):title("Create transformer")

    test("not importing", function()
      parser:parse("var [x, y] = 1+2")
      assert(trans:next()):eq("let [x, y] = dogma.getArrayToUnpack((1+2), 2);\n")
    end)

    test("importing", function()
      parser:parse("var [x, y] = 1+2")
      assert(trans:next({importDogmalang = true})):eq([[
import {any, bool, func, list, map, num, promise, proxy, text, abstract, coalesce, dogma, exec, fmt, keys, len, print, printf, todo, typename} from "dogmalang";
let [x, y] = dogma.getArrayToUnpack((1+2), 2);
]])
    end)

    test("importing with #!runWith as 1st proposition", function()
      parser:parse([[
#!/usr/bin/env node
var [x, y] = 1+2
]])
      assert(trans:next({importDogmalang = true})):eq([[
#!/usr/bin/env node
import {any, bool, func, list, map, num, promise, proxy, text, abstract, coalesce, dogma, exec, fmt, keys, len, print, printf, todo, typename} from "dogmalang";
let [x, y] = dogma.getArrayToUnpack((1+2), 2);
]])
    end)
  end)
end)
