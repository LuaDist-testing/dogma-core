--imports
local tablex = require("pl.tablex")
local StmtType = require("dogma.syn.StmtType")
local transName = require("dogma.trans.js._.util").transName
local SubTrans = require("dogma.trans.js._.SubTrans")

--A statement transformer.
local StmtTrans = {}
StmtTrans.__index = StmtTrans
setmetatable(StmtTrans, {__index = SubTrans})
package.loaded[...] = StmtTrans

--Constructor.
--
--@param trans:Trans  Parent transformer.
function StmtTrans.new(trans)
  return setmetatable(SubTrans.new(trans), StmtTrans)
end

--Transform a statement.
--
--@param stmt:Stmt  Statement to transform.
--@return string
function StmtTrans:transform(stmt)
  if stmt.subtype == StmtType.ASYNC then
    return self:_transAsync(stmt)
  elseif stmt.subtype == StmtType.BREAK then
    return self:_transBreak(stmt)
  elseif stmt.subtype == StmtType.CONST then
    return self:_transConst(stmt)
  elseif stmt.subtype == StmtType.DO then
    return self:_transDo(stmt)
  elseif stmt.subtype == StmtType.ENUM then
    return self:_transEnum(stmt)
  elseif stmt.subtype == StmtType.FN then
    return self:_transFn(stmt)
  elseif stmt.subtype == StmtType.FOR then
    return self:_transFor(stmt)
  elseif stmt.subtype == StmtType.FOR_EACH then
    return self:_transForEach(stmt)
  elseif stmt.subtype == StmtType.FROM then
    return self:_transFrom(stmt)
  elseif stmt.subtype == StmtType.IF then
    return self:_transIf(stmt)
  elseif stmt.subtype == StmtType.NEXT then
    return self:_transNext(stmt)
  elseif stmt.subtype == StmtType.RETURN then
    return self:_transReturn(stmt)
  elseif stmt.subtype == StmtType.TYPE then
    return self:_transType(stmt)
  elseif stmt.subtype == StmtType.USE then
    return self:_transUse(stmt)
  elseif stmt.subtype == StmtType.VAR then
    return self:_transVar(stmt)
  elseif stmt.subtype == StmtType.WHILE then
    return self:_transWhile(stmt)
  -- elseif stmt.subtype == StmtType.YIELD then
  --   return self:_transYield(stmt)
  end
end

--Transform a use statement.
--
--@return string
function StmtTrans:_transUse(stmt)
  local code

  --(1) transform
  code = ""

  for _, mod in ipairs(stmt.modules) do
    code = code .. string.format([[import %s from "%s";]], mod.name, mod.path)
  end

  --(2) return
  return code
end

--Transform a from statement.
--
--@return string
function StmtTrans:_transFrom(stmt)
  local code

  --(1) transform
  code = "import {"

  for i, mem in ipairs(stmt.members) do
    code = code .. (i == 1 and "" or ", ")

    if mem.name == mem.as then
      code = code .. mem.name
    else
      code = code .. string.format("%s as %s", mem.name, mem.as)
    end
  end

  code = code .. [[} from "]] .. stmt.module .. [[";]]

  --(2) return
  return code
end

--Transform a break statement.
--
--@return string
function StmtTrans:_transBreak(stmt)
  return "break;"
end

--Transform a next statement.
--
--@return string
function StmtTrans:_transNext(stmt)
  return "continue;"
end

--Transform an enum statement.
--
--@return string
function StmtTrans:_transEnum(enum)
  local code

  --(1) transform
  code = string.format([[
%sclass %s {
  constructor(name, val) {
    Object.defineProperty(this, "name", {value: name, enum: true});
    Object.defineProperty(this, "value", {value: val, enum: true});
  }
}
]],
    self:_transVisib(enum.visib),
    enum.name
  )

  for _, item in ipairs(enum.items) do
    code = code .. string.format(
      [[Object.defineProperty(%s, "%s", {value: new %s("%s", %s), enum: true});]] .. "\n",
      enum.name,
      item.name,
      enum.name,
      item.name,
      (type(item.value) == "string" and string.format([["%s"]], item.value) or item.value)
    )
  end

  --(2) return
  return code
end

function StmtTrans:_transVisib(visib)
  if visib == "export" then
    return "export default "
  elseif visib == "pub" then
    return "export "
  else
    return ""
  end
end

--Transform an async statement.
--
--@param node
--@return string
function StmtTrans:_transAsync(node)
  local code

  --(1) get sentences to run
  if node.catch then
    code = "try "
  else
    code = ""
  end

  code = code .. self:_transBody(node.body)
  code = code .. self:_transCatch(node.catch)

  --(2) return
  return string.format("setImmediate(() => %s);", code)
end

--Transform a var statement.
--
--@return string
function StmtTrans:_transVar(stmt)
  local code

  --(1) transform
  if #stmt.vars > 0 then
    if stmt.visib then
      code = "var "
    else
      code = "let "
    end

    for i, var in ipairs(stmt.vars) do
      code = code .. (i == 1 and "" or ", ") .. var.name

      if var.value then
        code = code .. " = " .. self._.trans:_trans(var.value)
      end
    end

    code = code .. ";"

    if stmt.visib then
      for _, var in ipairs(stmt.vars) do
        code = code .. self:_transVisib(stmt.visib) .. var.name .. ";"
      end
    end
  else
    code = ""
  end

  --(2) return
  return code
end

--Transform a const statement.
--
--@return string
function StmtTrans:_transConst(stmt)
  local code

  --(1) transform
  if #stmt.vars > 0 then
    code = "const "

    for i, var in ipairs(stmt.vars) do
      code = code .. (i == 1 and "" or ", ") ..
             var.name .. " = " .. self._.trans:_trans(var.value)
    end

    code = code .. ";"

    if stmt.visib then
      for _, var in ipairs(stmt.vars) do
        code = code .. self:_transVisib(stmt.visib) .. var.name .. ";"
      end
    end
  else
    code = ""
  end

  --(2) return
  return code
end

--Transform an while statement.
--
--@return string
function StmtTrans:_transWhile(node)
  local trans = self._.trans
  local code

  --(1) transform
  if node.iter then
    code = string.format(
      "for (; %s; %s) ",
      trans:_trans(node.cond),
      trans:_trans(node.iter)
    )
  else
    code = string.format("while (%s) ", trans:_trans(node.cond))
  end

  if node.catch or node.finally then
    code = code .. "try "
  end

  code = code .. self:_transBody(node.body)
  code = code .. self:_transCatch(node.catch)
  code = code .. self:_transFinally(node.finally)

  --(2) return
  return code
end

--Transform a statement body.
--
--2return string
function StmtTrans:_transBody(body)
  local trans = self._.trans
  local code

  --(1) transform
  code = "{"

  for _, sent in ipairs(body) do
    code = code .. trans:_trans(sent, ";")
  end

  code = code .. "}"

  --(2) return
  return code
end

--Transform a catch clause.
--
--@return string
function StmtTrans:_transCatch(catch)
  local trans = self._.trans
  local code

  --(1) transform
  if catch then
    code = string.format(" catch(%s) {", catch.var or "_")

    for _, sent in ipairs(catch.body) do
      code = code .. trans:_trans(sent, ";")
    end

    code = code .. "}"
  end

  --(2) return
  return code or ""
end

--Transform a finally clause.
--
--@return string
function StmtTrans:_transFinally(fin)
  local trans = self._.trans
  local code

  --(1) transform
  if fin then
    code = " finally {"

    for _, sent in ipairs(fin.body) do
      code = code .. trans:_trans(sent, ";")
    end

    code = code .. "}"
  end

  --(2) return
  return code or ""
end

--Transform a do statement.
--
--@return string
function StmtTrans:_transDo(node)
  local trans = self._.trans
  local code

  --(1) transform
  if node.catch or node.finally then
    if node.cond then
      code = "do try "
    else
      code = "try "
    end
  else
    code = "do "
  end

  code = code .. self:_transBody(node.body)
  code = code .. self:_transCatch(node.catch)
  code = code .. self:_transFinally(node.finally)

  if node.cond then
    code = code .. string.format(" while (%s);", trans:_trans(node.cond))
  end

  --(2) return
  return code
end

--Transfor a for statement.
--
--@return string
function StmtTrans:_transFor(stmt)
  local trans = self._.trans
  local code

  --(1) transform
  code = "for (let "

  for i, var in ipairs(stmt.def) do
    code = code .. (i == 1 and "" or ", ") .. var.name

    if var.value then
      code = code .. " = " .. trans:_trans(var.value)
    end
  end

  code = code .. "; " .. trans:_trans(stmt.cond) .. "; "

  if stmt.iter then
    code = code .. trans:_trans(stmt.iter)
  end

  code = code .. ") "

  if stmt.catch or stmt.finally then
    code = code .. "try "
  end

  code = code .. self:_transBody(stmt.body)
  code = code .. self:_transCatch(stmt.catch)
  code = code .. self:_transFinally(stmt.finally)

  --(2) return
  return code
end

--Transform a for each statement.
--
--@return string
function StmtTrans:_transForEach(node)
  local trans = self._.trans
  local code

  --(1) transform
  if node.key then
    local iter = self:_getRandomName()

    code = string.format(
      "const %s = %s; for (let %s in %s) { let %s = %s[%s]; ",
      iter,
      trans:_trans(node.iter),
      node.key,
      iter,
      node.value,
      iter,
      node.key
    )
  else
    code = string.format(
      "for (let %s of %s) ",
      node.value,
      trans:_trans(node.iter)
    )
  end

  if node.catch or node.finally then
    code = code .. "try "
  end

  code = code .. self:_transBody(node.body)
  code = code .. self:_transCatch(node.catch)
  code = code .. self:_transFinally(node.finally)

  if node.key then
    code = code .. " }"
  end

  --(2) return
  return code
end

--Transform a return statement.
--
--@return string
function StmtTrans:_transReturn(node)
  local trans = self._.trans
  local code

  --(1) transform
  code = "return"

  if #node.values == 1 then
    code = code .. " " .. trans:_trans(node.values[1])
  end

  code = code .. ";"

  --(2) return
  return code
end

--Transform a type statement.
--
--@return string
function StmtTrans:_transType(stmt)
  local code

  --(1) transform
  --$class
  code = string.format("const $%s = class %s", stmt.name, stmt.name)
  if stmt.base then
    code = code .. " extends " .. stmt.base
  end

  code = code .. " {\n"

  code = code .. string.format("  constructor(%s) { ", self:_transParams(stmt.params))
  code = code .. self:_transParamsCheck(stmt.params)
  code = code .. self:_transSuperConstructor(stmt.bargs)
  code = code .. self:_transSelfParams(stmt.params)
  if stmt.catch or stmt.finally then code = code .. " try " end
  code = code .. self:_transBody(stmt.body)
  code = code .. self:_transCatch(stmt.catch)
  code = code .. self:_transFinally(stmt.finally)
  code = code .. "  }\n"
  code = code .. "};\n"

  --class proxy
  code = code .. string.format(
    "const %s = new Proxy($%s, { apply(receiver, self, args) { return new $%s(...args); } });",
    stmt.name,
    stmt.name,
    stmt.name
  )

  if stmt.visib == "export" then
    code = code .. string.format("export default %s;", stmt.name)
  end

  --(2) return
  return code
end

--Transform function parameters.
--
--@return string
function StmtTrans:_transParams(params)
  local trans = self._.trans
  local code

  --(1) transform
  if #params > 0 then
    code = ""

    for i, p in ipairs(params) do
      if i > 1 then
        code = code .. ", "
      end

      if p.modifier == "..." then
        code = code .. "..."
      end

      code = code .. transName(p.name)

      if p.value then
        code = code .. " = " .. trans:_trans(p.value)
      end
    end
  end

  --(2) return
  return code or ""
end

--Return the code for checking the function parameters.
--
--@return string
function StmtTrans:_transParamsCheck(params)
  local function toJs(obj)
    local repr

    repr = "{"
    for ix, val in ipairs(obj) do
      repr = repr .. (ix == 1 and "" or ", ") .. val.name .. ": " .. val.type
    end
    repr = repr .. "}"

    return repr
  end

  local code

  --(1) transform
  if #params > 0 then
    code = ""

    for _, p in ipairs(params) do
      if not p.optional and p.modifier ~= "..." then  --mandatory parameter with(out) type check
        if type(p.type) == "table" then
          code = code .. string.format(
            [[dogma.paramExpectedToHave("%s", %s, %s);]],
            transName(p.name),
            transName(p.name),
            toJs(p.type)
          )
        else
          code = code .. string.format(
            [[dogma.paramExpected("%s", %s, %s);]],
            transName(p.name),
            transName(p.name),
            p.type or "null"
          )
        end
      elseif p.type then  --optional parameter with type check
        if type(p.type) == "table" then
          code = code .. string.format(
            [[dogma.paramExpectedToHave("%s", %s, %s);]],
            transName(p.name),
            transName(p.name),
            toJs(p.type)
          )
        else
          code = code .. string.format(
            [[dogma.paramExpectedToBe("%s", %s, %s);]],
            transName(p.name),
            transName(p.name),
            p.type
          )
        end
      end
    end
  end

  --(2) return
  return code or ""
end

--Return the code for setting $ or : attributes from parameters.
--
--@return string
function StmtTrans:_transSelfParams(params)
  local code

  --(1) transform
  if #params > 0 then
    code = ""

    for _, p in ipairs(params) do
      if p.modifier == "$" then
        code = code .. string.format(
          [[Object.defineProperty(this, "%s", {value: %s, enum: true, writable: %s});]],
          transName(p.name),
          transName(p.name),
          not p.const
        )
      elseif p.modifier == ":" then
        code = code .. string.format(
          [[Object.defineProperty(this, "_%s", {value: %s, writable: %s});]],
          p.name,
          p.name,
          not p.const
        )
      end
    end
  end

  --(2) return
  return code or ""
end

--Return a call to the super constructor.
--
--@return string
function StmtTrans:_transSuperConstructor(bargs)
  local trans = self._.trans
  local code

  --(1) Transform
  if bargs then
    if #bargs == 0 then
      code = "super();"
    else
      code = "super("

      for i, a in ipairs(bargs) do
        code = code .. (i == 1 and "" or ", ") .. trans:_trans(a)
      end

      code =  code .. ");"
    end
  end

  --(2) return
  return code or ""
end

--Transform a fn statement.
--
--@return string
function StmtTrans:_transFn(stmt)
  if stmt.itype then
    return self:_transTypeFn(stmt)
  else
    return self:_transStdFn(stmt)
  end
end

function StmtTrans:_transStdFn(fn)
  local code

  --(1) transform
  code = string.format(
    "%sfunction %s(%s) { ",
    self:_transVisib(fn.visib),
    fn.name,
    self:_transParams(fn.params)
  )

  code = code .. self:_transReturnVar(fn)
  code = code .. self:_transParamsCheck(fn.params)
  code = code .. self:_transSelfParams(fn.params)
  if fn.catch or fn.finally then code = code .. " try " end
  code = code .. self:_transBody(fn.body)
  code = code .. self:_transCatch(fn.catch)
  code = code .. self:_transFinally(fn.finally)
  if fn.rvar then
    code = code .. string.format(" return %s;", fn.rvar == "self" and "this" or fn.rvar)
  end
  code = code .. " }"

  --(2) return
  return code
end

function StmtTrans:_transTypeFn(stmt)
  if tablex.find(stmt.annots, "prop") then
    return self:_transProp(stmt)
  else
    return self:_transMethod(stmt)
  end
end

function StmtTrans:_transProp(stmt)
  local code

  --(1) transform
  code = string.format(
    [[Object.defineProperty(%s.prototype, "%s%s", {enum: %s, get: function() { ]],
    stmt.itype,
    stmt.visib == "pub" and "" or "_",
    stmt.name,
    stmt.visib == "pub"
  )

  if tablex.find(stmt.annots, "abstract") then
    code = code .. "abstract();"
  else
    code = code .. self:_transReturnVar(stmt)
    if stmt.catch or stmt.finally then code = code .. " try " end
    code = code .. self:_transBody(stmt.body)
    code = code .. self:_transCatch(stmt.catch)
    code = code .. self:_transFinally(stmt.finally)

    if stmt.rvar then
      code = code .. string.format(" return %s;", stmt.rvar == "self" and "this" or stmt.rvar)
    end
  end

  code = code .. " }});"

  --(2) return
  return code
end

function StmtTrans:_transMethod(stmt)
  local code

  --(1) transform
  if tablex.find(stmt.annots, "abstract") then
    code = string.format(
      "%s.prototype.%s%s = function() { abstract(); };",
      stmt.itype,
      stmt.visib == "pub" and "" or "_",
      stmt.name
    )
  else
    if tablex.find(stmt.annots, "static") then
      code = string.format(
        "%s.%s%s = function(%s) { ",
        stmt.itype,
        stmt.visib == "pub" and "" or "_",
        stmt.name,
        self:_transParams(stmt.params)
      )
    else
      code = string.format(
        "%s.prototype.%s%s = function(%s) { ",
        stmt.itype,
        stmt.visib == "pub" and "" or "_",
        stmt.name,
        self:_transParams(stmt.params)
      )
    end

    code = code .. self:_transReturnVar(stmt)
    code = code .. self:_transParamsCheck(stmt.params)
    code = code .. self:_transSelfParams(stmt.params)

    if stmt.catch or stmt.finally then code = code .. " try " end
    code = code .. self:_transBody(stmt.body)
    code = code .. self:_transCatch(stmt.catch)
    code = code .. self:_transFinally(stmt.finally)

    if stmt.rvar then
      code = code .. string.format(" return %s;", stmt.rvar == "self" and "this" or stmt.rvar)
    end

    code = code .. " };"
  end

  --(2) return
  return code
end

function StmtTrans:_transReturnVar(fn)
  local code

  --(1) transform
  code = ""

  if fn.rvar then
    if fn.rvar ~= "self" and not fn.params:has(fn.rvar) then
      code = string.format("let %s;", fn.rvar)
    end
  end

  --(2) return
  return code
end

--Transform an if statement.
--
--@return string
function StmtTrans:_transIf(stmt)
  local trans = self._.trans
  local code

  --(1) transform
  code = string.format(
    "if (%s) %s",
    trans:_trans(stmt.cond),
    self:_transBody(stmt.body)
  )

  if stmt.elif then
    for _, cl in ipairs(stmt.elif) do
      code = code .. string.format(
        " else if (%s) %s",
        trans:_trans(cl.cond),
        self:_transBody(cl.body)
      )
    end
  end

  if stmt.el then
    code = code .. " else " .. self:_transBody(stmt.el)
  end

  --(2) return
  return code
end
