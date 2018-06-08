--imports
local NonTerminal = require("dogma.syn._.NonTerminal")
local NonTerminalType = require("dogma.syn.NonTerminalType")

--An operator.
local Op = {}
Op.__index = Op
setmetatable(Op, {__index = NonTerminal})
package.loaded[...] = Op

--Constructor.
--
--@param arity:string       Arity: u, b, t, n.
--@param optor:string       The operator.
function Op.new(arity, tok)
  local self

  --(1) create
  self = setmetatable(NonTerminal.new(NonTerminalType.OP, tok), Op)
  self.op = tok.value
  self.arity = arity
  local desc = self:getDesc()
  self.assoc = desc.assoc
  self.prec = desc.prec

  --(2) return
  return self
end

--Return the operator descriptor: assoc and prec.
function Op:getDesc()
  local OPS = {
    ["u ."] = {assoc = "r", prec = 20},
    ["u :"] = {assoc = "r", prec = 20},
    ["u <<<"] = {assoc = "r", prec = 20},
    ["u >>>"] = {assoc = "r", prec = 20},

    ["b ."] = {assoc = "l", prec = 19},
    ["b :"] = {assoc = "l", prec = 19},
    ["n .{}"] = {assoc = "l", prec = 19},
    ["b ?"] = {assoc = "l", prec = 19},
    ["b []"] = {assoc = "l", prec = 19},  --index
    ["t []"] = {assoc = "l", prec = 19},  --index
    ["n ()"] = {assoc = "l", prec = 19},  --call
    ["n {}"] = {assoc = "l", prec = 19},  --exp{}

    ["u !"] = {assoc = "r", prec = 18},
    ["u not"] = {assoc = "r", prec = 18},
    ["u ~"] = {assoc = "r", prec = 18},
    ["u +"] = {assoc = "r", prec = 18},
    ["u -"] = {assoc = "r", prec = 18},

    ["b **"] = {assoc = "r", prec = 17},

    ["b *"] = {assoc = "l", prec = 16},
    ["b /"] = {assoc = "l", prec = 16},
    ["b %"] = {assoc = "l", prec = 16},

    ["b +"] = {assoc = "l", prec = 15},
    ["b -"] = {assoc = "l", prec = 15},

    ["b <<"] = {assoc = "l", prec = 14},
    ["b >>"] = {assoc = "l", prec = 14},
    ["b <<<"] = {assoc = "l", prec = 14},
    ["b >>>"] = {assoc = "l", prec = 14},

    ["b <"] = {assoc = "l", prec = 13},
    ["b <="] = {assoc = "l", prec = 13},
    ["b >"] = {assoc = "l", prec = 13},
    ["b >="] = {assoc = "l", prec = 13},
    ["b in"] = {assoc = "l", prec = 13},
    ["b notin"] = {assoc = "l", prec = 13},
    ["b is"] = {assoc = "l", prec = 13},
    ["b isnot"] = {assoc = "l", prec = 13},
    ["b like"] = {assoc = "l", prec = 13},
    ["b notlike"] = {assoc = "l", prec = 13},

    ["b =="] = {assoc = "l", prec = 12},
    ["b ==="] = {assoc = "l", prec = 12},
    ["b =~"] = {assoc = "l", prec = 12},
    ["b !="] = {assoc = "l", prec = 12},
    ["b !=="] = {assoc = "l", prec = 12},
    ["b !~"] = {assoc = "l", prec = 12},

    ["b &"] = {assoc = "l", prec = 11},
    ["b ^"] = {assoc = "l", prec = 10},
    ["b |"] = {assoc = "l", prec = 9},

    ["b &&"] = {assoc = "l", prec = 8},
    ["b and"] = {assoc = "l", prec = 8},

    ["b ||"] = {assoc = "l", prec = 7},
    ["b or"] = {assoc = "l", prec = 7},

    ["b ="] = {assoc = "r", prec = 6},
    ["b :="] = {assoc = "r", prec = 6},
    ["b .="] = {assoc = "r", prec = 6},
    ["b +="] = {assoc = "r", prec = 6},
    ["b -="] = {assoc = "r", prec = 6},
    ["b *="] = {assoc = "r", prec = 6},
    ["b **="] = {assoc = "r", prec = 6},
    ["b /="] = {assoc = "r", prec = 6},
    ["b %="] = {assoc = "r", prec = 6},
    ["b <<="] = {assoc = "r", prec = 6},
    ["b >>="] = {assoc = "r", prec = 6},
    ["b &="] = {assoc = "r", prec = 6},
    ["b |="] = {assoc = "r", prec = 6},
    ["b ^="] = {assoc = "r", prec = 6},
    ["b ?="] = {assoc = "r", prec = 6},

    ["u ..."] = {assoc = "r", prec = 5}
  }

  return OPS[self.arity .. " " .. self.op]
end
