local _req_uri = ngx.var.uri
local _req_method = ngx.req.get_method()
local _req_json_body = ngx.ctx.req_json_body

if _req_uri == string.match(_req_uri, ".-/folders") then

  local req_uri_args = ngx.req.get_uri_args()
  local req_headers = ngx.req.get_headers()

  if _req_method == "GET" then
    if req_uri_args["parent"] == "/" then
      req_uri_args["parent"] = "share_root"
    end
    ngx.req.set_uri_args({
      func = "get_tree",
      sid = req_headers["X-QTS-SID"],
      node = req_uri_args["parent"],
      hidden_file = ((req_uri_args["show-hidden"] == "true") and 1 or 0),
    })

  elseif _req_method == "POST" then
    ngx.req.set_uri_args({
      func = "createdir",
      sid = req_headers["X-QTS-SID"],
      dest_folder = _req_json_body.name,
      dest_path = _req_json_body.parent,
    })

  end

  return true, ""

else

  return false, "invalid request uri: " .. _req_uri

end