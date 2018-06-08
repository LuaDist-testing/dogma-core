--imports
local SubTrans = require("dogma.trans.js._.SubTrans")

--An unpack sentence transformer.
local UnpackTrans = {}
UnpackTrans.__index = UnpackTrans
setmetatable(UnpackTrans, {__index = SubTrans})
package.loaded[...] = UnpackTrans

--Constructor.
--
--@param trans:Trans  Parent transformer.
function UnpackTrans.new(trans)
  return setmetatable(SubTrans.new(trans), UnpackTrans)
end

--Transform an unpack sentence.
--
--@param sent:Unpack  Sentence to transform.
--@return string
function UnpackTrans:transform(sent)
  if sent.subtype == "[]" then
    if sent.assign == "=" then
      return self:_transList(sent)
    elseif sent.assign == ":=" then
      return self:_transReadOnlyFieldsList(sent)
    elseif sent.assign == ".=" then
      return self:_transPropList(sent)
    else
      return self:_transOptionalList(sent)
    end
  elseif sent.subtype == "{}" then
    if sent.assign == "=" then
      return self:_transMap(sent)
    else
      return self:_transReadOnlyFieldsMap(sent)
    end
  end
end

--Transform [...] = Exp.
--
--@param sent:Unpack
--@return string
function UnpackTrans:_transList(sent)
  local trans = self._.trans
  local code

  --(1) variables
  code = "["

  for i, def in ipairs(sent.vars) do
    local var = self:_transDataAccess(def)

    code = code .. (i == 1 and "" or ", ") .. string.format(
      "%s%s%s",
      def.mod == "..." and "..." or "",
      var,
      def.value and (" = " .. trans:_trans(def.value)) or ""
    )
  end

  code = code .. "]"

  --(4) expression
  code = code .. string.format(
    " = dogma.getArrayToUnpack(%s, %s);",
    trans:_trans(sent.exp),
    #sent.vars
  )

  --(5) return
  return code
end

--Transform [...] := Exp.
--
--@param sent:Unpack
--@return string
function UnpackTrans:_transReadOnlyFieldsList(sent)
  local trans = self._.trans
  local code, valVar

  --(1) list value
  valVar = self:_getRandomName()
  code = string.format(
    "const %s = dogma.getArrayToUnpack(%s, %s);",
    valVar,
    trans:_trans(sent.exp),
    #sent.vars
  )

  --(2) unpack
  for ix, fld in ipairs(sent.vars) do
    local name = fld.name:gsub(":", "._")

    if fld.mod == "." then
      code = code .. string.format(
        'Object.defineProperty(this, "%s", {value: %s[%s], enum: true});',
        name,
        valVar,
        ix - 1
      )
    elseif fld.mod == ":" then
      code = code .. string.format(
        'Object.defineProperty(this, "_%s", {value: %s[%s]});',
        name,
        valVar,
        ix - 1
      )
    else
      code = code .. string.format('%s = %s[%s];', name, valVar, ix - 1)
    end
  end

  --(3) return
  return code
end

--Transform [...] ?= Exp
--
--@param sent:Unpack
--@return string
function UnpackTrans:_transOptionalList(sent)
  local trans = self._.trans
  local code, valVar

  --(1) list value
  valVar = self:_getRandomName()
  code = string.format(
    "const %s = dogma.getArrayToUnpack(%s, %s);",
    valVar,
    trans:_trans(sent.exp),
    #sent.vars
  )

  --(2) unpack
  local left, right = "", ""

  for ix, def in ipairs(sent.vars) do
    local js = self:_transDataAccess(def)

    if ix > 1 then
      left = left .. ", "
      right = right .. ", "
    end

    left = left .. js
    right = right .. string.format(
      "%s != null ? %s : %s[%s]",
      js,
      js,
      valVar,
      ix - 1
    )
  end

  code = code .. string.format("[%s] = [%s];", left, right)

  --(3) return
  return code
end

--Transform [...] .= Exp.
--
--@param sent:Unpack
--@return string
function UnpackTrans:_transPropList(sent)
  local trans = self._.trans
  local code, valVar

  --(1) list value
  valVar = self:_getRandomName()
  code = string.format(
    "const %s = dogma.getArrayToUnpack(%s, %s);",
    valVar,
    trans:_trans(sent.exp),
    #sent.vars
  )

  --(2) unpack
  for ix, def in ipairs(sent.vars) do
    if def.name:find("[:.]") then
      local obj = def.name:match("(.+)[:.][^:.]+$")
      local fld = def.name:match(".+[:.]([^:.]+)$")

      code = code .. string.format(
        'Object.defineProperty(%s, "_%s", {value: %s[%s], writable: true});',
        obj,
        fld,
        valVar,
        ix - 1
      )

      code = code .. string.format(
        'Object.defineProperty(%s, "%s", {enum: true, get() { return %s._%s; }});',
        obj,
        fld,
        obj,
        fld
      )
    else
      code = code .. string.format(
        'Object.defineProperty(this, "_%s", {value: %s[%s], writable: true});',
        def.name,
        valVar,
        ix - 1
      )

      code = code .. string.format(
        'Object.defineProperty(this, "%s", {enum: true, get() { return this._%s; }});',
        def.name,
        def.name
      )
    end
  end

  --(3) return
  return code
end

--Transform {...} = Exp.
--
--@param sent:Unpack
--@return string
function UnpackTrans:_transMap(sent)
  local trans = self._.trans
  local code

  --(1) variables
  code = "({"

  for i, var in ipairs(sent.vars) do
    code = code .. (i == 1 and "" or ", ") .. string.format(
      "%s: %s%s",
      var.name,
      self:_transDataAccess(var),
      var.value and (" = " .. trans:_trans(var.value)) or ""
    )
  end

  code = code .. "}"

  --(2) expression
  code = code .. " = " .. trans:_trans(sent.exp) .. ");"

  --(3) return
  return code
end

--Transform {...} := Exp.
--
--@param sent:Unpack
--@return string
function UnpackTrans:_transReadOnlyFieldsMap(sent)
  local trans = self._.trans
  local code, valVar

  --(1) list value
  valVar = self:_getRandomName()
  code = string.format("const %s = %s;", valVar, trans:_trans(sent.exp))

  --(2) unpack
  for _, fld in ipairs(sent.vars) do
    local name = fld.name

    if fld.mod == "." then
      code = code .. string.format(
        'Object.defineProperty(this, "%s", {value: %s["%s"], enum: true});',
        name,
        valVar,
        name
      )
    elseif fld.mod == ":" then
      code = code .. string.format(
        'Object.defineProperty(this, "_%s", {value: %s["%s"]});',
        name,
        valVar,
        name
      )
    else
      code = code .. string.format('%s = %s["%s"];', name, valVar, name)
    end
  end

  --(3) return
  return code
end
