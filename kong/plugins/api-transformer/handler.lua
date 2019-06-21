local BasePlugin = require("kong.plugins.base_plugin")
local MyPlugin = BasePlugin:extend()
local _inspect_ = require("inspect")
local _utils = require("kong.plugins.api-transformer.utils")
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
    _req_get_headers_ = ngx.req.get_headers,
    _req_set_header_ = ngx.req.set_header,
    _req_method = ngx.req.get_method(),
    _req_json_body = _req_json_body,
    _req_get_uri_args_ = ngx.req.get_uri_args,
    _req_set_uri_args_ = ngx.req.set_uri_args,
    _req_set_body_data_ = ngx.req.set_body_data,
  }

  -- save vars into context for later usage
  ngx.ctx.parsing_error = false
  ngx.ctx.req_uri = _env._req_uri
  ngx.ctx.req_method = _env._req_method
  ngx.ctx.req_json_body = _env._req_json_body

  local p_status, f_status, req_body_or_err  = _utils.run_untrusted_file(config.request_transformer, _env)

  if not p_status then
    ngx.ctx.parsing_error = true
    return kong.response.exit(500, "transformer script parsing failure.")
  end

  if not f_status then
    ngx.ctx.parsing_error = true
    return kong.response.exit(500, req_body_or_err)
  end

  if type(req_body_or_err) ~= "string" then
    ngx.ctx.parsing_error = true
    return kong.response.exit(500, "unknown error")
  end

  if string.len(req_body_or_err) > 0 then
    ngx.req.set_body_data(req_body_or_err)
    ngx.req.set_header(CONTENT_LENGTH, #req_body_or_err)
  end

  ngx.ctx.resp_buffer = ''
end


function MyPlugin:header_filter(config)
  ngx.header["content-length"] = nil -- this needs to be for the content-length to be recalculated
  
  if ngx.ctx.parsing_error then
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
      _req_uri = ngx.ctx.req_uri,
      _req_method = ngx.ctx.req_method,
      _req_json_body = ngx.ctx.req_json_body,
      _resp_json_body = _cjson_decode_(raw_body),
      _resp_get_headers_ = ngx.resp.get_headers,
    }

    local p_status, f_status, resp_body_or_err = _utils.run_untrusted_file(config.response_transformer, _env)

    local resp_body = {
      data = {},
      error = {code = -1, message = ""}
    }    

    if (not p_status) or (type(resp_body_or_err) ~= "string") then
      resp_body.error.code = 500
      resp_body.error.message = "transformer script parsing failure."
      ngx.arg[1] = _cjson_encode_(resp_body)
    elseif not f_status then
      resp_body.error.code = 500
      resp_body.error.message = resp_body_or_err
      ngx.arg[1] = _cjson_encode_(resp_body)
    else
      ngx.arg[1] = resp_body_or_err
    end
    
  end
  
end

MyPlugin.PRIORITY = 801

return MyPlugin