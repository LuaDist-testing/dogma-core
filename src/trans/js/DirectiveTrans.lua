--imports
local DirectiveType = require("dogma.syn.DirectiveType")
local SubTrans = require("dogma.trans.js._.SubTrans")

--A directive transformer.
local DirectiveTrans = {}
DirectiveTrans.__index = DirectiveTrans
setmetatable(DirectiveTrans, {__index = SubTrans})
package.loaded[...] = DirectiveTrans

--Constructor.
--
--@param trans:Trans  Parent transformer.
function DirectiveTrans.new(trans)
  return setmetatable(SubTrans.new(trans), DirectiveTrans)
end

--Transform a directive.
--
--@param dir:Directive  Directive to transform.
--@return string
function DirectiveTrans:transform(dir)
  if dir.subtype == DirectiveType.IF then
    return self:_transIf(dir)
  elseif dir.subtype == DirectiveType.RUNWITH then
    return self:_transRunWith(dir)
  end
end

--Transform an if directive.
--
--@return string
function DirectiveTrans:_transIf(dir)
  local function transform(sents)
    local trans = self._.trans
    local code

    code = ""
    for _, sent in ipairs(sents) do
      code = code .. trans:_trans(sent)
    end

    return code
  end

  --(1) transform if
  local code

  if dir.cond == "js" or (dir.cond:find("^not") and dir.cond ~= "not js") then
    code = transform(dir.body)
  elseif dir.el then
    code = transform(dir.el)
  else
    code = ""
  end

  --(2) return
  return code
end

--Transform a runWith directive.
--
--@return string
function DirectiveTrans:_transRunWith(dir)
  return "#!" .. dir.cmd
end
