--imports
local tablex = require("pl.tablex")
local NodeType = require("dogma.syn.NodeType")
local TerminalType = require("dogma.syn.TerminalType")
local NonTerminalType = require("dogma.syn.NonTerminalType")
local transName = require("dogma.trans.js._.util").transName
local SubTrans = require("dogma.trans.js._.SubTrans")

--An expression transformer to JavaScript.
local ExpTrans = {}
ExpTrans.__index = ExpTrans
setmetatable(ExpTrans, {__index = SubTrans})
package.loaded[...] = ExpTrans

--Constructor.
function ExpTrans.new(trans)
  return setmetatable(SubTrans.new(trans), ExpTrans)
end

--Transform an expression.
--
--@param exp:Exp      Expression to transform.
--@return string
function ExpTrans:transform(exp)
  return self:_transNode(exp.tree.root)
end

--Transform a node.
--
--@param node:Node
--@return string
function ExpTrans:_transNode(node)
  if node.type == NodeType.TERMINAL then
    return self:_transTerminal(node)
  elseif node.type == NodeType.NON_TERMINAL then
    return self:_transNonTerminal(node)
  end
end

--Transform a terminal node.
--
--@param node:Terminal
--@return string
function ExpTrans:_transTerminal(node)
  if node.subtype == TerminalType.NAME then
    return transName(node.data)
  elseif node.subtype == TerminalType.NUM then
    return tostring(node.data)
  elseif node.subtype == TerminalType.TEXT then
    return string.format([["%s"]], node.data:gsub('"', '\\"')):gsub("\n", "\\n")
  elseif node.subtype == TerminalType.TRUE then
    return "true"
  elseif node.subtype == TerminalType.FALSE then
    return "false"
  elseif node.subtype == TerminalType.NIL then
    return "null"
  elseif node.subtype == TerminalType.LIST then
    return self:_transLiteralList(node)
  elseif node.subtype == TerminalType.MAP then
    return self:_transLiteralMap(node)
  elseif node.subtype == TerminalType.SELF then
    return "this"
  elseif node.subtype == TerminalType.SUPER then
    return "super"
  elseif node.subtype == TerminalType.NOP then
    return "dogma.nop()"
  elseif node.subtype == TerminalType.FN then
    return self:_transLiteralFn(node)
  elseif node.subtype == TerminalType.IIF then
    return self:_transIifFn(node)
  elseif node.subtype == TerminalType.SUBEXP then
    return self:transform(node.data)
  elseif node.subtype == TerminalType.NATIVE then
    return self:_transNativeFn(node)
  elseif node.subtype == TerminalType.AWAIT then
    return self:_transAwaitFn(node)
  elseif node.subtype == TerminalType.PEVAL then
    return self:_transPevalFn(node)
  elseif node.subtype == TerminalType.PAWAIT then
    return self:_transPawaitFn(node)
  elseif node.subtype == TerminalType.THROW then
    return self:_transThrowFn(node)
  elseif node.subtype == TerminalType.USE then
    return self:_transUseFn(node)
  elseif node.subtype == TerminalType.IF then
    return self:_transIfSubExp(node)
  end
end

--Transform if Exp then Exp else Exp end
function ExpTrans:_transIfSubExp(node)
  return string.format(
    "(%s ? %s : %s)",
    self:transform(node.cond),
    self:transform(node.trueCase),
    node.falseCase ~= nil and self:transform(node.falseCase) or "null"
  )
end

--Transform a native() function.
function ExpTrans:_transNativeFn(fn)
  return string.format(fn.code)
end

--Transform an await() function.
function ExpTrans:_transAwaitFn(fn)
  return string.format("await(%s)", self:transform(fn.exp))
end

--Transform a pawait() function.
function ExpTrans:_transPawaitFn(fn)
  return string.format("dogma.pawait((done) => {%s;})", self:transform(fn.exp))
end

--Transform a use() function.
function ExpTrans:_transUseFn(fn)
  return string.format("dogma.use(require(%s))", self:transform(fn.exp))
end

--Transform a peval() function.
function ExpTrans:_transPevalFn(fn)
  return string.format("dogma.peval(() => {return %s;})", self:transform(fn.exp))
end

--Transform an iif() function.
function ExpTrans:_transIifFn(fn)
  return string.format(
    "(%s ? %s : %s)",
    self:transform(fn.cond),
    self:transform(fn.onTrue),
    fn.onFalse and self:transform(fn.onFalse) or "null"
  )
end

--Transform a throw() function.
function ExpTrans:_transThrowFn(fn)
  local code

  --(1) transform
  code = "dogma.raise("

  if #fn.args == 1 then
    code = code .. self:transform(fn.args[1])
  else
    for i, arg in ipairs(fn.args) do
      code = code .. (i == 1 and "" or ", ") .. self:transform(arg)
    end
  end

  code = code .. ")"

  --(2) return
  return code
end

--Transform a literal list.
function ExpTrans:_transLiteralList(term)
  local code

  --(1) transform
  code = "["

  for ix, item in ipairs(term.data) do
    code = code .. (ix == 1 and "" or ", ") .. self:transform(item)
  end

  code = code .. "]"

  --(2) return
  return code
end

--Transform a literal map.
function ExpTrans:_transLiteralMap(term)
  local code

  --(1) transform
  code = "{"

  for i, entry in ipairs(term.data) do
    code = code .. (i == 1 and "" or ", ") .. string.format(
      '["%s"]: %s',
      entry.name,
      self:transform(entry.value)
    )
  end

  code = code .. "}"

  --(2) return
  return code
end

--Transform a literal function.
function ExpTrans:_transLiteralFn(term)
  local strans = self._.trans._.stmtTrans

  return string.format(
    "((%s) => { %s%s%s%s })",
    strans:_transParams(term.data.params),
    strans:_transReturnVar(term.data),
    strans:_transParamsCheck(term.data.params),
    strans:_transBody(term.data.body),
    term.data.rvar and string.format(" return %s;", term.data.rvar == "self" and "this" or term.data.rvar) or ""
  )
end

--Transform a non-terminal node.
--
--@param node:NonTerminal
--@return string
function ExpTrans:_transNonTerminal(node)
  if node.subtype == NonTerminalType.OP then
    return self:_transOp(node)
  end
end

--Transform an operator node.
--
--@param node:Op
--@return string
function ExpTrans:_transOp(node)
  if node.arity == "u" then
    return self:_transUnaryOp(node)
  elseif node.arity == "b" then
    return self:_transBinOp(node)
  elseif node.arity == "t" then
    return self:_transTernaryOp(node)
  elseif node.arity == "n" then
    return self:_transNaryOp(node)
  end
end

function ExpTrans:_transUnaryOp(node)
  if node.op == "." then
    return "this." .. node.child.data
  elseif node.op == ":" then
    return "this._" .. node.child.data
  elseif node.op == "not" or node.op == "!" then
    return string.format("!(%s)", self:_transNode(node.child))
  elseif node.op == "~" then
    return string.format("~(%s)", self:_transNode(node.child))
  elseif node.op == "+" then
    return string.format("+(%s)", self:_transNode(node.child))
  elseif node.op == "-" then
    return string.format("-(%s)", self:_transNode(node.child))
  elseif node.op == "..." then
    return string.format("...(%s)", self:_transNode(node.child))
  elseif node.op == "<<<" then
    return string.format("dogma.lshift(%s)", self:_transNode(node.child))
  elseif node.op == ">>>" then
    return string.format("dogma.rshift(%s)", self:_transNode(node.child))
  end
end

function ExpTrans:_transBinOp(node)
  local left, right = node.children[1], node.children[2]

  if tablex.find({"+", "-", "*", "**", "/", "%", "==", "!=", "===", "!==", "<", "<=", ">", ">=", "||", "&&", "<<", "<<"}, node.op) then
    return "(" .. self:_transNode(left) .. node.op .. self:_transNode(right) .. ")"
  elseif tablex.find({"=", "+=", "-=", "*=", "**=", "/=", "%=", "<<=", ">>=", "|=", "&=", "^="}, node.op) then
    return self:_transAssign(node)
  elseif node.op == "=~" then
    return self:_transEnumEq(node)
  elseif node.op == "!~" then
    return self:_transEnumNe(node)
  elseif node.op == "?=" then
    return self:_transCondAssign(node)
  elseif node.op == ".=" then
    return self:_transAssignWithPubProp(node)
  elseif node.op == ":=" then
    return self:_transConstAssign(node)
  elseif node.op == ">>>" then
    return string.format("dogma.rshift(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "<<<" then
    return string.format("dogma.lshift(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "and" then
    return "(" .. self:_transNode(left) .. "&&" .. self:_transNode(right) .. ")"
  elseif node.op == "or" then
    return "(" .. self:_transNode(left) .. "||" .. self:_transNode(right) .. ")"
  elseif node.op == "?" then
    return string.format("(%s != null ? %s.%s : null)", self:_transNode(left), self:_transNode(left), self:_transNode(right))
  elseif node.op == "." then
    if left.subtype == TerminalType.SUPER then
      return string.format('dogma.super(this, "%s")', self:_transNode(right))
    else
      return self:_transNode(left) .. "." .. self:_transNode(right)
    end
  elseif node.op == ":" then
    if left.subtype == TerminalType.SUPER then
      return string.format('dogma.super(this, "_%s")', self:_transNode(right))
    else
      return self:_transNode(left) .. "._" .. self:_transNode(right)
    end
  elseif node.op == "is" then
    return string.format("dogma.is(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "isnot" then
    return string.format("dogma.isNot(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "in" then
    return string.format("dogma.includes(%s, %s)", self:_transNode(right), self:_transNode(left))
  elseif node.op == "notin" then
    return string.format("!dogma.includes(%s, %s)", self:_transNode(right), self:_transNode(left))
  elseif node.op == "like" then
    return string.format("dogma.like(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "notlike" then
    return string.format("dogma.notLike(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "[]" then
    return string.format("dogma.getItem(%s, %s)", self:_transNode(left), self:_transNode(right))
  end
end

function ExpTrans:_transEnumEq(op)
  return string.format(
    'dogma.enumEq(%s, "%s")',
    self:_transNode(op.children[1]),
    self:_transNode(op.children[2])
  )
end

function ExpTrans:_transEnumNe(op)
  return string.format(
    '(!dogma.enumEq(%s, "%s"))',
    self:_transNode(op.children[1]),
    self:_transNode(op.children[2])
  )
end

function ExpTrans:_transCondAssign(op)
  local left, right = op.children[1], op.children[2]
  local code

  --(1) transform
  if left.arity == "b" and left.op == "[]" then
    code = string.format(
      'dogma.setItem("=", %s, %s, coalesce(dogma.getItem(%s, %s), %s))',
      self:_transNode(left.children[1]),
      self:_transNode(left.children[2]),
      self:_transNode(left.children[1]),
      self:_transNode(left.children[2]),
      self:_transNode(right)
    )
  else
    code = string.format(
      "(%s = coalesce(%s, %s))",
      self:_transNode(left),
      self:_transNode(left),
      self:_transNode(right)
    )
  end

  --(2) return
  return code
end

function ExpTrans:_transAssign(op)
  local left, right = op.children[1], op.children[2]
  local code

  --(1) transform
  if left.op == "[]" then
    code = string.format(
      [[dogma.setItem("%s", %s, %s, %s)]],
      op.op,
      self:_transNode(left.children[1]),
      self:_transNode(left.children[2]),
      self:_transNode(right)
    )
  else
    code = string.format("(%s%s%s)", self:_transNode(left), op.op, self:_transNode(right))
  end

  --(2) return
  return code
end

function ExpTrans:_transConstAssign(op)
  local left, right = op.children[1], op.children[2]
  local code

  --(1) transform
  if left.arity == "u" and left.op == "." then
    code = string.format(
      [[Object.defineProperty(this, "%s", {value: %s, enum: true})]],
      self:_transNode(left.child),
      self:_transNode(right)
    )
  elseif left.arity == "b" and left.op == "." then
    code = string.format(
      [[Object.defineProperty(%s, "%s", {value: %s, enum: true})]],
      self:_transNode(left.children[1]),
      self:_transNode(left.children[2]),
      self:_transNode(right)
    )
  elseif left.op == ":" then
    if left.arity == "u" then
      code = string.format(
        [[Object.defineProperty(this, "_%s", {value: %s})]],
        left.child.data,
        self:_transNode(right)
      )
    else
      code = string.format(
        [[Object.defineProperty(%s, "_%s", {value: %s})]],
        self:_transNode(left.children[1]),
        left.children[2].data,
        self:_transNode(right)
      )
    end
  elseif left.op == "[]" then
    code = string.format(
      [[dogma.setItem("=", %s, %s, %s)]],
      self:_transNode(left.children[1]),
      self:_transNode(left.children[2]),
      self:_transNode(right)
    )
  end

  --(2) return
  return code
end

function ExpTrans:_transAssignWithPubProp(op)
  local left, right = op.children[1], op.children[2]
  local code

  --(1) transform
  if left.arity == "u" then
    code = string.format(
      'Object.defineProperty(this, "_%s", {value: %s, writable: true});',
      left.child.data,
      self:_transNode(right)
    )

    code = code .. string.format(
      'Object.defineProperty(this, "%s", {enum: true, get() { return this._%s; }})',
      left.child.data,
      left.child.data
    )
  end

  --(2) return
  return code
end

function ExpTrans:_transTernaryOp(op)
  if op.op == "[]" then
    return string.format(
      "dogma.getSlice(%s, %s, %s)",
      self:_transNode(op.children[1]),
      self:_transNode(op.children[2]),
      self:_transNode(op.children[3])
    )
  end
end

function ExpTrans:_transNaryOp(node)
  if node.op == "()" then
    return self:_transCallOp(node)
  elseif node.op == "{}" then
    return self:_transPackOp(node)
  elseif node.op == ".{}" then
    return self:_transUpdateOp(node)
  end
end

function ExpTrans:_transCallOp(node)
  local code

  code = self:_transNode(node.children[1]) .. "("
  for i, arg in ipairs(node.children) do
    if i > 1 then
      code = code .. (i == 2 and "" or ", ") .. self:_transNode(arg.tree.root)
    end
  end
  code = code .. ")"

  return code
end

function ExpTrans:_transPackOp(node)
  local code

  --(1) transform
  if #node.children > 1 and node.children[2].name == "*" then
    code = string.format("dogma.clone(%s", self:_transNode(node.children[1]))

    for i, item in ipairs(node.children) do
      if i == 3 then
        code = code .. ", {"
      elseif i > 3 then
        code = code .. ", "
      end

      if i >= 3 then
        code = code .. string.format(
          '"%s%s": %s',
          item.visib == "." and "" or "_",
          item.name,
          self:transform(item.value)
        )
      end
    end

    if #node.children > 2 then
      code = code .. "})"
    else
      code = code .. ")"
    end
  else
    code = "dogma.pack("

    for i, item in ipairs(node.children) do
      if i == 1 then
        code = code .. self:_transNode(item)
      else
        if item.value == nil then
          code = code .. string.format(', "%s%s"', item.visib == "." and "" or "_", item.name)
        else
          code = code .. string.format(
            ', {name: "%s%s", value: %s}',
            item.visib == "." and "" or "_",
            item.name,
            self:transform(item.value)
          )
        end
      end
    end

    code = code .. ")"
  end

  --(2) return
  return code
end

function ExpTrans:_transUpdateOp(op)
  local code

  --(1) transform
  code = "dogma.update(" .. self:_transNode(op.children[1])

  for _, fld in ipairs(table.pack(table.unpack(op.children, 2))) do
    if fld.type then
      code = code .. string.format(
        ', {name: [%s], visib: "%s", assign: "%s", value: %s, type: "%s"}',
        table.concat(tablex.map(function(name) return string.format('"%s"', name) end, fld.name), ", "),
        op.visib,
        fld.assign or "=",
        fld.value and self:transform(fld.value) or fld.name,
        fld.type
      )
    else
      code = code .. string.format(
        ', {name: "%s", visib: "%s", assign: "%s", value: %s}',
        fld.name,
        op.visib,
        fld.assign or "=",
        fld.value and self:transform(fld.value) or fld.name
      )
    end
  end

  code = code .. ")"

  --(2) return
  return code
end
