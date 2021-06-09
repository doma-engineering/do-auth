defmodule DoAuth.NickServ do
  alias Ecto.Adapters.SQL
  alias DoAuth.DID
  alias DoAuth.Repo
  alias DoAuth.Credential
  alias DoAuth.Crypto
  alias DoAuth.Subject
  alias DoAuth.Parsers

  import Ecto.Query

  # TODO: Since we're speedrunning this shit, we're really ifgnoring the fact
  # that we need to actually sign registration request on client! It needs to be
  # fixed.

  def register(did = %DID{}, nickname, cloaked \\ true) do
    register64(did |> DID.show(), nickname, cloaked)
  end

  @doc """
  Registers a single (so far) nickname per registered DID.
  """
  def register64(<<did64::binary>>, <<nickname::binary>>, cloaked \\ true) do
    Repo.transaction(fn ->
      # TODO: Repo.one!() / Repo.get_by! are DANGEROUS. I honestly have no
      # fucking idea why do I keep using it without thinking well enough. "Let
      # it crash?" :D
      _did = Repo.get_by!(DID, body: DID.read(did64).body)
      # TODO: less smelly way to do this?
      {:ok, _, "", _, _, _} = Parsers.nickname(nickname)

      SQL.query!(Repo, "LOCK credentials IN EXCLUSIVE MODE;")

      {:error, :not_found} = whois(nickname)
      # We permit only one nickname per identity right now
      {:error, :not_found} = whois64(did64)

      misc =
        if cloaked do
          %{}
        else
          %{location: "/nickserv/" <> nickname}
        end

      Credential.tx_from_keypair_credential!(
        Crypto.server_keypair(),
        %{
          kind: "nameserv_register",
          nickname: nickname,
          holder: did64,
          attestedBy: (Application.get_env(:do_auth, DoAuth.Web) |> Keyword.fetch!(:url))[:host]
        },
        misc
      )
    end)
  end

  def whois64(<<did64::binary>>) do
    case(
      from(c in Subject,
        where:
          fragment(
            ~s(? ->> 'kind' = 'nameserv_register' and ? ->> 'holder' = ?),
            c.claim,
            c.claim,
            ^did64
          )
      )
      |> Repo.all()
    ) do
      [] -> {:error, :not_found}
      [x] -> {:ok, Credential.by_subject(x)}
      _ -> raise "Tampering!"
    end
  end

  @doc """
  Check (under transaction and an exclusive lock) that a user is registered.
  """
  def whois(did = %DID{}) do
    whois64(did |> DID.show())
  end

  def whois(<<nickname::binary>>) do
    case(
      from(c in Subject,
        where:
          fragment(
            ~s(? ->> 'kind' = 'nameserv_register' and ? ->> 'nickname' = ?),
            c.claim,
            c.claim,
            ^nickname
          )
      )
      |> Repo.all()
    ) do
      [] -> {:error, :not_found}
      [x] -> {:ok, Credential.by_subject(x)}
      _ -> raise "Tampering!"
    end
  end

  # TODO: GROUP?..
  # TODO: ALTER?..
end
