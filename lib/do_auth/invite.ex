defmodule DoAuth.Invite do
  @moduledoc """
  Functions to make invites.
  So far, it supports number-bound invites.

  When an invite is accepted and client certificate is generated, a server-signed credential get issued that effectively reduces the "invite issued" count.
  """

  use DoAuth.Boilerplate.DatabaseStuff
  alias DoAuth.{Crypto, Presentation}
  import DoAuth.Cat, only: [const: 1]

  @spec grant(%DID{}, pos_integer(), list()) :: {:ok, %Credential{}} | {:error, any()}
  def grant(did, n, opts \\ []) do
    try do
      {:ok, grant!(did, n, opts)}
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end

  @spec grant!(%DID{}, pos_integer(), map(), list()) :: %Credential{}
  def grant!(%DID{} = did, n, misc \\ %{}, opts \\ []) do
    with kp <- Crypto.server_keypair() do
      invite =
        Credential.transact_with_keypair_from_subject_map!(
          kp,
          %{
            "kind" => "invite",
            "capacity" => n,
            "holder" => DID.to_string(did)
          },
          Map.merge(
            %{
              "location" =>
                "/invites/" <>
                  Crypto.salted_hash(
                    ~s(invite|#{inspect(n)}|#{DID.to_string(did)}|#{inspect(DateTime.utc_now())})
                  )
            },
            misc
          ),
          opts
        )
        |> Credential.to_map()

      {:ok, res} = Presentation.present_credential_map(kp, invite)
      res
    end
  end

  @spec fulfill(String.t(), map()) :: any()
  def fulfill(pk64, %{} = invite_presentation_map) do
    try do
      %{} = invite_map = Map.get(invite_presentation_map, "verifiableCredential", %{})
      true = is_public_key_unregistered(pk64)

      {:ok, true} =
        case Crypto.verify_map(invite_presentation_map) do
          {:error, _something} ->
            Crypto.verify_map(invite_presentation_map, key_extractor: const(pk64))

          ok = {:ok, true} ->
            ok
        end

      true = is_presentation_vacant(invite_presentation_map)

      :ok = fulfill_do!(invite_presentation_map)

      Repo.transaction(fn ->
        Credential.transact_with_keypair_from_subject_map!(Crypto.server_keypair(), %{
          "parent" => invite_map["id"],
          "signature" => invite_presentation_map["proof"]["signatre"],
          "kind" => "decrement"
        })

        did = DID.sin_one_pk64!(pk64)

        Credential.transact_with_keypair_from_subject_map!(Crypto.server_keypair(), %{
          "parent" => invite_map["id"],
          "holder" => did |> DID.to_string(),
          "kind" => "fulfill"
        })
      end)
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end

  defp fulfill_do!(%{} = invite_presentation_map) do
    credential_map = Map.get(invite_presentation_map, "verifiableCredential")

    {invite_presentation_map, credential_map} =
      case Map.get(credential_map, "verifiableCredential") do
        nil -> {invite_presentation_map, credential_map}
        actual_cred -> {credential_map, actual_cred}
      end

    true = is_vacant(credential_map)
    true = is_issued_by_us(credential_map) || is_presenter_the_holder(invite_presentation_map)
    true = is_contemporary(credential_map)
    # Saving the heaviest computation for the last
    {:ok, true} = Crypto.verify_map(credential_map)
    :ok
  end

  defp is_presentation_vacant(%{} = invite_presentation_map) do
    signature = invite_presentation_map |> Map.get("proof") |> Map.get("signature")

    is_presented_by_us(invite_presentation_map) ||
      0 ==
        from(s in Subject,
          where:
            fragment(~s(? ->> 'signature' = ?), s.subject, ^signature) and
              fragment(~s(? ->> 'kind' = ?), s.subject, "decrement")
        )
        |> Repo.aggregate(:count)
  end

  defp is_vacant(%{} = credential_map) do
    invite_id = Map.get(credential_map, "id")

    credential_map |> Map.get("credentialSubject") |> Map.get("capacity", -1) >
      from(s in Subject,
        where:
          fragment(~s(? ->> 'parent' = ?), s.subject, ^invite_id) and
            fragment(~s(? ->> 'kind' = ?), s.subject, "decrement")
      )
      |> Repo.aggregate(:count)
  end

  defp is_issued_by_us(%{} = credential_map) do
    %{public: pk} = Crypto.server_keypair()
    did = DID.one_by_pk!(pk)
    credential_map["issuer"] == did |> DID.to_string()
  end

  defp is_presenter_the_holder(presentation_map) do
    presentation_map["issuer"] == presentation_map["verifiableCredential"]["holder"]
  end

  defp is_presented_by_us(presentation_map) do
    %{public: pk} = Crypto.server_keypair()
    presentation_map["issuer"] == DID.one_by_pk!(pk)
  end

  defp is_contemporary(credential_map) do
    require Logger
    tau0 = Repo.now()
    g = &Map.get(credential_map, &1, &2)

    valid_from = g.("validFrom", g.("effectiveDate", g.("issuanceDate", nil)))

    valid_until = g.("validUntil", g.("expirationDate", nil))

    true =
      if valid_from == nil do
        throw(ArgumentError.message(%{message: "issuanceDate is missing"}))
      else
        {:ok, valid_from, 0} = valid_from |> DateTime.from_iso8601()
        Enum.member?([:gt, :eq], DateTime.compare(tau0, valid_from))
      end

    true =
      if valid_until == nil do
        true
      else
        {:ok, valid_until, 0} = valid_until |> DateTime.from_iso8601()
        Enum.member?([:lt, :eq], DateTime.compare(tau0, valid_until))
      end

    true
  end

  defp is_public_key_unregistered(pk64) do
    [] == DID.all_by_pk64(pk64)
  end
end
