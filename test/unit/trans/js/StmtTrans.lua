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

  ---------
  -- use --
  ---------
  suite("use", function()
    test("use LiteralStr", function()
      parser:parse([[use "my/module"]])
      assert(trans:next()):eq('import module from "my/module";\n')
    end)

    test("use LiteralStr as Name", function()
      parser:parse([[use "my/module" as mod]])
      assert(trans:next()):eq('import mod from "my/module";\n')
    end)

    test("use LiteralStr, LiteralStr", function()
      parser:parse([[use "my/mod1", "my/mod2"]])
      assert(trans:next()):eq('import mod1 from "my/mod1";import mod2 from "my/mod2";\n')
    end)

    test("use LiteralStr as Name, LiteralStr as Name", function()
      parser:parse([[use "my/module1" as mod1, "my/module2" as mod2]])
      assert(trans:next()):eq('import mod1 from "my/module1";import mod2 from "my/module2";\n')
    end)
  end)

  ----------
  -- from --
  ----------
  suite("from", function()
    test("from LiteralStr use Name", function()
      parser:parse([[from "fs" use FSWatcher]])
      assert(trans:next()):eq('import {FSWatcher} from "fs";\n')
    end)

    test("from LiteralStr use Name as Name", function()
      parser:parse([[from "fs" use FSWatcher as Watcher]])
      assert(trans:next()):eq('import {FSWatcher as Watcher} from "fs";\n')
    end)

    test("from LiteralStr use Name, Name", function()
      parser:parse([[from "fs" use FSWatcher, watch]])
      assert(trans:next()):eq('import {FSWatcher, watch} from "fs";\n')
    end)

    test("from LiteralStr use Name as Name, Name as Name", function()
      parser:parse([[from "fs" use FSWatcher as Watcher, watch as w]])
      assert(trans:next()):eq('import {FSWatcher as Watcher, watch as w} from "fs";\n')
    end)
  end)

  -----------
  -- break --
  -----------
  test("break", function()
    parser:parse("break")
    assert(trans:next()):eq("break;\n")
  end)

  ----------
  -- next --
  ----------
  test("next", function()
    parser:parse("next")
    assert(trans:next()):eq("continue;\n")
  end)

  ----------
  -- enum --
  ----------
  suite("enum", function()
    test("export enum Name {Name}", function()
      parser:parse("export enum Color {RED}")
      assert(trans:next()):eq([[
export default class Color {
  constructor(name, val) {
    Object.defineProperty(this, "name", {value: name, enum: true});
    Object.defineProperty(this, "value", {value: val, enum: true});
  }
}
Object.defineProperty(Color, "RED", {value: new Color("RED", 1), enum: true});

]])
    end)

    test("pub enum Name {Name}", function()
      parser:parse("pub enum Color {RED}")
      assert(trans:next()):eq([[
export class Color {
  constructor(name, val) {
    Object.defineProperty(this, "name", {value: name, enum: true});
    Object.defineProperty(this, "value", {value: val, enum: true});
  }
}
Object.defineProperty(Color, "RED", {value: new Color("RED", 1), enum: true});

]])
    end)

    test("enum Name {Name, Name, Name}", function()
      parser:parse("enum Color {RED, GREEN, BLUE}")
      assert(trans:next()):eq([[
class Color {
  constructor(name, val) {
    Object.defineProperty(this, "name", {value: name, enum: true});
    Object.defineProperty(this, "value", {value: val, enum: true});
  }
}
Object.defineProperty(Color, "RED", {value: new Color("RED", 1), enum: true});
Object.defineProperty(Color, "GREEN", {value: new Color("GREEN", 2), enum: true});
Object.defineProperty(Color, "BLUE", {value: new Color("BLUE", 3), enum: true});

]])
    end)

    test([[enum Name {Name = Str, Name = LiteralStr, Name = LiteralStr}]], function()
      parser:parse([[enum Color {RED = "1", GREEN = "2", BLUE = "3"}]])
      assert(trans:next()):eq([[
class Color {
  constructor(name, val) {
    Object.defineProperty(this, "name", {value: name, enum: true});
    Object.defineProperty(this, "value", {value: val, enum: true});
  }
}
Object.defineProperty(Color, "RED", {value: new Color("RED", "1"), enum: true});
Object.defineProperty(Color, "GREEN", {value: new Color("GREEN", "2"), enum: true});
Object.defineProperty(Color, "BLUE", {value: new Color("BLUE", "3"), enum: true});

]])
    end)
  end)

  -----------
  -- async --
  -----------
  suite("async", function()
    test("async without catch", function()
      parser:parse("async\n 1+2\n 3+4")
      assert(trans:next()):eq("setImmediate(() => {(1+2);(3+4);});\n")
    end)

    test("async with catch without var", function()
      parser:parse("async\n 1+2\n 3+4\ncatch\n 5+6")
      assert(trans:next()):eq("setImmediate(() => try {(1+2);(3+4);} catch(_) {(5+6);});\n")
    end)

    test("async with catch with var", function()
      parser:parse("async\n 1+2\n 3+4\ncatch e\n 5+6")
      assert(trans:next()):eq("setImmediate(() => try {(1+2);(3+4);} catch(e) {(5+6);});\n")
    end)
  end):tags("abc")

  ---------
  -- var --
  ---------
  suite("var", function()
    test("export var Name = Exp", function()
      parser:parse("export var x = 3")
      assert(trans:next()):eq("var x = 3;export default x;\n")
    end)

    test("pub var Name = Exp", function()
      parser:parse("pub var x = 3")
      assert(trans:next()):eq("var x = 3;export x;\n")
    end)

    test("var", function()
      parser:parse("var")
      assert(trans:next()):eq("\n")
    end)

    test("var Name", function()
      parser:parse("var x")
      assert(trans:next()):eq("let x;\n")
    end)

    test("var Name = Exp", function()
      parser:parse("var x = 1+2")
      assert(trans:next()):eq("let x = (1+2);\n")
    end)

    test("var Name, Name", function()
      parser:parse("var x, y")
      assert(trans:next()):eq("let x, y;\n")
    end)

    test("var Name = Exp, Name = Exp", function()
      parser:parse("var x = 1+2, y = 3+4")
      assert(trans:next()):eq("let x = (1+2), y = (3+4);\n")
    end)
  end)

  -----------
  -- const --
  -----------
  suite("const", function()
    test("const", function()
      parser:parse("const")
      assert(trans:next()):eq("\n")
    end)

    test("const Name = Exp", function()
      parser:parse("const x = 1+2")
      assert(trans:next()):eq("const x = (1+2);\n")
    end)

    test("const Name = Exp, Name = Exp", function()
      parser:parse("const x = 1+2, y = 3+4")
      assert(trans:next()):eq("const x = (1+2), y = (3+4);\n")
    end)

    test("export const Name = Exp", function()
      parser:parse("export const x = 3")
      assert(trans:next()):eq("const x = 3;export default x;\n")
    end)

    test("pub const Name = Exp", function()
      parser:parse("pub const x = 3")
      assert(trans:next()):eq("const x = 3;export x;\n")
    end)
  end)

  -----------
  -- while --
  -----------
  suite("while", function()
    test("while Exp do Exp", function()
      parser:parse("while true do x+1")
      assert(trans:next()):eq("while (true) {(x+1);}\n")
    end)

    test("while Exp do Stmt", function()
      parser:parse("while true do return x+1")
      assert(trans:next()):eq("while (true) {return (x+1);}\n")
    end)

    test("while Exp; Exp do Sent", function()
      parser:parse("while true; x + 1 do x + 2")
      assert(trans:next()):eq("for (; true; (x+1)) {(x+2);}\n")
    end)

    test("while with catch", function()
      parser:parse("while true do\n x+1\ncatch\n x+2")
      assert(trans:next()):eq("while (true) try {(x+1);} catch(_) {(x+2);}\n")
    end)

    test("while with finally", function()
      parser:parse("while true do\n x+1\nfinally\n x+2")
      assert(trans:next()):eq("while (true) try {(x+1);} finally {(x+2);}\n")
    end)

    test("while with catch and finally", function()
      parser:parse("while true do\n x+1\ncatch\n x+2\nfinally\n x+3")
      assert(trans:next()):eq("while (true) try {(x+1);} catch(_) {(x+2);} finally {(x+3);}\n")
    end)
  end):tags("while")

  --------
  -- do --
  --------
  suite("do", function()
    test("do with while", function()
      parser:parse("do\n x+1\nwhile true")
      assert(trans:next()):eq("do {(x+1);} while (true);\n")
    end)

    test("do with catch", function()
      parser:parse("do\n x+1\ncatch\n x+2")
      assert(trans:next()):eq("try {(x+1);} catch(_) {(x+2);}\n")
    end)

    test("do with finally", function()
      parser:parse("do\n x+1\nfinally\n x+2")
      assert(trans:next()):eq("try {(x+1);} finally {(x+2);}\n")
    end)

    test("do with catch and finally", function()
      parser:parse("do\n x+1\ncatch\n x+2\nfinally\n x+3")
        assert(trans:next()):eq("try {(x+1);} catch(_) {(x+2);} finally {(x+3);}\n")
    end)

    test("do with while, catch and finally", function()
      parser:parse("do\n x+1\nwhile true\ncatch\n x+2\nfinally\n x+3")
        assert(trans:next()):eq("do try {(x+1);} catch(_) {(x+2);} finally {(x+3);} while (true);\n")
    end)
  end)

  ---------
  -- for --
  ---------
  suite("for", function()
    test("for Name ; Exp do Exp", function()
      parser:parse("for i ; i < 10 do print(i)")
      assert(trans:next()):eq("for (let i; (i<10); ) {print(i);}\n")
    end)

    test("for Name = Exp; Exp do Exp", function()
      parser:parse("for i = 0; i < 10 do print(i)")
      assert(trans:next()):eq("for (let i = 0; (i<10); ) {print(i);}\n")
    end)

    test("for Variable; Exp; Exp do Exp", function()
      parser:parse("for i = 0; i < 10; i += 1 do print(i)")
      assert(trans:next()):eq("for (let i = 0; (i<10); (i+=1)) {print(i);}\n")
    end)

    test("for Name, Name ; Exp do Exp", function()
      parser:parse("for i, j ; i < 10 do print(i)")
      assert(trans:next()):eq("for (let i, j; (i<10); ) {print(i);}\n")
    end)

    test("for Name = Exp, Name = Exp ; Exp do Exp", function()
      parser:parse("for i = 0, j = 1 ; i < 10 do print(i)")
      assert(trans:next()):eq("for (let i = 0, j = 1; (i<10); ) {print(i);}\n")
    end)

    test("for Name = Exp, Name = Exp ; Exp; Exp do Exp", function()
      parser:parse("for i = 0, j = 1 ; i < 10; i += 1 do print(i)")
      assert(trans:next()):eq("for (let i = 0, j = 1; (i<10); (i+=1)) {print(i);}\n")
    end)

    test("for Name; Exp; Exp do\\n Body\\ncatch\\n Body", function()
      parser:parse("for i; i < 10; i += 1 do\n print(i)\ncatch e\n print(e)")
      assert(trans:next()):eq("for (let i; (i<10); (i+=1)) try {print(i);} catch(e) {print(e);}\n")
    end)
  end):tags("for")

  --------------
  -- for each --
  --------------
  suite("for each", function()
    test("for each Name in Exp do\\n Sent", function()
      parser:parse("for each k in arr do\n x+1")
      assert(trans:next()):eq("for (let k of arr) {(x+1);}\n")
    end)

    test("for each Name, Name in Exp do\\n Sent", function()
      parser:parse("for each k, v in map do\n x+1")
      assert(trans:next()):like("const $aux[0-9]+ = map; for %(let k in $aux[0-9]+%) { let v = $aux[0-9]+%[k%]; {%(x%+1%);} }\n")
    end)

    test("for each with catch", function()
      parser:parse("for each k in arr do\n x+1\ncatch\n x+2")
      assert(trans:next()):eq("for (let k of arr) try {(x+1);} catch(_) {(x+2);}\n")
    end)

    test("for each with finally", function()
      parser:parse("for each k in arr do\n x+1\nfinally\n x+2")
      assert(trans:next()):eq("for (let k of arr) try {(x+1);} finally {(x+2);}\n")
    end)

    test("for each with catch and finally", function()
      parser:parse("for each k in arr do\n x+1\ncatch\n x+2\nfinally\n x+3")
      assert(trans:next()):eq("for (let k of arr) try {(x+1);} catch(_) {(x+2);} finally {(x+3);}\n")
    end)
  end):tags("foreach")

  ------------
  -- return --
  ------------
  suite("return", function()
    test("return", function()
      parser:parse("return")
      assert(trans:next()):eq("return;\n")
    end)

    test("return Exp", function()
      parser:parse("return x+1")
      assert(trans:next()):eq("return (x+1);\n")
    end)
  end)

  ----------
  -- type --
  ----------
  suite("type", function()
    test("type Name()\\n Body", function()
      parser:parse("type Coord2D()\n $x = 0\n $y = 0")
      assert(trans:next()):eq([[
const $Coord2D = class Coord2D {
  constructor() { {(this.x=0);(this.y=0);}  }
};
const Coord2D = new Proxy($Coord2D, { apply(receiver, self, args) { return new $Coord2D(...args); } });
]])
    end)

    test("type Coord2D($x, $y)", function()
      parser:parse("type Coord2D($x, $y)")
      assert(trans:next()):eq([[
const $Coord2D = class Coord2D {
  constructor(x, y) { dogma.paramExpected("x", x, null);dogma.paramExpected("y", y, null);Object.defineProperty(this, "x", {value: x, enum: true, writable: true});Object.defineProperty(this, "y", {value: y, enum: true, writable: true});{}  }
};
const Coord2D = new Proxy($Coord2D, { apply(receiver, self, args) { return new $Coord2D(...args); } });
]])
    end)

    test("type Name(:Name)", function()
      parser:parse("type Coord1D(:x)")
      assert(trans:next()):eq([[
const $Coord1D = class Coord1D {
  constructor(x) { dogma.paramExpected("x", x, null);Object.defineProperty(this, "_x", {value: x, writable: true});{}  }
};
const Coord1D = new Proxy($Coord1D, { apply(receiver, self, args) { return new $Coord1D(...args); } });
]])
    end)

    test("type Name() : Name", function()
      parser:parse("type Coord3D() : Coord2D")
      assert(trans:next()):eq([[
const $Coord3D = class Coord3D extends Coord2D {
  constructor() { {}  }
};
const Coord3D = new Proxy($Coord3D, { apply(receiver, self, args) { return new $Coord3D(...args); } });
]])
    end)

    test("type Name() : Name()", function()
      parser:parse("type Coord3D() : Coord2D()")
      assert(trans:next()):eq([[
const $Coord3D = class Coord3D extends Coord2D {
  constructor() { super();{}  }
};
const Coord3D = new Proxy($Coord3D, { apply(receiver, self, args) { return new $Coord3D(...args); } });
]])
    end)

    test("type Coord3D(x, y, $z) : Coord2D(x, y)", function()
      parser:parse("type Coord3D(x, y, $z) : Coord2D(x, y)")
      assert(trans:next()):eq([[
const $Coord3D = class Coord3D extends Coord2D {
  constructor(x, y, z) { dogma.paramExpected("x", x, null);dogma.paramExpected("y", y, null);dogma.paramExpected("z", z, null);super(x, y);Object.defineProperty(this, "z", {value: z, enum: true, writable: true});{}  }
};
const Coord3D = new Proxy($Coord3D, { apply(receiver, self, args) { return new $Coord3D(...args); } });
]])
    end)

    test("export type Coord2D()", function()
      parser:parse("export type Coord2D()")
      assert(trans:next()):eq([[
const $Coord2D = class Coord2D {
  constructor() { {}  }
};
const Coord2D = new Proxy($Coord2D, { apply(receiver, self, args) { return new $Coord2D(...args); } });export default Coord2D;
]])
    end)
  end)

  --------
  -- fn --
  --------
  suite("fn", function()
    suite("params", function()
      test("fn func(keyword)", function()
        parser:parse("fn sum(x, default) = x + default")
        assert(trans:next()):eq('function sum(x, default_) { dogma.paramExpected("x", x, null);dogma.paramExpected("default_", default_, null);{return (x+default_);} }\n')
      end)

      test("fn Name(Name)", function()
        parser:parse("fn myfn(x)")
        assert(trans:next()):eq('function myfn(x) { dogma.paramExpected("x", x, null);{} }\n')
      end)

      test("fn Name(const Name)", function()
        parser:parse("fn myfn(x)")
        assert(trans:next()):eq('function myfn(x) { dogma.paramExpected("x", x, null);{} }\n')
      end)

      test("fn Name(Name?)", function()
        parser:parse("fn myfn(x?)")
        assert(trans:next()):eq('function myfn(x) { {} }\n')
      end)

      test("fn Name(...Name)", function()
        parser:parse("fn myfn(...x)")
        assert(trans:next()):eq('function myfn(...x) { {} }\n')
      end)

      test("fn Name(Name:Name)", function()
        parser:parse("fn myfn(x:num)")
        assert(trans:next()):eq('function myfn(x) { dogma.paramExpected("x", x, num);{} }\n')
      end)

      test("fn Name(Name?:Name)", function()
        parser:parse("fn myfn(x?:num)")
        assert(trans:next()):eq('function myfn(x) { dogma.paramExpectedToBe("x", x, num);{} }\n')
      end)

      test("fn Name(Name=Name)", function()
        parser:parse("fn myfn(x=123)")
        assert(trans:next()):eq('function myfn(x = 123) { dogma.paramExpected("x", x, null);{} }\n')
      end)

      test("fn Name(Name:{})", function()
        parser:parse("fn sum(vals:{}) = vals.x + vals.y")
        assert(trans:next()):eq('function sum(vals) { dogma.paramExpectedToHave("vals", vals, {});{return (vals.x+vals.y);} }\n')
      end)

      test("fn Name(Name:{p:type,p:type})", function()
        parser:parse("fn sum(vals:{x:num, y:num}) = vals.x + vals.y")
        assert(trans:next()):eq('function sum(vals) { dogma.paramExpectedToHave("vals", vals, {x: num, y: num});{return (vals.x+vals.y);} }\n')
      end)

      test("fn Name(Name?:{p:type,p:type})", function()
        parser:parse("fn sum(vals?:{x:num, y:num}) = vals.x + vals.y")
        assert(trans:next()):eq('function sum(vals) { dogma.paramExpectedToHave("vals", vals, {x: num, y: num});{return (vals.x+vals.y);} }\n')
      end)
    end)

    suite("standalone", function()
      test("fn Name()", function()
        parser:parse("fn myfn()")
        assert(trans:next()):eq("function myfn() { {} }\n")
      end)

      test("fn Name() = Exp", function()
        parser:parse("fn myfn() = 123")
        assert(trans:next()):eq("function myfn() { {return 123;} }\n")
      end)

      test("fn Name(Name?=Name)", function()
        parser:parse("fn myfn(x?=123)")
        assert(trans:next()):eq('function myfn(x = 123) { {} }\n')
      end)

      test("export fn Name()", function()
        parser:parse("export fn myfn()")
        assert(trans:next()):eq('export default function myfn() { {} }\n')
      end)

      test("pub fn Name()", function()
        parser:parse("pub fn myfn()")
        assert(trans:next()):eq('export function myfn() { {} }\n')
      end)

      test("fn Name(params) Body", function()
        parser:parse("fn sum(x, y)\n return x+y")
        assert(trans:next()):eq('function sum(x, y) { dogma.paramExpected("x", x, null);dogma.paramExpected("y", y, null);{return (x+y);} }\n')
      end)

      test("fn Name() -> self Body", function()
        parser:parse("fn myfn() -> self\n 1+2")
        assert(trans:next()):eq("function myfn() { {(1+2);} return this; }\n")
      end)

      test("fn Name() -> Name Body", function()
        parser:parse("fn myfn() -> x\n 1+2")
        assert(trans:next()):eq("function myfn() { let x;{(1+2);} return x; }\n")
      end)

      test("fn Name(param) -> Name Body - return variable not existing", function()
        parser:parse("fn myfn(a?, b?) -> x\n x = a + b")
        assert(trans:next()):eq("function myfn(a, b) { let x;{(x=(a+b));} return x; }\n")
      end)

      test("fn Name(param) -> Name Body - return variable existing", function()
        parser:parse("fn myfn(a?, b?, x?) -> x\n x = a + b")
        assert(trans:next()):eq("function myfn(a, b, x) { {(x=(a+b));} return x; }\n")
      end)
    end)

    suite("type", function()
      suite("property", function()
        test("@prop fn Name . Name () = Exp", function()
          parser:parse("@prop\nfn MyType.prop() = 1+2")
          assert(trans:next()):eq('Object.defineProperty(MyType.prototype, "prop", {enum: true, get: function() { {return (1+2);} }});\n')
        end)

        test("@prop fn Name . Name () -> Var Body", function()
          parser:parse("@prop\nfn MyType.prop() -> resp\n  resp = 1+2")
          assert(trans:next()):eq('Object.defineProperty(MyType.prototype, "prop", {enum: true, get: function() { let resp;{(resp=(1+2));} return resp; }});\n')
        end)

        test("@prop fn Name : Name () = Exp", function()
          parser:parse("@prop\nfn MyType:prop() = 1+2")
          assert(trans:next()):eq('Object.defineProperty(MyType.prototype, "_prop", {enum: false, get: function() { {return (1+2);} }});\n')
        end)

        test("@abstract @prop fn Name.Name()", function()
          parser:parse("@abstract @prop\nfn MyType.prop()")
          assert(trans:next()):eq('Object.defineProperty(MyType.prototype, "prop", {enum: true, get: function() { abstract(); }});\n')
        end)
      end):tags("prop")

      suite("static method", function()
        test("@static fn Name . Name() -> res\\n Body", function()
          parser:parse("@static\nfn MyType.method() -> res\n  res = 1+2")
          assert(trans:next()):eq("MyType.method = function() { let res;{(res=(1+2));} return res; };\n")
        end)
      end):tags("static")

      test("fn Name . Name ()", function()
        parser:parse("fn MyType.myfn()")
        assert(trans:next()):eq('MyType.prototype.myfn = function() { {} };\n')
      end)

      test("@abstract\\nfn Name . Name ()", function()
        parser:parse("@abstract\nfn MyType.myfn()")
        assert(trans:next()):eq('MyType.prototype.myfn = function() { abstract(); };\n')
      end):tags("abstract")

      test("fn Name : Name ()", function()
        parser:parse("fn MyType:myfn()")
        assert(trans:next()):eq('MyType.prototype._myfn = function() { {} };\n')
      end):tags("xyz")

      test("fn Name . Name ($ Name)", function()
        parser:parse("fn MyType.myfn($x)")
        assert(trans:next()):eq('MyType.prototype.myfn = function(x) { dogma.paramExpected("x", x, null);Object.defineProperty(this, "x", {value: x, enum: true, writable: true});{} };\n')
      end)

      test("fn Name . Name (. Name)", function()
        parser:parse("fn MyType.myfn(.x)")
        assert(trans:next()):eq('MyType.prototype.myfn = function(x) { dogma.paramExpected("x", x, null);Object.defineProperty(this, "x", {value: x, enum: true, writable: true});{} };\n')
      end):tags("1x2")

      test("fn Name . Name ($ Name , $ Name)", function()
        parser:parse("fn MyType.myfn($x, $y)")
        assert(trans:next()):eq('MyType.prototype.myfn = function(x, y) { dogma.paramExpected("x", x, null);dogma.paramExpected("y", y, null);Object.defineProperty(this, "x", {value: x, enum: true, writable: true});Object.defineProperty(this, "y", {value: y, enum: true, writable: true});{} };\n')
      end)

      test("fn Name . Name (const $ Name)", function()
        parser:parse("fn MyType.myfn(const $x)")
        assert(trans:next()):eq('MyType.prototype.myfn = function(x) { dogma.paramExpected("x", x, null);Object.defineProperty(this, "x", {value: x, enum: true, writable: false});{} };\n')
      end)

      test("fn Name . Name (const . Name)", function()
        parser:parse("fn MyType.myfn(const .x)")
        assert(trans:next()):eq('MyType.prototype.myfn = function(x) { dogma.paramExpected("x", x, null);Object.defineProperty(this, "x", {value: x, enum: true, writable: false});{} };\n')
      end)

      test("fn Name . Name ($x Name ?)", function()
        parser:parse("fn MyType.myfn($x?)")
        assert(trans:next()):eq('MyType.prototype.myfn = function(x) { Object.defineProperty(this, "x", {value: x, enum: true, writable: true});{} };\n')
      end)

      test("fn Name . Name() -> self\\n Body", function()
        parser:parse("fn MyType.method() -> self\n 1+2")
        assert(trans:next()):eq("MyType.prototype.method = function() { {(1+2);} return this; };\n")
      end)
    end)
  end):tags("fn")

  --------
  -- if --
  --------
  suite("if", function()
    test("if Exp then Exp", function()
      parser:parse("if true then x+y")
      assert(trans:next()):eq("if (true) {(x+y);}\n")
    end)

    test("if Exp then Sent", function()
      parser:parse("if true then return x+y")
      assert(trans:next()):eq("if (true) {return (x+y);}\n")
    end)

    test("if Exp then Exp else Exp", function()
      parser:parse("if true then x+y else a+b")
      assert(trans:next()):eq("if (true) {(x+y);} else {(a+b);}\n")
    end)

    test("if Exp then Exp else Sent", function()
      parser:parse("if true then x+y else return a+b")
      assert(trans:next()):eq("if (true) {(x+y);} else {return (a+b);}\n")
    end)

    test("if with else if", function()
      parser:parse("if true then\n x+y\nelse if false then\n a+b")
      assert(trans:next()):eq("if (true) {(x+y);} else if (false) {(a+b);}\n")
    end)

    test("if with else if and else", function()
      parser:parse("if x then\n x+y\nelse if y then\n a+b\nelse if z then\n 1+2\nelse\n 3+4")
      assert(trans:next()):eq("if (x) {(x+y);} else if (y) {(a+b);} else if (z) {(1+2);} else {(3+4);}\n")
    end)
  end):tags("if")

  ---------
  -- pub --
  ---------
  suite("pub", function()
    test("pub Item", function()
      parser:parse("pub Item")
      assert(trans:next()):eq("export {Item};\n")
    end)

    test("pub Item, Item", function()
      parser:parse("pub Item1, Item2")
      assert(trans:next()):eq("export {Item1, Item2};\n")
    end)
  end):tags("pub")

  ------------
  -- export --
  ------------
  suite("export", function()
    test("export Exp", function()
      parser:parse("export 1+2")
      assert(trans:next()):eq("export default (1+2);\n")
    end)
  end):tags("export")

  ----------
  -- with --
  ----------
  suite("with", function()
    test("with", function()
      parser:parse("with 1+2\n  if 1 then x+1\n  if 2 then y+1\n  else z+1")
      assert(trans:next()):like("const %$aux[0-9]+ = %(1%+2%);if %(%$aux[0-9]+ == 1%) {%(x%+1%);} else if %(%$aux[0-9]+ == 2%) {%(y%+1%);} else {%(z%+1%);}")
    end)
  end):tags("with")
end):tags("stmt")
