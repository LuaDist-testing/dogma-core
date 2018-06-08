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
      assert(trans:next()):eq("let [x, y] = dogma.getArrayToUnpack((1+2), 2);\n")
    end)

    test("export var [Name, Name] = Exp", function()
      parser:parse("export var [x, y] = 1+2")
      assert(trans:next()):eq("export default let [x, y] = dogma.getArrayToUnpack((1+2), 2);\n")
    end)

    test("pub var [Name, Name] = Exp", function()
      parser:parse("pub var [x, y] = 1+2")
      assert(trans:next()):eq("export let [x, y] = dogma.getArrayToUnpack((1+2), 2);\n")
    end)

    test("const [Name, Name] = Exp", function()
      parser:parse("const [x, y] = 1+2")
      assert(trans:next()):eq("const [x, y] = dogma.getArrayToUnpack((1+2), 2);\n")
    end)

    test("export const [Name, Name] = Exp", function()
      parser:parse("export const [x, y] = 1+2")
      assert(trans:next()):eq("export default const [x, y] = dogma.getArrayToUnpack((1+2), 2);\n")
    end)

    test("pub const [Name, Name] = Exp", function()
      parser:parse("pub const [x, y] = 1+2")
      assert(trans:next()):eq("export const [x, y] = dogma.getArrayToUnpack((1+2), 2);\n")
    end)

    test("[Name] = Exp", function()
      parser:parse("[x] = 1+2")
      assert(trans:next()):eq("[x] = dogma.getArrayToUnpack((1+2), 1);\n")
    end)

    test("[Name, Name] = Exp", function()
      parser:parse("[x, y] = 1+2")
      assert(trans:next()):eq("[x, y] = dogma.getArrayToUnpack((1+2), 2);\n")
    end)

    test("[.Name, :Name, Name, Name.Name, Name:Name] = Exp", function()
      parser:parse("[.a, :b, c, d.e, f:g] = arr")
      assert(trans:next()):eq("[this.a, this._b, c, d.e, f._g] = dogma.getArrayToUnpack(arr, 5);\n")
    end)

    test("[.Name, :Name, Name, Name.Name, Name:Name] ?= Exp", function()
      parser:parse("[.a, :b, c, d.e, f:g] ?= arr")
      assert(trans:next()):like("const $aux%d+ = dogma.getArrayToUnpack%(arr, 5%);%[this.a, this._b, c, d.e, f._g%] = %[this.a != null %? this.a : $aux%d+%[0%], this._b != null %? this._b : $aux%d+%[1%], c != null %? c : $aux%d+%[2%], d.e != null %? d.e : $aux%d+%[3%], f._g != null %? f._g : $aux%d+%[4%]%];\n")
    end)

    test("[Name = Exp, Name, Name = Exp] = Exp", function()
      parser:parse("[x = 1, y, z = 3] = 1+2")
      assert(trans:next()):eq("[x = 1, y, z = 3] = dogma.getArrayToUnpack((1+2), 3);\n")
    end)

    test("[Name, ...Name] = Exp", function()
      parser:parse("[x, ...y] = 1+2")
      assert(trans:next()):eq("[x, ...y] = dogma.getArrayToUnpack((1+2), 2);\n")
    end)

    test("[.Name, :Name, Name, Name.Name, Name:Name] := Exp", function()
      parser:parse("[.a, :b, c, d.e, f:g] := arr")
      assert(trans:next()):like(
        'const $aux%d+ = dogma.getArrayToUnpack%(arr, 5%);Object.defineProperty%(this, "a", {value: $aux%d+%[0%], enum: true}%);Object.defineProperty%(this, "_b", {value: $aux%d+%[1%]}%);c = $aux%d+%[2%];d.e = $aux%d+%[3%];f._g = $aux%d+%[4%];\n'
      )
    end)

    test("[:Name, :Name] .= Exp", function()
      parser:parse("[:a, :b] .= arr")
      assert(trans:next()):like(
        'const $aux%d+ = dogma.getArrayToUnpack%(arr, 2%);Object.defineProperty%(this, "_a", {value: $aux%d+%[0%], writable: true}%);Object.defineProperty%(this, "a", {enum: true, get%(%) { return this._a; }}%);Object.defineProperty%(this, "_b", {value: $aux%d+%[1%], writable: true}%);Object.defineProperty%(this, "b", {enum: true, get%(%) { return this._b; }}%);\n'
      )
    end)

    test("[Name, Name] .= Exp", function()
      parser:parse("[a, b] .= arr")
      assert(trans:next()):like(
        'const $aux%d+ = dogma.getArrayToUnpack%(arr, 2%);Object.defineProperty%(this, "_a", {value: $aux%d+%[0%], writable: true}%);Object.defineProperty%(this, "a", {enum: true, get%(%) { return this._a; }}%);Object.defineProperty%(this, "_b", {value: $aux%d+%[1%], writable: true}%);Object.defineProperty%(this, "b", {enum: true, get%(%) { return this._b; }}%);\n'
      )
    end)

    test("[Name:Name, Name:Name] .= Exp", function()
      parser:parse("[a:x, b:y] .= arr")
      assert(trans:next()):like(
        'const $aux%d+ = dogma.getArrayToUnpack%(arr, 2%);Object.defineProperty%(a, "_x", {value: $aux%d+%[0%], writable: true}%);Object.defineProperty%(a, "x", {enum: true, get%(%) { return a._x; }}%);Object.defineProperty%(b, "_y", {value: $aux%d+%[1%], writable: true}%);Object.defineProperty%(b, "y", {enum: true, get%(%) { return b._y; }}%);\n'
      )
    end)
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

    test("{.Name, :Name, Name} = Exp", function()
      parser:parse("{.a, :b, c} = 1+2")
      assert(trans:next()):eq("({a: this.a, b: this._b, c: c} = (1+2));\n")
    end)

    test("{Name = Exp, Name, Name = Exp} = Exp", function()
      parser:parse("{x = 1, y, z = 3} = 1+2")
      assert(trans:next()):eq("({x: x = 1, y: y, z: z = 3} = (1+2));\n")
    end)

    test("{.Name, :Name, Name} := Exp", function()
      parser:parse("{.a, :b, c} := obj")
      assert(trans:next()):like(
        'const $aux%d+ = obj;Object.defineProperty%(this, "a", {value: $aux%d+%["a"%], enum: true}%);Object.defineProperty%(this, "_b", {value: $aux%d+%["b"%]}%);c = %$aux%d+%["c"%];\n'
      )
    end)
  end)
end):tags("unpack")
