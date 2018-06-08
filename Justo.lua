--imports
local catalog = require("justo").catalog
local cli = require("justo.plugin.cli")

--catalog
catalog:macro("lint", {
  {title = "Check Lua code", task = cli, params = {cmd = "luacheck --codes ."}},
  {title = "Check rockspec", task = cli, params = {cmd = "luarocks lint *.rockspec"}}
}):desc("Lint source code.")

catalog:call("make", cli, {
  cmd = "luarocks make --local"
}):desc("make and install the rock.")

catalog:macro("test", {
  {title = "AdvancedList", task = "./test/unit/lex/AdvancedList"},
  {title = "ProcessedList", task = "./test/unit/lex/ProcessedList"},
  {title = "Reader", task = "./test/unit/lex/Reader"},
  {title = "Lexer", task = "./test/unit/lex/Lexer"},

  {title = "Parser", task = "./test/unit/syn/Parser"},
  {title = "DirectiveParser", task = "./test/unit/syn/DirectiveParser"},
  {title = "ExpParser", task = "./test/unit/syn/ExpParser"},
  {title = "StmtParser", task = "./test/unit/syn/StmtParser"},
  {title = "UnpackParser", task = "./test/unit/syn/UnpackParser"},
  {title = "NonTerminal", task = "./test/unit/syn/NonTerminal"},
  {title = "CallOp", task = "./test/unit/syn/CallOp"},

  {title = "Trans", task = "./test/unit/trans/Trans"},
  {title = "js.DirectiveTrans", task = "./test/unit/trans/js/DirectiveTrans"},
  {title = "js.ExpTrans", task = "./test/unit/trans/js/ExpTrans"},
  {title = "js.StmtTrans", task = "./test/unit/trans/js/StmtTrans"},
  {title = "js.UnpackTrans", task = "./test/unit/trans/js/UnpackTrans"}
}):desc("Unit testing.")

catalog:macro("prepub", {
  {title = "Prepare for packing", task = cli, params = {cmd = "git congif --local credential.helper 'cache --timeout 3600'"}}
}):desc("Prepare for packing rock.")

catalog:macro("default", {
  {title = "Lint code", task = "lint"},
  {title = "Make and install", task = "make"},
  {title = "Test", task = "test"}
}):desc("Lint, make and install.")
