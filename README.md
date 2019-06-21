[![Build Status](https://travis-ci.org/andersenq/kong-plugin-api-transformer.svg?branch=master)](https://travis-ci.org/andersenq/kong-plugin-api-transformer)

# Kong-plugin-api-transformer

This is a Kong middleware to transform requests / responses, using the lua script, inspired by [Kong-plugin-template-transformer](https://github.com/stone-payments/kong-plugin-template-transformer).

## Abstract

Current plugins which listed in the **[Kong Hub - TRANSFORMATIONS](https://docs.konghq.com/hub/#transformations)** exists many restrictions while applying in our business cases, what we need is a more elastic way in transformtion. With this plugin, you can write the control logic in Lua to transform requests and responses for specific routes/servcies, we also engage the Lua sanbox approach for security concerns.

## Project Structure

```
├── kong
│   └── plugins
│       └── api-transformer
│           ├── handler.lua
│           ├── schema.lua
│           └── utils.lua
└── spec
    ├── fscgi_req.lua            (request transformer script)
    ├── fscgi_resp.lua           (response transformer script)
    └── fscgi_handler_spec.lua   (test case)
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

### Allowed Lua objects/functions in the transformer script's context
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

### Available utils in the transformer script's context
| Sanbox         | Coreresponding                | Lua type |
|----------------|-------------------------------|----------|
| _inspect_      | require('inspect')            | function |
| _cjson_decode_ | require('cjson').decode       | function |
| _cjson_encode_ | require('cjson').encode       | function |
| _url_encode_   |                               | function |
| _url_decode_   |                               | function |
| _log_          | ngx.log(ngx.ERR, _inspect(e)) | function |

### Available OpenResty API in the transformer script's context
| Sandbox            | Corresponding                       | Lua type |
|--------------------|-------------------------------------|----------|
| _req_uri           | ngx.var.uri                         | string   |
| _req_headers       | ngx.req.get_headers()               | table    |
| _req_method        | ngx.req.get_method()                | string   |
| _req_uri_args      | ngx.req.get_uri_args()              | table    |
| _req_json_body     | _cjson_decode_(ngx.req.read_body()) | table    |
| _req_set_uri_args_ | ngx.req.set_uri_args                | function |


### run test manually
```bash
docker run -it -v ${PWD}:/api-transformer qnapandersen/kong-plugin-api-transformer-dev:0.1.0 bash
cd /api-transformer
make test
```

## Credits

QNAP Inc. [www.qnap.com](http://www.qnap.com)