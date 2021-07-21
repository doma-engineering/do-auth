defmodule DoAuth.Repo.Populate do
  @moduledoc """
  This is a moderately ugly way to ensure that the mission-critical data is
  populated in the Postgres database at each start.
  """

  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.{Crypto, Invite}

  @max_retries 10

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

  @doc """
  Exposed for testing.
  """
  @spec populate_do(%{secret: binary(), public: binary()}, non_neg_integer()) ::
          {:ok, %Credential{}}
  def populate_do(kp \\ Crypto.server_keypair(), retries \\ 0)

  def populate_do(_, @max_retries) do
    raise("Populate has reached maximum retires reached while waiting for Repo")
  end

  def populate_do(kp, retries) do
    if GenServer.whereis(Repo) do
      {:ok, credential} =
        Repo.transaction(fn ->
          pk64 = kp.public |> Crypto.show()

          %Issuer{} = DID.sin_one_pk64!(pk64) |> Issuer.sin_one_did!()

          credential =
            case Subject.all_by_credential_subject(%{"me" => pk64}) do
              [] ->
                Credential.transact_with_keypair_from_subject_map!(kp, %{"me" => pk64})

              [x = %Subject{}] ->
                from(c in Credential, where: c.subject_id == ^x.id) |> Repo.one!()

              _ ->
                raise "Server key is added more than once. It shouldn't be possible, and signals some serious tampering."
            end

          credential
        end)

      ensure_root_invite!()
      {:ok, credential |> Credential.preload()}
    else
      populate_do(retries + 1)
    end
  end

  @spec ensure_root_invite!({} | %DID{}) :: %Credential{}
  def ensure_root_invite!(did_stored \\ {}) do
    did_stored =
      if did_stored == {} do
        DID.one_by_pk64!(Crypto.server_keypair64()[:public])
      else
        did_stored
      end

    did_as_string = DID.to_string(did_stored)

    q0 =
      from(s in Subject,
        where:
          fragment(
            "? ->> 'kind' = 'invite' AND ? ->> 'holder' = ?",
            s.subject,
            s.subject,
            ^did_as_string
          )
      )

    case q0 |> Repo.all() do
      [] ->
        Invite.grant!(did_stored, Application.get_env(:do_auth, :default_root_invites))

      [x = %Subject{}] ->
        Credential.one_by_subject_id!(x.id)

      # from(c in Credential, where: c.subject_id == ^x.id) |> Repo.one!()

      _ ->
        raise "Multiple root invites were generated. It is impossible and signals serious tampering or exploitation."
    end
  end
end
