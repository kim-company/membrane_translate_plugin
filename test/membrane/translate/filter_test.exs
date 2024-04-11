defmodule Membrane.Translate.FilterTest do
  use ExUnit.Case, async: true
  use Membrane.Pipeline
  alias Membrane.Testing.Pipeline
  import Membrane.Testing.Assertions

  @translations [
    {"Hallo, wie gehts?", "Hello, how are you?"},
    {"Herzlich willkommen", "A warm welcome"}
  ]

  test "sends the correct stream format and translates buffers" do
    translations = Map.new(@translations)

    Req.Test.stub(Deepl, fn conn ->
      case conn.path_info do
        ["v2", "languages"] ->
          Req.Test.json(conn, [
            %{
              language: "DE",
              name: "German",
              supports_formality: true
            }
          ])

        ["v2", "translate"] ->
          {:ok, body, conn} = Plug.Conn.read_body(conn)
          %{"text" => [text]} = Jason.decode!(body)

          Req.Test.json(conn, %{
            translations: [
              %{
                detected_source_language: "DE",
                text: Map.fetch!(translations, text)
              }
            ]
          })
      end
    end)

    links = [
      child(:source, %Membrane.Testing.Source{
        output: Enum.map(@translations, &elem(&1, 0)),
        stream_format: %Membrane.Text{locale: "DE"}
      })
      |> child(:translator, %Membrane.Translate.Filter{
        locale: "EN-US",
        deepl_opts: [
          plug: {Req.Test, Deepl}
        ]
      })
      |> child(:sink, %Membrane.Testing.Sink{})
    ]

    pipeline = Pipeline.start_link_supervised!(spec: links)
    Req.Test.allow(Deepl, self(), Pipeline.get_child_pid!(pipeline, :translator))

    assert_sink_stream_format(pipeline, :sink, %Membrane.Text{locale: "EN-US"})

    Enum.each(@translations, fn {_k, v} ->
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: ^v})
    end)

    assert_end_of_stream(pipeline, :sink)
  end
end
