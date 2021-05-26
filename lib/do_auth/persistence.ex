defmodule DoAuth.Persistence do
  @moduledoc """
  OTP subtree that takes care of things that are required to persist
  claims.
  """

  use Supervisor
  import Ecto.Query
  alias DoAuth.Repo
  alias DoAuth.Crypto

  # Sadly, there doesn't seem to be a way to subscribe to Repo initialization
  # end, so we ad-hoc with transient spawn_link
  @max_retries 11

  def init(_) do
    children = [
      DoAuth.Repo,
      %{id: DoAuth.Persistence.Populate, start: {__MODULE__, :populate, []}, restart: :transient}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Exposed for testing.
  """
  @spec populate_do(any) :: any
  def populate_do(kp \\ Crypto.server_keypair(), retries \\ 0)

  def populate_do(_, @max_retries) do
    raise("Populate has reached maximum retires reached while waiting for Repo")
  end

  def populate_do(kp, retries) do
    if GenServer.whereis(Repo) do
      Repo.transaction(fn ->
        # kp = DoAuth.Crypto.server_keypair()
        pk64 = kp.public |> Crypto.show()

        impossibility =
          "Server key is added more than once. It shouldn't be possible, and signals some serious tampering."

        pk_stored =
          case pk64 |> DoAuth.Key.by_pk() |> Repo.all() do
            [] ->
              DoAuth.Key.changeset(%{public_key: pk64}) |> Repo.insert!()

            [x = %DoAuth.Key{}] ->
              x

            _ ->
              raise impossibility
          end

        did_stored =
          case DoAuth.DID.by_pk64(pk64) |> Repo.all() do
            [] ->
              DoAuth.DID.from_key(pk_stored) |> Repo.insert!()

            [x = %DoAuth.DID{}] ->
              x

            _ ->
              raise impossibility
          end

        _entity_stored =
          case DoAuth.Entity.by_did_id(did_stored.id) |> Repo.all() do
            [] ->
              DoAuth.Entity.from_did(did_stored) |> Repo.insert!()

            [x = %DoAuth.Entity{}] ->
              x

            _ ->
              raise impossibility
          end

        # case from(c in DoAuth.Subject, where: c.claim["me"] == ^pk64) |> Repo.all() do
        credential =
          case from(c in DoAuth.Subject,
                 where: fragment(~s(? ->> 'me' = ?), c.claim, ^pk64)
               )
               |> Repo.all() do
            [] ->
              DoAuth.Credential.tx_from_keypair_credential!(kp, %{me: pk64})

            [x = %DoAuth.Subject{}] ->
              from(c in DoAuth.Credential, where: c.subject_id == ^x.id) |> Repo.one!()

            _ ->
              impossibility
          end

        {:ok, credential}
      end)
    else
      populate_do(retries + 1)
    end
  end

  if Mix.env() != :test do
    @spec populate :: {:ok, pid()}
    def populate() do
      {:ok,
       spawn_link(fn ->
         populate_do()
       end)}
    end
  else
    @spec populate :: {:ok, pid()}
    def populate() do
      {:ok, spawn_link(fn -> :ok end)}
    end
  end
end
