--A sentence.
local Sent = {}
Sent.__index = Sent
package.loaded[...] = Sent

--Constructor.
function Sent.new(t, ln, col)
  return setmetatable({
    type = t,
    line = ln,
    col = col,
    _ = {}
  }, Sent)
end
