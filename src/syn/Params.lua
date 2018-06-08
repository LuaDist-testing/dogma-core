--A parameters list.
local Params = {}
Params.__index = Params
setmetatable(Params, {__index = table})
package.loaded[...] = Params

--Constructor.
function Params.new()
  return setmetatable({}, Params)
end

--Check whether a parameter exists.
--
--@param name:string  Parameter name.
--@return bool
function Params:has(name)
  local res

  --(1) check
  res = false

  for _, param in ipairs(self) do
    if param.name == name then
      res = true
      break
    end
  end

  --(2) return
  return res
end
