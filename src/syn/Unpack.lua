--imports
local Sent = require("dogma.syn._.Sent")
local SentType = require("dogma.syn.SentType")

--An unpack sentence.
local Unpack = {}
Unpack.__index = Unpack
setmetatable(Unpack, {__index = Sent})
package.loaded[...] = Unpack

--Constructor.
--
--@param ln:number
--@param col:number
--@param sub:string     Unpack type: [] or {}.
--@param vars:array
--@param assign:string  =, := or ?=.
--@param exp:Exp
function Unpack.new(ln, col, sub, vars, assign, exp)
  local self

  --(1) create
  self = setmetatable(Sent.new(SentType.UNPACK, ln, col), Unpack)
  self.subtype = sub
  self.vars = vars
  self.assign = assign
  self.exp = exp

  --(2) return
  return self
end
