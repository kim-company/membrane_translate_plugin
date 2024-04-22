defmodule Membrane.Translate.MixProject do
  use Mix.Project

  def project do
    [
      app: :membrane_translate_plugin,
      version: "0.2.0",
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
      {:membrane_core, "~> 1.0"},
      {:membrane_text_format, github: "kim-company/membrane_text_format"},
      {:deepl, github: "kim-company/deepl"},
      {:ex_lang, github: "kim-company/ex_lang"},
      {:plug, "~> 1.0", only: :test}
    ]
  end
end
