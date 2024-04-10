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

## Configuration
We're using [Req](https://github.com/wojtekmach/req) as HTTP client in the Deepl dep.
Follow [Deepl](https://github.com/kim-company/deepl) readme to configure the client for
testing and production.

Check the filter test to understand how you can mock requests with stubs.

## Copyright and License
Copyright 2024, [KIM Keep In Mind GmbH](https://www.keepinmind.info/)
Licensed under the [Apache License, Version 2.0](LICENSE)
