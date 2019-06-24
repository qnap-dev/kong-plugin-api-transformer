
return {
  no_consumer = true,
  fields = {
    request_transformer = {
      type = "string",
      required = true,
    },

    response_transformer = {
      type = "string",
      required = true,
    },
    http_200_always = {
      type = "boolean",
      default = true,
    },    
  },
}
