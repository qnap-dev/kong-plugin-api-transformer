local _inspect = require "inspect"

local _M = {}


function _M.url_encode(s)
  s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)  
  return string.gsub(s, " ", "+")  
end  


function _M.url_decode(s)  
  s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)  
  return s  
end


local _G_ENV = {
  print = _G.print,
  assert = _G.assert,
  error = _G.error,
  ipairs = _G.ipairs,
  next = _G.next,
  pairs = _G.pairs,
  pcall = _G.pcall,
  select = _G.select,
  tonumber = _G.tonumber,
  tostring = _G.tostring,
  type = _G.type,
  unpack = _G.unpack,
  xpcall = _G.xpcall,
  string = {
    byte = string.byte,
    char = string.char,
    find = string.find,
    format = string.format,
    gmatch = string.gmatch,
    gsub = string.gsub,
    len = string.len,
    match = string.match,
    rep = string.rep,
    reverse = string.reverse,
    sub = string.sub,
    upper = string.upper,
  },
  table = {
    insert = table.insert,
    maxn = table.maxn,
    remove = table.remove,
    sort = table.sort,
    insert = table.insert,
    concate = table.concate,
  },

  _inspect = _inspect,
  _cjson_decode_ = require('cjson').decode,
  _cjson_encode_ = require('cjson').encode,
  _url_encode_ = _M.url_encode,
  _url_decode_ = _M.url_decode,
  _log_ = function(e) ngx.log(ngx.ERR, _inspect(e)) end,  
}


function _M.run_untrusted_file(lua_file, local_env)
  local f, message = loadfile(lua_file)
  if not f then 
    return nil, message 
  end
  for k,v in pairs(_G_ENV) do
    local_env[k] = v 
  end
  setfenv(f, local_env)
  return xpcall(f, function() ngx.log(ngx.ERR, debug.traceback()) end)
end


return _M
  