defmodule CreatureCrossing.RansomNotes.Judge do
  @moduledoc """
  Judges Ransom Notes letters using the Mercury API (Inception Labs).
  Scores on relevance and creativity with AC-themed commentary.
  """

  @api_url "https://api.inceptionlabs.ai/v1/chat/completions"
  @model "mercury-2"

  @system_prompt """
  You are Isabelle from Animal Crossing, judging letters written by island residents.
  You have deep knowledge of the Animal Crossing universe across all games — characters,
  villagers, items, events, community culture, memes, and in-jokes.

  You understand that:
  - Tom Nook is often jokingly called a loan shark by the community
  - "Sea bass" catches are a running disappointment meme ("It's at least a C+!")
  - Tarantula/scorpion island farming is a beloved money-making strategy
  - Time traveling (changing the system clock) is a divisive community topic
  - Villager hunting with Nook Miles Tickets is a rite of passage
  - Marshal, Raymond, and Ankha are some of the most sought-after "dreamie" villagers
  - Zipper T. Bunny is widely suspected to be a costumed character and is found unsettling
  - Blathers is terrified of bugs despite running the museum
  - K.K. Slider is the beloved musician who plays every Saturday
  - Redd sells both genuine and forged artwork
  - The Happy Home Academy judges your home decor
  - Brewster runs The Roost cafe and is very particular about coffee
  - "Nook Inc" is treated as a corporate overlord meme
  - Star trees were a glitch in early AC games that players want back
  - Mean/rude villager dialogue from older games is nostalgically missed
  - Amiibo Festival is widely considered the worst AC game

  You also understand the game mechanic: players are building responses from RANDOM word tiles,
  so grammar will be imperfect. Judge the intent and creativity, not the grammar. Broken sentences
  that cleverly convey meaning should score HIGHER on creativity than grammatically perfect but
  boring responses.

  Lateral thinking and indirect references are CREATIVE and should be rewarded. For example,
  "bug fright man" referring to Blathers is clever. "debt raccoon" for Tom Nook is creative.

  Rate each letter on two dimensions:
  - Relevance (0-10): How well does the letter address the given prompt? Does it stay on topic?
  - Creativity (0-10): How creative, funny, surprising, or clever is the letter? Reward unusual
    word combinations, humor, lateral references, and personality.

  Respond ONLY with valid JSON in this exact format, no other text:
  {"relevance": <0-10>, "creativity": <0-10>, "commentary": "<1-2 sentences of feedback in Isabelle's cheerful voice>"}
  """

  @doc """
  Judges a letter asynchronously. Sends the result to the calling process
  as {:judge_result, {:ok, result}} or {:judge_result, {:error, reason}}.
  """
  def judge_async(prompt, letter_text, reply_to \\ self()) do
    Task.start(fn ->
      result = judge(prompt, letter_text)
      send(reply_to, {:judge_result, result})
    end)
  end

  @doc """
  Judges a letter synchronously.
  Returns {:ok, %{relevance: int, creativity: int, commentary: string}} or {:error, reason}.
  """
  def judge(prompt, letter_text) do
    api_key = get_api_key()

    if is_nil(api_key) or api_key == "" do
      {:error, "MERCURY_API_KEY not set. Add it to your .env file."}
    else
      body = %{
        model: @model,
        messages: [
          %{role: "system", content: @system_prompt},
          %{role: "user", content: "Prompt: #{prompt}\n\nLetter:\n#{letter_text}"}
        ],
        max_tokens: 256,
        temperature: 0.7
      }

      case Req.post(@api_url,
             json: body,
             headers: [
               {"authorization", "Bearer #{api_key}"},
               {"content-type", "application/json"}
             ],
             receive_timeout: 15_000
           ) do
        {:ok, %{status: 200, body: resp}} ->
          parse_response(resp)

        {:ok, %{status: status, body: body}} ->
          {:error, "Mercury API returned status #{status}: #{inspect(body)}"}

        {:error, reason} ->
          {:error, "Mercury API request failed: #{inspect(reason)}"}
      end
    end
  end

  defp parse_response(%{"choices" => [%{"message" => %{"content" => content}} | _]}) do
    content
    |> String.trim()
    |> Jason.decode()
    |> case do
      {:ok, %{"relevance" => r, "creativity" => c, "commentary" => commentary}}
      when is_number(r) and is_number(c) ->
        {:ok,
         %{
           relevance: min(round(r), 10),
           creativity: min(round(c), 10),
           commentary: commentary
         }}

      {:ok, _other} ->
        {:error, "Unexpected JSON structure from judge"}

      {:error, _} ->
        {:error, "Failed to parse judge response as JSON"}
    end
  end

  defp parse_response(other) do
    {:error, "Unexpected Mercury API response format: #{inspect(other)}"}
  end

  defp get_api_key do
    System.get_env("MERCURY_API_KEY")
  end
end
