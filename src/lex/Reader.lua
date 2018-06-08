--imports
local stringx = require("pl.stringx")
local Char = require("dogma.lex._.Char")
local ProcessedList = require("dogma.lex._.ProcessedList")
local AdvancedList = require("dogma.lex._.AdvancedList")

--A text reader.
local Reader = {}
Reader.__index = Reader
package.loaded[...] = Reader

--Constructor.
function Reader.new(txt)
  return setmetatable({
    _ = {
      text = stringx.split(txt, "\n"),
      line = 1,
      col = 1,
      processed = ProcessedList.new(3),
      char = nil,
      advanced = AdvancedList.new(3),
    }
  }, Reader)
end

--Check whether the lexer has some char to shift.
--
--@return bool
function Reader:_hasCharToShift()
  return #self._.advanced > 0
end

--Read the next character.
--
--@return Char
function Reader:next()
  --(1) read
  if self:_hasCharToShift() then
    self:_shift()
  else
    local ln = self._.text[self._.line]

    if ln then
      if self._.col > #ln then
        self:_backUp()
        self._.char = Char.new(self._.line, self._.col, "\n")
        self._.line = self._.line + 1
        self._.col = 1
      else
        self:_backUp()
        self._.char = Char.new(self._.line, self._.col, ln:sub(self._.col, self._.col))
        self._.col = self._.col + 1
      end
    else  --end of input
      self:_backUp()
      self._.char = nil
    end
  end

  --(2) return
  return self._.char
end

--Shift a char: <- processed <- current <- advanced
function Reader:_shift()
  --(1) pre
  if #self._.advanced == 0 then
    error("no advanced char to shift.")
  end

  --(2) current to processed
  if self._.char then
    self._.processed:insert(self._.char)
  end

  --(3) advanced to current
  self._.char = self._.advanced:remove()
end

--Unshift a char: processed -> current -> advanced
function Reader:unshift()
  --(1) current to advanced
  if self._.char then
    self._.advanced:insert(self._.char)
  end

  --(2) last processed to current
  if #self._.processed == 0 then
    self._.char = nil
  else
    self._.char = self._.processed:remove()
  end
end

--Shift current char to processed chars: processed <- char.
function Reader:_backUp()
  if self._.char then
    self._.processed:insert(self._.char)
  end
end
