--imports
local assert = require("justo.assert")
local justo = require("justo")
local suite, test, init = justo.suite, justo.test, justo.init
local Trans = require("dogma.trans.js.Trans")
local Parser = require("dogma.syn.Parser")

--Suite.
return suite("dogma.trans.js._.StmtTrans", function()
  local trans, parser

  ----------
  -- init --
  ----------
  init("*", function()
    parser = Parser.new()
    trans = Trans.new()
    trans:transform(parser)
  end):title("Create transformer")

  ----------
  -- list --
  ----------
  suite("list", function()
    test("var [Name, Name] = Exp", function()
      parser:parse("var [x, y] = 1+2")
      assert(trans:next()):eq("let [x, y] = (1+2);\n")
    end)

    test("export var [Name, Name] = Exp", function()
      parser:parse("export var [x, y] = 1+2")
      assert(trans:next()):eq("export default let [x, y] = (1+2);\n")
    end)

    test("pub var [Name, Name] = Exp", function()
      parser:parse("pub var [x, y] = 1+2")
      assert(trans:next()):eq("export let [x, y] = (1+2);\n")
    end)

    test("const [Name, Name] = Exp", function()
      parser:parse("const [x, y] = 1+2")
      assert(trans:next()):eq("const [x, y] = (1+2);\n")
    end)

    test("export const [Name, Name] = Exp", function()
      parser:parse("export const [x, y] = 1+2")
      assert(trans:next()):eq("export default const [x, y] = (1+2);\n")
    end)

    test("pub const [Name, Name] = Exp", function()
      parser:parse("pub const [x, y] = 1+2")
      assert(trans:next()):eq("export const [x, y] = (1+2);\n")
    end)

    test("[Name] = Exp", function()
      parser:parse("[x] = 1+2")
      assert(trans:next()):eq("[x] = (1+2);\n")
    end)

    test("[Name, Name] = Exp", function()
      parser:parse("[x, y] = 1+2")
      assert(trans:next()):eq("[x, y] = (1+2);\n")
    end)

    test("[$Name, .Name, :Name] = Exp", function()
      parser:parse("[$x, .y, :z] = 1+2")
      assert(trans:next()):eq("[this.x, this.y, this._z] = (1+2);\n")
    end):tags("1x2")

    test("[Name = Exp, Name, Name = Exp] = Exp", function()
      parser:parse("[x = 1, y, z = 3] = 1+2")
      assert(trans:next()):eq("[x = 1, y, z = 3] = (1+2);\n")
    end)

    test("[Name, ...Name] = Exp", function()
      parser:parse("[x, ...y] = 1+2")
      assert(trans:next()):eq("[x, ...y] = (1+2);\n")
    end)

    test("[Name, Name] ; Exp", function()
      parser:parse("[x, ...y] ; 1+2")
      assert(function() trans:next() end):raises("on (1,11), = or := expected.")
    end)

    test("[$Name, .Name, :Name, Name] := Exp", function()
      parser:parse("[$x, .y, :z, a] := 1+2")
      assert(trans:next()):like(
        'const %$aux[0-9a-zA-Z]+ = %(1%+2%);Object.defineProperty%(this, "x", {value: $aux[0-9a-zA-Z]+%[0%], enum: true}%);Object.defineProperty%(this, "y", {value: $aux[0-9a-zA-Z]+%[1%], enum: true}%);Object.defineProperty%(this, "_z", {value: $aux[0-9a-zA-Z]+%[2%]}%);a = %$aux[0-9a-zA-Z]+%[3%];\n'
      )
    end):tags("1x2")
  end)

  ---------
  -- map --
  ---------
  suite("map", function()
    test("export var {Name} = Exp", function()
      parser:parse("export var {x} = 1+2")
      assert(trans:next()):eq("export default let {x} = (1+2);\n")
    end)

    test("pub var {Name} = Exp", function()
      parser:parse("pub var {x} = 1+2")
      assert(trans:next()):eq("export let {x} = (1+2);\n")
    end)

    test("var {Name} = Exp", function()
      parser:parse("var {x} = 1+2")
      assert(trans:next()):eq("let {x} = (1+2);\n")
    end)

    test("export const {Name} = Exp", function()
      parser:parse("export const {x} = 1+2")
      assert(trans:next()):eq("export default const {x} = (1+2);\n")
    end)

    test("pub const {Name} = Exp", function()
      parser:parse("pub const {x} = 1+2")
      assert(trans:next()):eq("export const {x} = (1+2);\n")
    end)

    test("const {Name} = Exp", function()
      parser:parse("const {x} = 1+2")
      assert(trans:next()):eq("const {x} = (1+2);\n")
    end)

    test("{Name} = Exp", function()
      parser:parse("{x} = 1+2")
      assert(trans:next()):eq("({x: x} = (1+2));\n")
    end)

    test("{Name, Name} = Exp", function()
      parser:parse("{x, y} = 1+2")
      assert(trans:next()):eq("({x: x, y: y} = (1+2));\n")
    end)

    test("{$Name, .Name, :Name} = Exp", function()
      parser:parse("{$x, .y, :z} = 1+2")
      assert(trans:next()):eq("({x: this.x, y: this.y, z: this._z} = (1+2));\n")
    end):tags("1x2")

    test("{Name = Exp, Name, Name = Exp} = Exp", function()
      parser:parse("{x = 1, y, z = 3} = 1+2")
      assert(trans:next()):eq("({x: x = 1, y: y, z: z = 3} = (1+2));\n")
    end)

    test("{$Name, .Name, :Name, Name} := Exp", function()
      parser:parse("{$x, .y, :z, a} := 1+2")
      assert(trans:next()):like(
        'const %$aux[0-9a-zA-Z]+ = %(1%+2%);Object.defineProperty%(this, "x", {value: $aux[0-9a-zA-Z]+%["x"%], enum: true}%);Object.defineProperty%(this, "y", {value: $aux[0-9a-zA-Z]+%["y"%], enum: true}%);Object.defineProperty%(this, "_z", {value: $aux[0-9a-zA-Z]+%["z"%]}%);a = %$aux[0-9a-zA-Z]+%["a"%];\n'
      )
    end):tags("1x2")
  end)
end):tags("unpack")
