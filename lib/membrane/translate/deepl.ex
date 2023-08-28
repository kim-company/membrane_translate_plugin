defmodule Membrane.Translate.Deepl do
  # TODO: Check other deepl options like `formality`, `split_sentences` ect...

  @type t :: %__MODULE__{client: Tesla.Client.t()}
  defstruct client: nil

  # https://www.deepl.com/docs-api/translate-text/translate-text
  @supported_languages [
    {"BG", "Bulgarian"},
    {"CS", "Czech"},
    {"DA", "Danish"},
    {"DE", "German"},
    {"EL", "Greek"},
    {"EN-GB", "English (British)"},
    {"EN-US", "English (American)"},
    {"ES", "Spanish"},
    {"ET", "Estonian"},
    {"FI", "Finnish"},
    {"FR", "French"},
    {"HU", "Hungarian"},
    {"ID", "Indonesian"},
    {"IT", "Italian"},
    {"JA", "Japanese"},
    {"KO", "Korean"},
    {"LT", "Lithuanian"},
    {"LV", "Latvian"},
    {"NB", "Norwegian (Bokmål)"},
    {"NL", "Dutch"},
    {"PL", "Polish"},
    {"PT-BR", "Portuguese (Brazilian)"},
    {"PT-PT", "Portuguese (all Portuguese varieties excluding Brazilian Portuguese)"},
    {"RO", "Romanian"},
    {"RU", "Russian"},
    {"SK", "Slovak"},
    {"SL", "Slovenian"},
    {"SV", "Swedish"},
    {"TR", "Turkish"},
    {"UK", "Ukrainian"},
    {"ZH", "Chinese (simplified)"}
  ]

  @type sentence :: String.t()

  @type option() :: {:timeout, pos_integer()}
  @spec client([option()]) :: t()
  def client(opts \\ []) do
    api_key = opts[:auth_key]
    endpoint = opts[:endpoint]
    timeout = Keyword.get(opts, :timeout, 3_000)

    # NOTE: Maybe we should add retries. We should consider that the maximum timeout of the filter element shouldn't be exceeded.

    middleware = [
      {Tesla.Middleware.BaseUrl, "https://#{endpoint}/v2/"},
      {Tesla.Middleware.Headers, [{"authorization", "DeepL-Auth-Key #{api_key}"}]},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.FormUrlencoded,
      {Tesla.Middleware.Timeout, timeout: timeout}
    ]

    %__MODULE__{client: Tesla.client(middleware)}
  end

  def supported_languages(), do: @supported_languages

  @spec translate(t(), [sentence()], Membrane.Text.Language.code(), Membrane.Text.Language.code()) ::
          {:ok, [sentence()]} | {:error, String.t()}
  def translate(client, sentences, from, to) do
    from = parse_language!(from) |> String.slice(0, 2)
    to = parse_language!(to)

    body =
      sentences
      |> Enum.map(&{"text", &1})
      |> Enum.concat([{"source_lang", from}, {"target_lang", to}])

    case Tesla.post(client.client, "translate", body) do
      {:ok, %Tesla.Env{body: %{"translations" => translations}}} ->
        sentences = Enum.map(translations, fn %{"text" => x} -> x end)
        {:ok, sentences}

      {:ok, %Tesla.Env{} = env} ->
        {:error,
         "translation error. status: #{inspect(env.status)}, headers: #{inspect(env.headers)}, body: #{inspect(env.body)}"}

      {:error, error} ->
        {:error, "translation error. #{inspect(error)}"}
    end
  end

  defp parse_language!(code) do
    {:ok, code} = parse_language(code)
    code
  end

  defp parse_language(code) do
    code =
      code
      |> to_string()
      |> String.upcase()

    language_codes = Enum.map(@supported_languages, fn {x, _} -> x end)

    cond do
      code in language_codes ->
        {:ok, code}

      (short = String.slice(code, 0, 2)) in language_codes ->
        {:ok, short}

      true ->
        {:error, "unsupported language #{inspect(code)}"}
    end
  end
end
