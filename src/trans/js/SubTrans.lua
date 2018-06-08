--A sub transformer.
local SubTrans = {}
SubTrans.__index = SubTrans
package.loaded[...] = SubTrans

--Constructor.
--
--@param trans:Trans  Parent transformer.
function SubTrans.new(trans)
  return setmetatable({
    _ = {
      trans = trans
    }
  }, SubTrans)
end

--Last seed used.
local lastSeed = os.time()

--Return a random name.
--
--@return string
function SubTrans._getRandomName()
  lastSeed = math.random(1, lastSeed)
  math.randomseed(lastSeed)
  return "$aux" .. os.time() .. math.random(1, 10000)
end

--Transform a data access.
--
--@param def:DataAccess
--@return string, string
function SubTrans:_transDataAccess(def)
  local prefix

  if def.mod == "." then
    prefix = "this."
  elseif def.mod == ":" then
    prefix = "this._"
  else
    prefix = ""
  end

  return prefix .. def.name:gsub(":", "._")
end
