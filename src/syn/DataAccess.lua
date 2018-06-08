--Data access.
local DataAccess = {}
DataAccess.__index = DataAccess
package.loaded[...] = DataAccess

--Constructor.
function DataAccess.new(mod, name, value)
  return setmetatable({mod = mod, name = name, value = value}, DataAccess)
end
