function gen_error_obj(status)
  local code = status or 1
  local message = ""
  if code == 1 then
    message = "success"
  elseif code == 3 then
    message = "Authentication Failure"
  elseif code == 4 then
    message = "Permission denied"
  elseif code == 5 then
    message = "File/Folder not exist"
  elseif code == 7 then
    message = "I/O error"
  elseif code == 33 then
    message = "Name duplication"
  else
    message = "failure"
  end
  return {code=code, message=message}
end


local new_resp_body = {
  data = {},
  error = {code=99, message="Unknown operation"}
}


if _req_uri == string.match(_req_uri, ".-/folders") then

  if _req_method == "GET" then

    new_resp_body.data = _resp_json_body
    for _, obj in pairs(_resp_json_body) do
      if not obj.id then
        new_resp_body.data = {}
        break
      end
      obj["no_setup"] = nil
      obj["is_cached"] = nil
      obj["draggable"] = nil
      obj["max_item_limit"] = nil
      obj["real_total"] = nil
      obj["recycle_bin"] = nil
      obj["recycle_folder"] = nil
      obj.name = obj.text
      obj.text = nil
      obj.path = obj.id
      obj.id = _url_encode_(obj.id) -- conver id for rest style usage
      obj["icon-class"] = obj["iconCls"]
      obj["iconCls"] = nil
      obj["readonly"] = (obj["cls"] == "r")
      obj["cls"] = nil
    end

  elseif _req_method == "POST" then
    if _resp_json_body.status == 1 then
      new_resp_body.data = {
        id = _url_encode_(_req_json_body.parent .. "/" .. _req_json_body.name)
      }
    end

  end
  -- gen error obj finally
  new_resp_body.error = gen_error_obj(_resp_json_body.status)

  return true, _cjson_encode_(new_resp_body)

else

  return false, "invalid request uri: " .. _req_uri

end

