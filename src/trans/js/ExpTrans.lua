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
    return string.format([["%s"]], node.data)
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
  elseif node.subtype == TerminalType.SUBEXP then
    return self:transform(node.data)
  elseif node.subtype == TerminalType.NATIVE then
    return self:_transNativeFn(node)
  elseif node.subtype == TerminalType.PEVAL then
    return self:_transPevalFn(node)
  elseif node.subtype == TerminalType.THROW then
    return self:_transThrowFn(node)
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
    self:transform(node.falseCase)
  )
end

--Transform a native() function.
function ExpTrans:_transNativeFn(fn)
  return string.format(fn.code)
end

--Transform a peval() function.
function ExpTrans:_transPevalFn(fn)
  return string.format("dogma.peval(() => {return %s;})", self:transform(fn.exp))
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
    "(%s) => { %s%s%s%s }",
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
  -- elseif node.subtype == NonTerminalType.TREE then
  --   return self:_transTree(node)
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
  end
end

function ExpTrans:_transBinOp(node)
  local left, right = node.children[1], node.children[2]

  if tablex.find({"+", "-", "*", "**", "/", "%", "==", "!=", "===", "!==", "<", "<=", ">", ">=", "<<", ">>", "||", "&&"}, node.op) then
    return "(" .. self:_transNode(left) .. node.op .. self:_transNode(right) .. ")"
  elseif tablex.find({"=", "+=", "-=", "*=", "**=", "/=", "%=", "<<=", ">>=", "|=", "&=", "^="}, node.op) then
    return self:_transAssign(node)
  elseif node.op == "?=" then
    return self:_transCondAssign(node)
  elseif node.op == ".=" then
    return self:_transAssignWithPubProp(node)
  elseif node.op == ":=" then
    return self:_transConstAssign(node)
  elseif node.op == "and" then
    return "(" .. self:_transNode(left) .. "&&" .. self:_transNode(right) .. ")"
  elseif node.op == "or" then
    return "(" .. self:_transNode(left) .. "||" .. self:_transNode(right) .. ")"
  elseif node.op == "." then
    return self:_transNode(left) .. "." .. self:_transNode(right)
  elseif node.op == ":" then
    return self:_transNode(left) .. "._" .. right.data
  elseif node.op == "is" then
    return string.format("dogma.is(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "isnot" then
    return string.format("dogma.isNot(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "in" then
    return string.format("(%s).includes(%s)", self:_transNode(right), self:_transNode(left))
  elseif node.op == "notin" then
    return string.format("!(%s).includes(%s)", self:_transNode(right), self:_transNode(left))
  elseif node.op == "like" then
    return string.format("dogma.like(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "notlike" then
    return string.format("dogma.notLike(%s, %s)", self:_transNode(left), self:_transNode(right))
  elseif node.op == "[]" then
    return string.format("dogma.getItem(%s, %s)", self:_transNode(left), self:_transNode(right))
  end
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
end
