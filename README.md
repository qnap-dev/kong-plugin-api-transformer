[![Build Status](https://travis-ci.org/stone-payments/kong-plugin-template-transformer.svg?branch=master)](https://travis-ci.org/stone-payments/kong-plugin-template-transformer)

# Kong-plugin-template-transformer

This is a Kong middleware to transform requests / responses, using pre-configured templates.

## The Problem

When using Kong, you can create routes that proxy to an upstream. The problem lies when the upstream has an ugly response/request contract. Sometimes the [kong bundled request transformer](https://docs.konghq.com/hub/kong-inc/request-transformer/) is not enough. This plugin was created for those situations, it can apply a [template](https://github.com/bungle/lua-resty-template) to JSON requests and responses, transforming them pretty much however you like.

## Project Structure

The plugin folder should contain at least a `schema.lua` and a `handler.lua`, alongside with a `spec` folder and a `.rockspec` file specifying the current version of the package.

# Writing Templates

We use [lua-resty-template](https://github.com/bungle/lua-resty-template) to write templates. It's also **very important** that you don't leave any `\t` in the files. We also only support JSON requests and responses for now.

## Rockspec Format

The `.rockspec` file should follow [LuaRocks' conventions](https://github.com/luarocks/luarocks/wiki/Rockspec-format)

## Configuration

### Enabling the plugin on a Route

Configure this plugin on a Route with:

```bash
curl -X POST http://kong:8001/routes/{route_id}/plugins \
    --data "name=kong-plugin-template-transformer"  \
    --data "config.request_template=http://new-url.com"
    --data "config.response_template=http://new-url.com"
    --data "config.hidden_fields=http://new-url.com"
```

- route_id: the id of the Route that this plugin configuration will target.
- config.request_template: Optional, the template to be applied before proxying to the upstream.
- config.response_template: Optional, the template to be applied before returning to the client.
- config.hidden_fields: Optional, a list of request or response fields that you do not want Kong to save them in a log file.

## Developing

### In docker

```bash
docker build . -t kong-plugin-template-transformer-dev
docker run -it -v ${PWD}/template-transformer:/template-transformer kong-plugin-template-transformer-dev bash
```

## Credits

made with :heart: by Stone Payments