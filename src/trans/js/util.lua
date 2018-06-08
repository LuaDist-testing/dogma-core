--imports
local tablex = require("pl.tablex")

package.loaded[...] = {
  transName = function(name)
    local KEYWORDS = {
      "abstract", "await",
      "break",
      "case", "char", "class", "const", "continue",
      "debugger", "default", "do",
      "else", "enum", "export", "extends",
      "final", "finally", "for", "function",
      "goto",
      "if", "implements", "import", "in", "instanceof", "interface",
      "let",
      "native", "new",
      "private", "protected", "public",
      "return",
      "static", "super", "switch",
      "this", "throw", "transient", "try", "typeof",
      "var", "volatile",
      "while", "with",
      "yield"
    }

    if tablex.find(KEYWORDS, name) then
      return name .. "_"
    else
      return name
    end
  end
}
