local AdvancedList = {}
AdvancedList.__index = AdvancedList
package.loaded[...] = AdvancedList

function AdvancedList.new(max)
  --(1) arguments
  if max == nil then error("max expected.") end

  --(2) return
  return setmetatable({
    _ = {
      max = max,
      items = {}
    }
  }, AdvancedList)
end

function AdvancedList:__len()
  return #self._.items
end

function AdvancedList:insert(item)
  if #self == self._.max then
    error("list already full.")
  end

  table.insert(self._.items, 1, item)
end

function AdvancedList:remove()
  if #self == 0 then
    error("empty list, nothing to remove.")
  end

  return table.remove(self._.items, 1)
end
