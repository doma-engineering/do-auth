### See https://hexdocs.pm/ecto/testing-with-ecto.html

defmodule DoAuth.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias DoAuth.Repo

      import Ecto
      import Ecto.Query
      import DoAuth.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DoAuth.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(DoAuth.Repo, {:shared, self()})
    end

    :ok
  end
end
