--A function parameter.
local Param = {}
Param.__index = Param
package.loaded[...] = Param

--Constructor.
--
--@param const:bool
--@param mod?:string $ or : or ....
--@param name:string
--@param opt:bool
--@param dtype?:Exp
--@param val?:Exp
function Param.new(const, mod, name, opt, dtype, val)
  local self

  --(1) create
  self = setmetatable({
    const = const,
    modifier = mod,  --$ or : or ...
    name = name,
    optional = not not opt,
    type = dtype,
    value = val
  }, Param)

  if self.modifier == "." then
    self.modifier = "$"
  end

  --(2) return
  return self
end
