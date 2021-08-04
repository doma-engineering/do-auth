defmodule DoAuth.NickServ do
  @moduledoc """
  Naive way to attach nicknames to DIDs.
  """

  alias Ecto.Adapters.SQL
  alias DoAuth.{Crypto, Parsers}
  import DoAuth.Cat, only: [cont: 2]

  use DoAuth.Boilerplate.DatabaseStuff

  @spec register64(map) :: {:error, any} | {:ok, any}
  def register64(%{} = register_cred_map) do
    # This is the actual logic
    finally = fn ->
      register64_do(
        nickname(register_cred_map),
        did(register_cred_map),
        discoverable_default(register_cred_map, false)
      )
    end

    # Validate once before locking to exit early
    register64_validate(register_cred_map)
    |> cont(fn ->
      Repo.transaction(fn ->
        SQL.query!(Repo, "LOCK credentials IN EXCLUSIVE MODE;")
        # Validate again with the exclusive lock
        register64_validate(register_cred_map) |> cont(finally)
      end)
    end)
  end

  defp register64_do(nickname, holder, discoverable) do
    with kp <- Crypto.server_keypair() do
      misc =
        if discoverable do
          %{"location" => "/nickserv/" <> nickname}
        else
          %{}
        end

      Credential.transact_with_keypair_from_subject_map(
        kp,
        %{"kind" => "nickserv", "nickname" => nickname, "holder" => holder},
        misc
      )
    end
  end

  defp register64_validate(register_cred_map) do
    if DID.exists64(did_default(register_cred_map)) do
      is_valid_nickname(nickname(register_cred_map))
      |> cont(fn -> Crypto.verify_map(register_cred_map) end)
      |> cont(fn -> is_vacant(nickname(register_cred_map), did(register_cred_map)) end)
    else
      {:error,
       %{
         "did is not registered in doauth" => did(register_cred_map),
         "offender" => register_cred_map
       }}
    end
  end

  @spec is_valid_nickname(binary) ::
          {:error,
           %{
             optional(<<_::96, _::_*32>>) =>
               binary | {:ok, list, binary, map, {any, any}, pos_integer}
           }}
          | {:ok, true}
  def is_valid_nickname(nickname) do
    parse_res = Parsers.nickname(nickname)

    case parse_res do
      {:ok, _, "", _, _, _} ->
        {:ok, true}

      _ ->
        {:error, %{"invalid nickname" => nickname, "parse result" => parse_res}}
    end
  end

  @spec is_vacant(nil) :: {:error, <<_::272>>}
  def is_vacant(nil) do
    {:error, "Desired `nickname` is not provided"}
  end

  @spec is_vacant(any, binary) :: {:error, any} | {:ok, any}
  def is_vacant(nickname, did) do
    is_vacant_did(did) |> cont(fn -> is_vacant_nickname(nickname) end)
  end

  @spec is_vacant_did(binary) :: {:error, %{optional(<<_::176>>) => any}} | {:ok, true}
  def is_vacant_did(did) do
    case whois_did64(did) do
      {:ok, found_nickname} -> {:error, %{"did already registered" => found_nickname}}
      {:error, :not_found} -> {:ok, true}
    end
  end

  @spec is_vacant_nickname(binary) :: {:error, <<_::112>>} | {:ok, true}
  def is_vacant_nickname(nickname) do
    case whois_nickname(nickname) do
      {:ok, _found_did} -> {:error, "nickname taken"}
      {:error, :not_found} -> {:ok, true}
    end
  end

  @spec whois_nickname(binary) ::
          {:error, :not_found | %{optional(<<_::64, _::_*40>>) => binary}} | {:ok, any}
  def whois_nickname(<<nickname::binary>>) do
    case nickserv_subjects()
         |> Subject.compose_by_kv("nickname", nickname)
         |> Repo.all()
         |> Subject.preload() do
      [] ->
        {:error, :not_found}

      [%Subject{subject: subject}] ->
        {:ok, subject["holder"]}

      _ ->
        {:error,
         %{
           "impossibility" => "more than one DID registered as the same nickname",
           "offender" => nickname
         }}
    end
  end

  @spec whois_did64(binary) ::
          {:error, :not_found | %{optional(<<_::64, _::_*40>>) => binary}} | {:ok, any}
  def whois_did64(<<did64::binary>>) do
    case nickserv_subjects()
         |> Subject.compose_by_kv("holder", did64)
         |> Repo.all()
         |> Subject.preload() do
      [] ->
        {:error, :not_found}

      [%Subject{subject: subject}] ->
        {:ok, subject["nickname"]}

      _ ->
        {:error,
         %{
           "impossibility" => "more than one nickname belongs to a single DID",
           "offender" => did64
         }}
    end
  end

  @spec nickserv_subjects :: Ecto.Query.t()
  def nickserv_subjects() do
    Subject.build_by_kv("kind", "nickserv")
  end

  defp nickname(cred) do
    cred["credentialSubject"]["nickname"]
  end

  # defp nickname_default(cred, default \\ "") do
  #   Map.get(cred, "credentialSubject", %{}) |> Map.get("nickname", default)
  # end

  defp discoverable_default(cred, default) do
    Map.get(cred, "credentialSubject", %{}) |> Map.get("discoverable", default)
  end

  defp did(cred) do
    cred["proof"]["verificationMethod"]
  end

  defp did_default(cred, default \\ "") do
    Map.get(cred, "proof", %{}) |> Map.get("verificationMethod", default)
  end
end
