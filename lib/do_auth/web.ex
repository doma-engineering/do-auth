defmodule DoAuth.Web do
  @moduledoc """
  OTP subtree that takes care of things that are required for DoAuth HTTP
  backend.

  Serves asset files from ./priv/static verbatim.

  Otherwise initiates a session storage under _do_auth_non_tracking_cookie;
  Sets up RequestId, Logger, and Parsers
  And finally lets DoAuth.Web.Router take over.

  Also defines some convenience macros:
   - controller
   - router
   - view
  "exporting" them with `__using__`.
  It seems to be an idiomatic way to do that.
  """
  use Phoenix.Endpoint, otp_app: :do_auth

  plug(Plug.Static,
    at: "/",
    from: {:do_auth, "priv/static"},
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  # TODO: Move it to CHAP.CHAP
  # Abuses Set-Cookie header to put a signed KVS into it! :mind-blown.png:
  # Maximum amount of data stored in one session is very limited: 4KiB (4096 bytes)
  plug(Plug.Session,
    store: :cookie,
    key: "_do_auth_non_tracking_cookie",
    # TODO: rotate salts regularly!
    signing_salt: Application.get_env(:do_auth, DoAuth.Web) |> Keyword.fetch!(:signing_salt),
    same_site: "Strict"
  )

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(DoAuth.Web.Router)

  #### Boring meta-programming that seem to be idiomatic to Phoenix :thinking:

  @spec controller :: {:__block__, [], [{:import, [...], [...]} | {:use, [...], [...]}, ...]}
  def controller do
    quote do
      use Phoenix.Controller, namespace: DoAuth.Web
      import Plug.Conn
    end
  end

  @spec router :: {:__block__, [], [{:import, [...], [...]} | {:use, [...], [...]}, ...]}
  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  @spec view :: {:__block__, [], [{:use, [...], [...]}, ...]}
  def view do
    quote do
      use Phoenix.View,
        root: "lib/do_auth/web/templates",
        namespace: DoAuth.Web

      use Phoenix.HTML
    end
  end

  @spec __using__(atom) :: any
  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
