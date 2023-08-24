# Membrane.Translate
Plugin providing a translation filter. Currently backed by Deepl, for which you need an authentication key.

This element is used in production.

## Installation
```elixir
def deps do
  [
    {:membrane_translate_plugin, github: "kim-company/membrane_translate_plugin"}
  ]
end
```

Remember then to configure an adapter for Tesla. We use Mint, which you need to
add as a dependency to your project and then add the following line to your config.
```
config :tesla, adapter: Tesla.Adapter.Mint
```

## Copyright and License
Copyright 2023, [KIM Keep In Mind GmbH](https://www.keepinmind.info/)
Licensed under the [Apache License, Version 2.0](LICENSE)
