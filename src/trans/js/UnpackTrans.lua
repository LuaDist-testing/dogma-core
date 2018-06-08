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
    else
      return self:_transReadOnlyFieldsList(sent)
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

  --(1) visibility?
  if sent.visib == nil then
    code = ""
  elseif sent.visib == "export" then
    code = "export default "
  elseif sent.visib == "pub" then
    code = "export "
  end

  --(2) var or const definition?
  if sent.def == "var" then
    code = code .. "let "
  elseif sent.def == "const" then
    code = code .. "const "
  end

  --(3) variables
  code = code .. "["

  for i, var in ipairs(sent.vars) do
    local name = var.name
    local prefix

    if name:find("^[$.]") then
      prefix = "this."
      name = name:sub(2)
    elseif name:find("^:") then
      prefix = "this._"
      name = name:sub(2)
    else
      prefix = ""
    end

    code = code .. (i == 1 and "" or ", ") .. string.format(
      "%s%s%s%s",
      var.rest and "..." or "",
      prefix,
      name,
      var.value and (" = " .. trans:_trans(var.value)) or ""
    )
  end

  code = code .. "]"

  --(4) expression
  code = code .. " = " .. trans:_trans(sent.exp) .. ";"

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
  code = string.format("const %s = %s;", valVar, trans:_trans(sent.exp))

  --(2) unpack
  for ix, fld in ipairs(sent.vars) do
    local name = fld.name

    if fld.name:find("^[$.]") then
      name = fld.name:sub(2)

      code = code .. string.format(
        'Object.defineProperty(this, "%s", {value: %s[%s], enum: true});',
        name,
        valVar,
        ix - 1
      )
    elseif fld.name:find("^:") then
      name = fld.name:sub(2)

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

--Transform {...} = Exp.
--
--@param sent:Unpack
--@return string
function UnpackTrans:_transMap(sent)
  local trans = self._.trans
  local code

  --(1) visibility?
  if sent.visib == nil then
    code = ""
  elseif sent.visib == "export" then
    code = "export default "
  elseif sent.visib == "pub" then
    code = "export "
  end

  --(2) var or const definition?
  if sent.def == "var" then
    code = code .. "let "
  elseif sent.def == "const" then
    code = code .. "const "
  end

  --(3) variables
  if not sent.def then
    code = "({"
  else
    code = code .. "{"
  end

  for i, var in ipairs(sent.vars) do
    if sent.def then
      code = code .. (i == 1 and "" or ", ") .. string.format(
        "%s%s",
        var.name,
        var.value and (" = " .. trans:_trans(var.value)) or ""
      )
    else
      local name = var.name
      local prefix

      if name:find("^[$.]") then
        prefix = "this."
        name = name:sub(2)
      elseif name:find("^:") then
        prefix = "this._"
        name = name:sub(2)
      else
        prefix = ""
      end

      code = code .. (i == 1 and "" or ", ") .. string.format(
        "%s: %s%s%s",
        name,
        prefix,
        name,
        var.value and (" = " .. trans:_trans(var.value)) or ""
      )
    end
  end

  code = code .. "}"

  --(4) expression
  code = code .. " = " .. trans:_trans(sent.exp)

  if not sent.def then
    code = code .. ")"
  end

  code = code .. ";"

  --(5) return
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

    if fld.name:find("^[$.]") then
      name = fld.name:sub(2)

      code = code .. string.format(
        'Object.defineProperty(this, "%s", {value: %s["%s"], enum: true});',
        name,
        valVar,
        name
      )
    elseif fld.name:find("^:") then
      name = fld.name:sub(2)

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
