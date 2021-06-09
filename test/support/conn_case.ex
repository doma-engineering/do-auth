defmodule DoAuth.Web.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      alias DoAuth.Web.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint DoAuth.Web
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DoAuth.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(DoAuth.Repo, {:shared, self()})
    end

    %{conn: Phoenix.ConnTest.build_conn()}
  end
end
