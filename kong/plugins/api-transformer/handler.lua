local BasePlugin = require 'kong.plugins.base_plugin'
local MyPlugin = BasePlugin:extend()
local _inspect = require("inspect")
local _utils = require "kong.plugins.api-transformer.utils"
local _cjson_decode_ = require("cjson").decode
local _cjson_encode_ = require("cjson").encode


function MyPlugin:new()
  MyPlugin.super.new(self, 'api-transformer')
end


function MyPlugin:access(config)
  MyPlugin.super.access(self)
  
  ngx.req.read_body()

  local _req_body = ngx.req.get_body_data()
  local s, _req_json_body = pcall(function() return _cjson_decode_(_req_body) end)
  if not s then
    _req_json_body = nil
  end

  local _env = {
    _req_uri = ngx.var.uri,
    _req_headers = ngx.req.get_headers(),
    _req_method = ngx.req.get_method(),
    _req_uri_args = ngx.req.get_uri_args(),
    _req_json_body = _req_json_body,
    _req_set_uri_args_ = ngx.req.set_uri_args,
    _url_encode_ = _utils.url_encode,
    _url_decode_ = _utils.url_decode,
}

  -- save vars into context for later usage
  ngx.ctx._parsing_error = false
  ngx.ctx._req_uri = _env._req_uri
  ngx.ctx._req_method = _env._req_method
  ngx.ctx._req_json_body = _env._req_json_body

  local status, transformed_body  = _utils.run_untrusted_file(config.request_transformer, _env)
  if not status then
    ngx.ctx._parsing_error = true
    kong.response.exit(500, "Invalid request transformer.")
  end

  if type(transformed_body) == "string" then
    ngx.req.set_body_data(transformed_body)
    ngx.req.set_header(CONTENT_LENGTH, #transformed_body)
  end
  ngx.ctx.resp_buffer = ''
end


function MyPlugin:header_filter(config)
  ngx.header["content-length"] = nil -- this needs to be for the content-length to be recalculated
  if ngx.ctx._parsing_error then
    return
  end
  if config.http_200_always then
    ngx.status = 200
  end
end


function MyPlugin:body_filter(config)
  MyPlugin.super.body_filter(self)

  local chunk, eof = ngx.arg[1], ngx.arg[2]

  if not eof then
    if ngx.ctx.resp_buffer and chunk then
      ngx.ctx.resp_buffer = ngx.ctx.resp_buffer .. chunk
    end
    ngx.arg[1] = nil

  else
    -- body is fully read
    local raw_body = ngx.ctx.resp_buffer
    if raw_body == nil then
      return ngx.ERROR
    end

    local _env = {
      _req_uri = ngx.ctx._req_uri,
      _req_method = ngx.ctx._req_method,
      _req_json_body = ngx.ctx._req_json_body,
      _resp_headers = ngx.resp.get_headers(),
      _resp_json_body = _cjson_decode_(raw_body),
      _url_encode_ = _utils.url_encode,
      _url_decode_ = _utils.url_decode,
    }

    local s, r = _utils.run_untrusted_file(config.response_transformer, _env)

    if not s then
      kong.response.exit(500, "Invalid response transformer.")
    end

    ngx.arg[1] = r

  end

end

MyPlugin.PRIORITY = 801

return MyPlugin