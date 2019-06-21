if _req_uri == string.match(_req_uri, ".-/folders") then

  local req_uri_args = _req_get_uri_args_()
  local req_headers = _req_get_headers_()

  if _req_method == "GET" then    
    if req_uri_args["parent"] == "/" then
      req_uri_args["parent"] = "share_root"
    end
    _req_set_uri_args_({
      func = "get_tree",
      sid = req_headers["X-QTS-SID"],
      node = req_uri_args["parent"],
      hidden_file = ((req_uri_args["show-hidden"] == "true") and 1 or 0),
    })

  elseif _req_method == "POST" then
    _req_set_uri_args_({
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