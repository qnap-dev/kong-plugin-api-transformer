
return {
  no_consumer = true,
  fields = {
    -- ".-/folders"
    -- route_pattern = {
    --   type = "string",
    --   required = false,
    -- },
    -- route_method = {
    --   type = "string", 
    --   enum = {"GET", "POST", "PUT", "PATCH", "DELETE"},
    --   required = false,
    -- },

    -- need to return new_request_body
    request_transformer = {
      type = "string",
      required = true,
    },

    response_transformer = {
      type = "string",
      required = true,
    },
    http_200_err_handling = {
      type = "boolean",
      default = true,
    },    
  },
}
