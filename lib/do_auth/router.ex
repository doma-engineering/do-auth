defmodule DoAuth.Router do
  @moduledoc """
  Standard router to provide work with different endpoints.
  """

  use Plug.Router

  alias Uptight.Binary
  alias Uptight.Base, as: B
  alias Uptight.Text, as: T
  alias Uptight.Result
  alias :enacl, as: C

  import DynHacks

  import Witchcraft.Functor

  require Logger

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(:dispatch)

  #Let's define our /doauth/confirm endpoint
  post "/doauth/confirm/:token" do   # And then we'll define parament for token in path, which we'll use

  #Part where we need to get corresponding token out of credential storage and compare our tokens
  #TODO: unfortunately, I didn't figured out how to get token from the storage
  #I tried smth like this:
  #IO.inspect DoAuth.Credential.mk_credential!(key, %{}, [])
  #But it didn't work

    {key, salt} = DoAuth.Crypto.main_key_init(
      Result.from_ok(
        T.new(token)))
    IO.inspect key

    Logger.info("something funny")
    send_resp(conn, 200, "OK, I like it, Picasso")
  end

  match _ do
    send_resp(conn, 404, "Oops...")
  end
end
