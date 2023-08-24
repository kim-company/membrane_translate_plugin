defmodule Membrane.Translate.MixProject do
  use Mix.Project

  def project do
    [
      app: :membrane_translate_plugin,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:membrane_core, "~> 0.12"},
      {:con_cache, "~> 0.13"},
      {:membrane_text_format, github: "kim-company/membrane_text_format"},
      {:tesla, "~> 1.6"},
      {:castore, "~> 1.0"}
    ]
  end
end
