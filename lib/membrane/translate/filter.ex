defmodule Membrane.Translate.Filter do
  use Membrane.Filter
  alias Membrane.Buffer
  alias Membrane.Text

  require Membrane.Logger

  def_input_pad(:input,
    accepted_format: Text,
    availability: :always
  )

  def_output_pad(:output,
    accepted_format: Text,
    availability: :always
  )

  def_options(
    locale: [
      spec: String.t(),
      description: "Language to translate to",
      default: "en-US"
    ],
    deepl_opts: [
      spec: keyword(),
      description: "Deepl client options",
      required: true
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    {[], opts}
  end

  def handle_setup(_ctx, opts) do
    deepl = Deepl.new(opts.deepl_opts)
    target = safe_target_language_code(opts.locale, deepl)

    if target == nil do
      Membrane.Logger.warning(
        "Filter will not be able to translate to #{inspect(opts.locale)} as it is not a supported language"
      )
    end

    {[],
     %{
       source_locale: nil,
       target_locale: target,
       deepl: deepl,
       enabled: true
     }}
  end

  @impl true
  def handle_stream_format(_pad, format, _ctx, state) do
    if is_source_language_supported(format.locale, state.deepl) do
      {[stream_format: {:output, %Text{locale: state.target_locale}}],
       %{state | source_locale: format.locale}}
    else
      Membrane.Logger.warning(
        "Source language #{inspect(format.locale)} is not in the list of supported languages: #{inspect(Deepl.source_languages(state.deepl))}"
      )

      {[stream_format: {:output, format}], %{state | enabled: false}}
    end
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state = %{target_locale: nil}) do
    {[forward: buffer], state}
  end

  def handle_buffer(:input, buffer, _ctx, state) do
    [translation] = Deepl.translate(state.deepl, [buffer.payload], state.target_locale)
    {[forward: %Buffer{buffer | payload: translation}], state}
  end

  defp is_source_language_supported(source, deepl) do
    allowed =
      deepl
      |> Deepl.source_languages()
      |> Enum.map(fn code -> ExLang.parse!(code).code end)

    ExLang.parse!(source).code in allowed
  end

  defp safe_target_language_code(target, deepl) do
    target_langs = Deepl.target_languages(deepl)

    if String.upcase(target) in target_langs do
      # It is good as provided.
      target
    else
      Membrane.Logger.warning(
        "Target language #{inspect(target)} is not in the supported list of target languages for Deepl. Finding best effort match"
      )

      target_code = ExLang.parse!(target).code

      match =
        target_langs
        |> Enum.map(fn lang -> {lang, ExLang.parse!(lang).code} end)
        |> Enum.find(fn {_lang, code} -> code == target_code end)

      case match do
        {lang, _code} -> lang
        nil -> nil
      end
    end
  end
end
