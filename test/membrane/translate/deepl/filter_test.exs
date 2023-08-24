defmodule Membrane.Translate.Deepl.FilterTest do
  use ExUnit.Case, async: false
  use Membrane.Pipeline
  import Membrane.Testing.Assertions

  @translations [
    {"Hallo, wie gehts?", "Hello, how are you?"},
    {"Herzlich willkommen", "Welcome"}
  ]

  @client Membrane.Translate.Deepl.client(endpoint: "api.deepl.com")

  test "sends the correct stream format and translates buffers" do
    translations = Map.new(@translations)

    Tesla.Mock.mock_global(fn
      %{
        method: :post,
        url: "https://api.deepl.com/v2/translate",
        body: body
      } ->
        body = URI.decode_query(body)
        translated = Map.fetch!(translations, body["text"])

        %Tesla.Env{
          status: 200,
          body: %{"translations" => [%{"text" => translated}]}
        }
    end)

    links = [
      child(:source, %Membrane.Testing.Source{
        output: Enum.map(@translations, &elem(&1, 0)),
        stream_format: %Membrane.Text{language_code: "de-DE"}
      })
      |> child(:translator, %Membrane.Translate.Deepl.Filter{
        language_code: "en-US",
        client: @client
      })
      |> child(:sink, %Membrane.Testing.Sink{})
    ]

    pipeline = Membrane.Testing.Pipeline.start_link_supervised!(structure: links)

    assert_sink_stream_format(pipeline, :sink, %Membrane.Text{language_code: "en-US"})

    Enum.each(@translations, fn {_k, v} ->
      assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: ^v})
    end)

    assert_end_of_stream(pipeline, :sink)
  end

  test "caches the translations" do
    control_pid = self()

    Tesla.Mock.mock_global(fn
      %{
        method: :post,
        url: "https://api.deepl.com/v2/translate",
        body: body
      } ->
        body = URI.decode_query(body)
        send(control_pid, {:translate, body["text"]})
        %Tesla.Env{status: 200, body: %{"translations" => [%{"text" => body["text"]}]}}
    end)

    links = [
      child(:source, %Membrane.Testing.Source{
        output: ["A", "B", "A"],
        stream_format: %Membrane.Text{language_code: "de-DE"}
      })
      |> child(:translator, %Membrane.Translate.Deepl.Filter{
        language_code: "en-US",
        client: @client
      })
      |> child(:sink, %Membrane.Testing.Sink{})
    ]

    pipeline = Membrane.Testing.Pipeline.start_link_supervised!(structure: links)
    assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: "A"})
    assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: "B"})
    assert_sink_buffer(pipeline, :sink, %Membrane.Buffer{payload: "A"})
    assert_end_of_stream(pipeline, :sink)

    assert_received {:translate, "A"}
    assert_received {:translate, "B"}
    refute_received {:translate, "A"}
  end
end
