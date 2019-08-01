local BasePlugin = require("kong.plugins.base_plugin")
local MyPlugin = BasePlugin:extend()
local _lrucache = require("resty.lrucache")
local _inspect_ = require("inspect")
local _utils = require("kong.plugins.api-transformer.utils")
local _cjson_decode_ = require("cjson").decode
local _cjson_encode_ = require("cjson").encode


local C1, err = _lrucache.new(50)
if not C1 then
    return error("failed to create the cache: " .. (err or "unknown"))
end


local _get_env_ = function()
  return {
    ngx = {
      ctx = ngx.ctx,
      var = ngx.var,
      req = {
        get_headers =  ngx.req.get_headers,
        set_header = ngx.req.set_header,
        get_method = ngx.req.get_method,
        get_body_data = ngx.req.get_body_data,
        set_body_data = ngx.req.set_body_data,
        get_uri_args = ngx.req.get_uri_args,
        set_uri_args = ngx.req.set_uri_args,
      },
      resp = {
        get_headers = ngx.resp.get_headers,
      }
    }
  }
end


function MyPlugin:new()
  MyPlugin.super.new(self, 'api-transformer')
end


function MyPlugin:access(config)
  MyPlugin.super.access(self)

  ngx.req.read_body()

  local s, req_json_body = pcall(function() return _cjson_decode_(ngx.req.get_body_data()) end)
  if not s then
    req_json_body = nil
  end

  -- save vars into context for later usage
  ngx.ctx._parsing_error_in_access_phase = false
  ngx.ctx.req_uri = ngx.var.uri
  ngx.ctx.req_headers = ngx.req.get_headers()
  ngx.ctx.req_uri_args = ngx.req.get_uri_args()
  ngx.ctx.req_method = ngx.req.get_method()
  ngx.ctx.req_json_body = req_json_body

  if config.dev_mode then
    C1:flush_all()
  end

  local current_route_id = kong.router.get_route().id
  local c1_key = current_route_id .. "access"
  local sandbox_f = C1:get(c1_key)

  if not sandbox_f  then
    local l_status
    l_status, sandbox_f  = _utils.sandbox_load(config.request_transformer, _get_env_())
    if not l_status then
      ngx.ctx._parsing_error_in_access_phase = true
      return kong.response.exit(500, sandbox_f)
    end
    C1:set(c1_key, sandbox_f, 300)
  end

  local p_status, f_status, req_body_or_err  = _utils.sandbox_exec(sandbox_f)

  if not p_status then
    ngx.ctx._parsing_error_in_access_phase = true
    return kong.response.exit(500, _, {["Warning"] = '199 qtsapi-transformer "'.. "transformer script parsing failure." .. '"'})
  end

  if not f_status then
    ngx.ctx._parsing_error_in_access_phase = true
    return kong.response.exit(500, _, {["Warning"] = '199 qtsapi-transformer "'.. req_body_or_err .. '"'})
  end

  if type(req_body_or_err) ~= "string" then
    ngx.ctx._parsing_error_in_access_phase = true
    return kong.response.exit(500, _, {["Warning"] = '199 qtsapi-transformer "'.. "unknown error" .. '"'})
  end

  if string.len(req_body_or_err) > 0 then
    ngx.req.set_body_data(req_body_or_err)
    ngx.req.set_header(CONTENT_LENGTH, #req_body_or_err)
  end

  ngx.ctx._resp_buffer = ''
end


function MyPlugin:header_filter(config)
  MyPlugin.super.header_filter(self)
  if ngx.ctx._parsing_error_in_access_phase then
    return
  end
  ngx.header["content-length"] = nil -- this needs to be for the content-length to be recalculated
  if config.http_200_always then
    ngx.status = 200
  end
end


function MyPlugin:body_filter(config)
  MyPlugin.super.body_filter(self)
  if ngx.ctx._parsing_error_in_access_phase then
    ngx.arg[1] = ""
    return
  end

  local chunk, eof = ngx.arg[1], ngx.arg[2]

  if not eof then
    if ngx.ctx._resp_buffer and chunk then
      ngx.ctx._resp_buffer = ngx.ctx._resp_buffer .. chunk
    end
    ngx.arg[1] = nil

  else
    -- body is fully read
    local raw_body = ngx.ctx._resp_buffer
    if raw_body == nil then
      return ngx.ERROR
    end

    ngx.ctx.resp_json_body = _cjson_decode_(raw_body)

    local current_route_id = kong.router.get_route().id
    local c1_key = current_route_id .. "body"
    local sandbox_f = C1:get(c1_key)
    if not sandbox_f then
      local l_status
      l_status, sandbox_f  = _utils.sandbox_load(config.response_transformer, _get_env_())
      if not l_status then
        ngx.ctx._parsing_error_in_access_phase = true
        return kong.response.exit(500, sandbox_f)
      end
      C1:set(c1_key, sandbox_f, 300)
    end

    local p_status, f_status, resp_body_or_err  = _utils.sandbox_exec(sandbox_f)

    local resp_body = {
      data = {},
      error = {code = -1, message = ""}
    }

    if (not p_status) or (type(resp_body_or_err) ~= "string") then
      if config.http_200_always then
        resp_body.error.code = 500
        resp_body.error.message = "transformer script parsing failure."
        ngx.arg[1] = _cjson_encode_(resp_body)
      else
        ngx.arg[1] = ""
        return kong.response.exit(500, "transformer script parsing failure.")
      end
    elseif not f_status then
      if config.http_200_always then
        resp_body.error.code = 500
        resp_body.error.message = resp_body_or_err
        ngx.arg[1] = _cjson_encode_(resp_body)
      else
        ngx.arg[1] = ""
        return kong.response.exit(500, resp_body_or_err)
      end
    else
      ngx.arg[1] = resp_body_or_err
    end

  end

end

MyPlugin.PRIORITY = 801

return MyPlugin