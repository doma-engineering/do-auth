defmodule DoAuth.Web do
  @moduledoc """
  OTP subtree that takes care of things that are required for DoAuth HTTP
  backend.
  """
  use Phoenix.Endpoint, otp_app: :do_auth

  plug(Plug.Static,
    at: "/",
    from: {:do_auth, "priv/static"},
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
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

  def controller do
    quote do
      use Phoenix.Controller, namespace: DoAuth.Web
      import Plug.Conn
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/do_auth/web/templates",
        namespace: DoAuth.Web

      use Phoenix.HTML
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
