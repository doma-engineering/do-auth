defmodule DoAuth.Chappy.Chappy do
  @moduledoc """
  This CHAP-inspired implementation is made to be compatible with Plug
  pipelines. Protects your non-PFS channels from replay attacks.

              !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
              ! Requires plug(:fetch_session) !
              ! Assumes cookie-based sessions !
              !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
              !    YOUR PROGRAM MOST LIKELY   !
              ! DOESN'T NEED THIS IF YOU ARE  !
              !      OK WITH REPLAYS OR       !
              ! GUARANTEED TO SERVE THE DATA  !
              ! OVER PFS TLS:                 !
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ! https://en.wikipedia.org/wiki/Forward_secrecy#Protocols !
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  The idea is that you can drop it into your pipeline and it shall create a
  session based on a chain of challenge-response objects that shall be sent
  along with the responses.

  Authenticated mode:

  Client |  ~GET /api/chappy,                        | Server
         |   x-doma-chappy-pk: Base64(nacl_pk)~>     |
         |                                           | [Find session for PK]
         |  <~200, Phoenix Session Cookie,           |
         |    x-doma-chappy-chal: chal~              |
         |                                           |
         | ~PUT /book/nāves%20ēnā,                   |
         |   Phoenix Session Cookie,                 |
         |   x-doma-chappy-resp: sig(chal)~>         |
         |                                           |
         |  <~OK, Phoenix Session Cookie,            |
         |    x-doma-chappy-chal: chal1~             |
         |

  Unauthenticated mode simply repeats the X-CHAP header contents.

  Currently only unauthenticated mode is implemented because it protects from
  replay attacks, but not from MITM, but MITM has a really tiny surface in
  the modern TLS-enabled world.

  ## Setup example

  First of all, make a :chappy pipeline in your Router.
  It shall only be used by /chappy endpoint (you are free to call it whatever):

  ```
    pipeline :chappy do
      plug(:accepts, ["json"])
      plug(:fetch_session)
    end

    scope "/chappy", YourWeb do
      pipe_through(:chappy)
      get("/", Chappy, :the_endpoint)
    end
  ```

  And then to protect your entire API from replay attacks:

  ```
    pipeline :api do
      plug(:accepts, ["json"])
      plug(:fetch_session)
      plug(Chappy)
    end

    scope "/api", DoAuth do
      pipe_through(:api)
      get("/demo", YourWeb.Controller, :demo)
    end
  ```

  """

  use Phoenix.Controller, namespace: DoAuth.Web
  import Plug.Conn
  alias DoAuth.Chappy.ChappyView, as: View

  # TODO: consider making it into a configurable setting
  @token_size 8

  def init(x), do: x

  @doc """
  Only permit initialisation of a challenge chain from "the endpoint".
  All the other occurrecnces of calls to this controller shall be assumed to
  have proper header set up.

  This is ":the_endpoint" from the setup example in the moduledoc.
  """
  def call(c, :the_endpoint) do
    the_endpoint(c, get_session(c, :chappy_token))
  end

  def call(c, _) do
    [supplied_token | _] = get_req_header(c, "x-doma-chappy-resp")
    {c, t} = unauthenticated_do(c, get_session(c, :chappy_token), supplied_token)
    c |> put_view(View) |> render("chain.json", token: t)
  end

  defp the_endpoint(c, nil) do
    {c, t} = mk_token(c)

    c
    |> put_view(View)
    |> render("success.json", token: t)
  end

  defp the_endpoint(c, t) do
    [supplied_token | _] = get_req_header(c, "x-doma-chappy-resp")
    {c, t} = unauthenticated_do(c, t, supplied_token)

    c
    |> put_view(View)
    |> render("chain.json", token: t)
  end

  # Here a problem with return value or something was because I piped
  # put_session(..) to put_resp_header.
  #
  # TODO: Use this in something like "common dialyzer errors" cheatsheet or
  # post
  defp mk_token(c) do
    with t <- :crypto.strong_rand_bytes(@token_size) |> Base.url_encode64() do
      c = put_session(c, :chappy_token, t)
      {Plug.Conn.put_resp_header(c, "x-doma-chappy", t), t}
    end
  end

  defp unauthenticated_do(c, x, x) do
    mk_token(c)
  end

  defp unauthenticated_do(_c, x, y) do
    raise "Chappy header mismatch: #{inspect(x)} != #{inspect(y)}."
  end
end
