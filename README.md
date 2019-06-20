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

- config.request_transformer: the lua script to transform the request context before proxying to the upstream.
- config.response_transformer: the lua script to transform the response context before returning to the client.
- config.http_200_always: default: true, use the http 200 approach in error handling, this will ignore the upstream's http code.

## Developing

### In docker

```bash
docker build . -t api-transformer-dev-env
docker run -it -v ${PWD}:/api-transformer qnapandersen/kong-plugin-api-transformer-dev:0.1.0 bash
busted -o=TAP --lazy /api-transformer/spec/fscgi_handler_spec.lua
```

## Credits

QNAP Inc. [www.qnap.com](http://www.qnap.com)