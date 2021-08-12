defmodule DoAuth.Tofu do
  @moduledoc """
  This module is dedicated to assisting clients in getting introduced to doauth servers.
  We are inspired by TOFU, just as Gemini protocol is:

  https://drewdevault.com/2020/09/21/Gemini-TOFU.html
  """

  alias DoAuth.Crypto
  use DoAuth.Boilerplate.DatabaseStuff

  @spec tofu_credential_map() :: {:ok, %Credential{}} | {:error, String.t()}
  def tofu_credential_map() do
    %{public: pk} = Crypto.server_keypair()

    creds =
      case Subject.all_by_credential_subject(%{me: pk |> Crypto.show()}) do
        [] -> {:error, "subject with `me` key is not found"}
        [x] -> Credential.all_by_subject_id(x.id)
      end

    cred =
      case creds do
        e = {:error, _} -> e
        [] -> {:error, "subject with `me` is not attached to a credential"}
        [x] -> x
      end

    case cred do
      e = {:error, _} ->
        e

      x ->
        {:ok,
         x
         |> Credential.to_map()
         |> Map.put(:id, "#{DoAuthWeb.Endpoint.url()}/tofu")}
    end
  end
end
