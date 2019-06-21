if _req_uri == string.match(_req_uri, ".-/folders") then
  if _req_method == "GET" then
    if _req_uri_args["parent"] == "/" then
      _req_uri_args["parent"] = "share_root"
    end
    _req_set_uri_args_({
      func = "get_tree",
      sid = _req_headers["X-QTS-SID"],
      node = _req_uri_args["parent"],
      hidden_file = ((_req_uri_args["show-hidden"] == "true") and 1 or 0),
    })
    return ""  
  elseif _req_method == "POST" then
    _req_set_uri_args_({
      func = "createdir",
      sid = _req_headers["X-QTS-SID"],
      dest_folder = _req_json_body.name,
      dest_path = _req_json_body.parent,
    })
    return ""
  end
end