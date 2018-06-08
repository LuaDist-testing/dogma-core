local List = {}
List.__index = List
package.loaded[...] = List

function List.new(max)
  --(1) arguments
  if max == nil then error("max expected.") end

  --(2) return
  return setmetatable({
    _ = {
      max = max,
      items = {}
    }
  }, List)
end

function List:__len()
  return #self._.items
end

function List:insert(item)
  if #self == self._.max then
    table.remove(self._.items, 1)
  end

  table.insert(self._.items, item)
end

function List:remove()
  if #self == 0 then
    error("internal error: invalid remove from previous list.")
  end

  return table.remove(self._.items)
end
