package = "kong-plugin-api-transformer"
version = "0.1.0"
source = {
  url = "https://github.com/andersenq/kong-plugin-api-transformer.git",
  tag = "0.1.0"
}
description = {
  summary = "A Kong plugin that enables elastic request/response transforming by lua scripts",
  license = "Apache License 2.0",
  maintainer = "andersenhuang@qnap.com"
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.api-transformer.handler"] = "template-transformer/handler.lua",
    ["kong.plugins.api-transformer.schema"] = "template-transformer/schema.lua",
    ["kong.plugins.api-transformer.utils"] = "template-transformer/utils.lua"
  }
}