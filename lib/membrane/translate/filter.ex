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
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    {[],
     %{
       source_locale: nil,
       target_locale: opts.locale,
       enabled: true
     }}
  end

  @impl true
  def handle_stream_format(_pad, format, _ctx, state) do
    if format.locale not in Deepl.source_languages() do
      Membrane.Logger.warning("Language #{inspect(format.locale)} cannot be translated")
      {[stream_format: {:output, format}], %{state | enabled: false}}
    else
      {[stream_format: {:output, %Text{locale: state.target_locale}}],
       %{state | source_locale: format.locale}}
    end
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    [translation] = Deepl.translate([buffer.payload], state.target_locale)
    {[forward: %Buffer{buffer | payload: translation}], state}
  end
end
