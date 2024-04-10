import Config

config :deepl,
  req_options: [
    plug: {Req.Test, Deepl}
  ]
