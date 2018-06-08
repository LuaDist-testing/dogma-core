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

--Return a random name.
--
--@return string
function SubTrans._getRandomName()
  math.randomseed(os.time())
  return "$aux" .. os.time() .. math.random(1, 10000)
end
