package = "lua-resty-console"
version = "0.1.0-1"
source = {
   url = "https://github.com/nicoster/lua-resty-console",
   tag = "v0.1.0"
}
description = {
   summary = "Interactive console (REPL) for Openresty to inspect Lua VM internal state, to run lua code, to invoke functions and more",
   homepage = "https://github.com/nicoster/lua-resty-console",
   license = "MIT <http://opensource.org/licenses/MIT>"
}
dependencies = {
   "lua-hiredis >= 0.2.1",
   "inspect >= 2.0",
}

build = {
   type = "builtin",
   modules = {
      ["resty.console"] = "lib/resty/console.lua",
      ["resty.console.binding"] = "lib/resty/console/binding.lua",
      ["resty.console.client"] = "lib/resty/console/client.lua",
      ["resty.console.completer"] = "lib/resty/console/completer.lua",
      ["resty.console.consts"] = "lib/resty/console/consts.lua",
      ["resty.console.readline"] = "lib/resty/console/readline.lua",
      ["resty.console.resp"] = "lib/resty/console/resp.lua",
      ["resty.console.utils"] = "lib/resty/console/utils.lua",
   },
   install = {
      bin = {
         -- ['resty-console'] = 'bin/resty-console'
      }
   }
}