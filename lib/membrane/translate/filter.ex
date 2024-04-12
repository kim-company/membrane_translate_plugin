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
    {[],
     %{
       source_locale: nil,
       target_locale: opts.locale,
       deepl: Deepl.new(opts.deepl_opts),
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
  def handle_buffer(:input, buffer, _ctx, state) do
    [translation] = Deepl.translate(state.deepl, [buffer.payload], state.target_locale)
    {[forward: %Buffer{buffer | payload: translation}], state}
  end

  defp is_source_language_supported(source, deepl) do
    allowed =
      deepl
      |> Deepl.source_languages()
      |> Enum.map(&String.downcase/1)

    String.downcase(source) in allowed
  end
end
