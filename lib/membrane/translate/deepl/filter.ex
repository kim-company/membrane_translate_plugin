defmodule Membrane.Translate.Deepl.Filter do
  use Membrane.Filter
  alias Membrane.Buffer
  alias Membrane.Text
  alias Membrane.Translate.Deepl
  require Membrane.Logger

  def_input_pad(:input,
    accepted_format: Text,
    availability: :always,
    demand_mode: :auto,
    demand_unit: :buffers,
    mode: :pull
  )

  def_output_pad(:output,
    accepted_format: Text,
    availability: :always,
    demand_mode: :auto,
    mode: :pull
  )

  def_options(
    language_code: [
      spec: Pepe.Language.code(),
      description: "Expected audio spoken language",
      default: :"en-US"
    ],
    client: [
      spec: Pepe.Translate.Deepl.t(),
      description: "Deepl client instance"
    ]
  )

  @impl true
  def handle_init(_ctx, opts) do
    {:ok, cache} =
      ConCache.start_link(
        ttl_check_interval: :timer.minutes(1),
        global_ttl: :timer.minutes(10),
        touch_on_read: true
      )

    {[],
     %{
       client: opts.client,
       cache: cache,
       source_language_code: nil,
       target_language_code: opts.language_code
     }}
  end

  @impl true
  def handle_stream_format(_pad, %Text{} = format, _ctx, state) do
    {
      [stream_format: {:output, %Text{format | language_code: state.target_language_code}}],
      %{state | source_language_code: format.language_code}
    }
  end

  @impl true
  def handle_process(:input, buffer, _ctx, state) do
    start_at = DateTime.utc_now()
    response = translate_cached(state, buffer.payload)
    latency = DateTime.diff(DateTime.utc_now(), start_at, :nanosecond)

    metadata = %{
      latency: latency,
      pts: buffer.pts,
      input: %{
        text: buffer.payload,
        language: state.source_language_code
      }
    }

    case response do
      {:ok, [sentence]} ->
        metadata =
          Map.put(metadata, :output, %{text: sentence, language: state.target_language_code})

        {[
           buffer: {:output, %Buffer{buffer | payload: sentence}},
           notify_parent: {:translator, :translate, :ok, metadata}
         ], state}

      {:error, reason} ->
        {[
           buffer: {:output, %Buffer{buffer | payload: ""}},
           notify_parent: {:translator, :translate, {:error, reason}, metadata}
         ], state}
    end
  end

  defp translate_cached(_state, ""), do: {:ok, [""]}

  defp translate_cached(state, text) do
    ConCache.fetch_or_store(state.cache, text, fn ->
      Deepl.translate(
        state.client,
        [text],
        state.source_language_code,
        state.target_language_code
      )
    end)
  end
end
