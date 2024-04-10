import Config

if config_env() != :test do
  config :deepl,
    req_options: [
      auth: "DeepL-Auth-Key #{System.fetch_env!("DEEPL_AUTH_KEY")}",
      connect_options: [timeout: 3_000],
      plug: nil
    ]
end
