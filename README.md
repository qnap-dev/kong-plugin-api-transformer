[![Build Status](https://travis-ci.org/qnap-dev/kong-plugin-api-transformer.svg?branch=master)](https://travis-ci.org/qnap-dev/kong-plugin-api-transformer)

# Kong-plugin-api-transformer

This is a Kong middleware to transform requests / responses by using Lua scripts, inspired by [Kong-plugin-template-transformer](https://github.com/stone-payments/kong-plugin-template-transformer).

## Abstract

Current transformer plugins that listed in the **[Kong Hub](https://docs.konghq.com/hub/#transformations)** exists many restrictions in our business requirements, what we need is a more elastic way in transformtion. With this plugin, you can write the control logic in Lua to transform requests and responses for specific routes/servcies, we also engage the Lua sanbox approach for security concerns.

## Project Structure

```
├── kong
│   └── plugins
│       └── api-transformer
│           ├── handler.lua
│           ├── schema.lua
│           └── utils.lua
└── spec
    ├── fscgi_req.lua            (mock request transformer script)
    ├── fscgi_resp.lua           (mock response transformer script)
    └── fscgi_handler_spec.lua   (fscgi test case)
```


## Configuration

### Enabling the plugin on a Route

Configure this plugin on a Route with:

```bash
curl -X POST http://kong:8001/services/{service_id}/plugins \
    --data "name=api-transformer"  \
    --data "config.request_transformer=$req_lua"
    --data "config.response_transformer=$resp_lua"
    --data "config.http_200_always=true"


curl -X POST http://kong:8001/routes/{route_id}/plugins \
    --data "name=api-transformer"  \
    --data "config.request_transformer=$req_lua"
    --data "config.response_transformer=$resp_lua"
    --data "config.http_200_always=true"
```

- config.request_transformer: the file path of lua script to transform the request context before proxying to the upstream.
- config.response_transformer: the file path of lua script to transform the response context before returning to the client.
- config.http_200_always: default: true, use the http 200 approach in error handling, this will ignore the upstream's http code.

## For Developer

### Allowed Lua symbols in the transformer
```lua
  print
  assert
  error
  ipairs
  next
  pairs
  pcall
  select
  tonumber
  tostring
  type
  unpack
  xpcall
  string.byte
  string.char
  string.find
  string.format
  string.gmatch
  string.gsub
  string.len
  string.match
  string.rep
  string.reverse
  string.sub
  string.upper
  table.insert
  table.maxn
  table.remove
  table.sort
  table.insert
  table.concate
```

### Available OpenResty symbols in the transformer
```
ngx.ctx
ngx.var
ngx.req.get_headers
ngx.req.set_header
ngx.req.get_method
ngx.req.get_body_data
ngx.req.set_body_data
ngx.req.get_uri_args
ngx.req.set_uri_args
ngx.resp.get_headers
```

### Available util functions in the transformer
| In Transformer   | Coreresponding                  | Lua type |
|------------------|---------------------------------|----------|
| `_inspect_`      | `require('inspect')`            | function |
| `_cjson_decode_` | `require('cjson').decode`       | function |
| `_cjson_encode_` | `require('cjson').encode`       | function |
| `_url_encode_`   |                                 | function |
| `_url_decode_`   |                                 | function |
| `_log_`          | `ngx.log(ngx.ERR, _inspect(e))` | function |


### Symbols which cached in ngx.ctx for the response transformer
This table `ngx.ctx` can be used to store per-request Lua context data and has a life time identical to the current request, so we use this table to store the necessary data for body_filter()

| Cached Symbols           | Coreresponding                             | Lua type |
|--------------------------|--------------------------------------------|----------|
| `ngx.ctx.req_uri`        | `ngx.var.uri`                              | string   |
| `ngx.ctx.req_method`     | `ngx.req.get_method()`                     | string   |
| `ngx.ctx.req_json_body`  | `_cjson_decode_(ngx.req.get_body_data())`  | table    |
| `ngx.ctx.resp_json_body` | `ngx.arg[1]`                               | talbe    |


### Return values

In the transformer, we need to return a Lua tuple:  (f_status: `boolean`, body_or_err: `string`)
```
if f_status == true then
  body_or_err = transformed_body
else
  body_or_err = error message
end
```


### Run test manually
```bash
docker run -it -v ${PWD}:/api-transformer qnapandersen/kong-plugin-api-transformer-dev:0.1.0 bash
cd /api-transformer
make test
```

## Credits

QNAP Inc. [www.qnap.com](http://www.qnap.com)