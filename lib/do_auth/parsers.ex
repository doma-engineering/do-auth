defmodule DoAuth.Parsers do
  @moduledoc """
  Collection of handy combinatorial parsers. Because parse, not validate!
  """

  import NimbleParsec

  defparsec(
    :nickname,
    [ascii_char([?_]), ascii_char([?0..?9]), ascii_char([?a..?z])] |> choice() |> repeat()
  )
end
