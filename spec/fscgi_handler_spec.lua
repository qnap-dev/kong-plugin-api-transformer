local cjson_decode = require('cjson').decode
local cjson_encode = require('cjson').encode
local _inspect = require "inspect"


local mock = {
  body = '',
  ngx_headers = { ["content-length"] = 123 },
  uri_args = { a=1 },
  req_headers =  { ["X-QTS-SID"] = "cool_header" },
  resp_headers = { ['Content-Type'] = "application/json; charset=utf-8" },
  router_matches = { group_one = "test_match" },
  ngx_var = {uri = "/abc"},
  ngx_get_method = "GET",
}


local ngx =  {
  arg = {
    [0] = "abc",
    [1] = "abc"
  },
  req = {
    read_body = spy.new(function()  end),
    set_body_data = spy.new(function(b) mock.body = b end),
    get_body_data =  spy.new(function() return mock.body end),
    set_uri_args = spy.new(function(a) 
      mock.uri_args = a 
      -- print("called!!!", _inspect(a))
    end),
    get_uri_args = spy.new(function() return mock.uri_args end),
    set_header = spy.new(function(h) mock.req_headers = h end),
    get_headers = spy.new(function() return mock.req_headers end),
    get_method = function() return mock.ngx_get_method end
  },
  var = mock.ngx_var,
  resp = {
    get_headers = spy.new(function() 
      return mock.resp_headers 
    end)
  },
  header = mock.ngx_headers,
  config = {
    subsystem = "http",
    prefix = spy.new(function()
        return "mock"
    end)
  },
  location = {
    capture = spy.new(function() end)
  },
  get_phase = spy.new(function() end),
  log = spy.new(function() end),
  ctx = {
    router_matches = { 
      uri_captures = { 
        group_one = "test_match" 
      } 
    },
    custom_data = { important_stuff = 123 },
    resp_buffer = "bbb",
  },
  status = 100,
}
_G.ngx = ngx
local transformerHandler = require('kong.plugins.api-transformer.handler')

local req_code_string = "/api-transformer/spec/fscgi_req.lua"
local resp_code_string = "/api-transformer/spec/fscgi_resp.lua"


local config = {
  http_200_always = true,
  request_transformer = req_code_string,
  response_transformer = resp_code_string
}


it("Test set object name", function()
  transformerHandler:new()
  assert.equal("api-transformer", transformerHandler._name)
end)


describe("<GET /folders>", function()

  describe("Test access()", function()

    before_each(function()
      mock = {
        body = '',
        ngx_headers = { ["content-length"] = 123 },
        uri_args = { a=1 },
        req_headers =  { ["X-QTS-SID"] = "cool_header" },
        resp_headers = { ['Content-Type'] = "application/json; charset=utf-8" },
        router_matches = { group_one = "test_match" },
        ngx_var = {uri = "/abc"},
        ngx_get_method = "GET",
      }
      
    end)
  
    it("should not call set_uri_args() when _req_uri did not match", function()
      ngx.var.uri = "xxx/folders1"

      transformerHandler:new()
      transformerHandler:access(config)
      assert.spy(ngx.req.set_uri_args).was_not_called()
    end)

    it("set_uri_args(parent = /)", function()
      mock.uri_args = {
        parent = "/",
        ["show-hidden"] = "true"
      }
      ngx.var.uri = "xxx/folders"

      local sid = mock.req_headers["X-QTS-SID"]

      transformerHandler:new()
      transformerHandler:access(config)

      assert.spy(ngx.req.set_uri_args).was_called_with({
        func = "get_tree",
        sid = sid,
        node = "share_root",
        hidden_file = 1,
      })
    end)  
    
    it("set_uri_args( parent = /Public )", function()
      mock.uri_args = {
        parent = "/Public",
        ["show-hidden"] = "false"
      }
      ngx.var.uri = "xxx/folders"

      local sid = mock.req_headers["X-QTS-SID"]

      transformerHandler:new()
      transformerHandler:access(config)

      assert.spy(ngx.req.set_uri_args).was_called_with({
        func = "get_tree",
        sid = sid,
        node = "/Public",
        hidden_file = 0,
      })
    end)
  
  end)

  describe("Test body_filter()", function()

    before_each(function()
    end)

    it("should get errcode 99 when _req_uri did not match", function()
      ngx.ctx._req_uri = "xxx/folders1"
      ngx.ctx._method = "GET"
    
      local new_rsp = {
        data = {},
        error = {code=99, message="Unknown operation"}
      }

      transformerHandler:new()
      ngx.arg[2] = true -- set eof == true
      ngx.ctx.resp_buffer = "{}"
      transformerHandler:body_filter(config)
      assert.is_equal(cjson_encode(new_rsp), ngx.arg[1])
    end)

    it("response body shall same after transformer", function()
      ngx.ctx._req_uri = "xxx/folders"
      ngx.ctx._method = "GET"

      local new_rsp = {
        data = {
          {name=".test",["icon-class"]="folder",path="/Public/.test",id="%2FPublic%2F.test",readonly=false},
          {name="new folder 1",["icon-class"]="folder",path="/Public/new folder 1",id="%2FPublic%2Fnew+folder+1",readonly=false}
        },
        error = {code=1, message="success"}
      }

      transformerHandler:new()
      ngx.arg[2] = true -- set eof == true
      ngx.ctx.resp_buffer = [[
        [ 
          { "id": "\/Public\/.test", "cls": "7", "text": ".test", "no_setup": 0, "is_cached": 0, "draggable": 1, "iconCls": "folder", "max_item_limit": 2000, "real_total": 12 }, 
          { "id": "\/Public\/new folder 1", "cls": "7", "text": "new folder 1", "no_setup": 0, "is_cached": 0, "draggable": 1, "iconCls": "folder", "max_item_limit": 2000, "real_total": 12 }
        ]
      ]]
      transformerHandler:body_filter(config)
      assert.are.same(new_rsp, cjson_decode(ngx.arg[1]))

    end)

  end)

end)


describe("<POST /folders>", function()

  describe("Test access()", function()

    before_each(function()
      mock = {
        body = '',
        ngx_headers = { ["content-length"] = 123 },
        uri_args = { a=1 },
        req_headers =  { ["X-QTS-SID"] = "cool_header" },
        resp_headers = { ['Content-Type'] = "application/json; charset=utf-8" },
        router_matches = { group_one = "test_match" },
        ngx_var = {uri = "/abc"},
        ngx_get_method = "POST",
      }
      
    end)
  
    it("should not call set_uri_args() when _req_uri did not match", function()
      ngx.var.uri = "xxx/folders1"
      local _o = ngx.req.set_uri_args
      ngx.req.set_uri_args = spy.new(function(a) mock.uri_args = a end)
      transformerHandler:new()
      transformerHandler:access(config)
      assert.spy(ngx.req.set_uri_args).was_not_called()
      ngx.req.set_uri_args = _o
    end)

    it("set_uri_args(func = createdir)", function()
      mock.body = cjson_encode({
        name = "a01",
        parent = "/Public"
      })
      ngx.var.uri = "xxx/folders"
      local sid = mock.req_headers["X-QTS-SID"]
      transformerHandler:new()
      transformerHandler:access(config)

      assert.spy(ngx.req.set_uri_args).was_called_with({
        dest_folder = "a01",
        dest_path = "/Public",
        func = "createdir",
        sid = sid,
      })
    end)  
  
  end)

  describe("Test body_filter()", function()

    before_each(function()
    end)

    it("Test response transformer when code=33", function()
      ngx.ctx._req_uri = "xxx/folders"
      ngx.ctx._method = "POST"

      local new_rsp = {["data"]={},["error"]={["message"]="Name duplication",["code"]=33}}

      transformerHandler:new()
      ngx.arg[2] = true -- set eof == true
      ngx.ctx.resp_buffer = [[
        { "version": "5.1.0", "build": "20190424", "status": 33, "success": "true" }
      ]]
      transformerHandler:body_filter(config)
      assert.are.same(new_rsp, cjson_decode(ngx.arg[1]))

    end)

    it("Test response transformer when code=0, with predefined req_body", function()
      ngx.ctx._req_uri = "xxx/folders"
      ngx.ctx._method = "POST"

      local new_rsp = {["data"]={["id"]="%2FPublic%2Fa04"},["error"]={["message"]="success",["code"]=1}}

      transformerHandler:new()
      ngx.arg[2] = true -- set eof == true
      ngx.ctx._req_json_body = {name="a04", parent="/Public"}
      ngx.ctx.resp_buffer = [[
        { "version": "5.1.0", "build": "20190424", "status": 1, "success": "true" }
      ]]
      transformerHandler:body_filter(config)
      assert.are.same(new_rsp, cjson_decode(ngx.arg[1]))

    end)

  end)  

end)