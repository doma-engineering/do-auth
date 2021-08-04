defmodule DoAuth.Schema.Subject do
  @moduledoc """
  Credential subjects are just free-form claims in DoAuth thus far.
  This choice wasn't made to increase already present confusion in specification-readers between "credential subject" as in "the protagonist of a credential" (the intended meaning) and "subject" as in "the topic of a credential" (the unintended meaning).
  Instead, we simply can't be bothered to import all the DIDs in our database and for our purposes, it feels rather silly to attempt it at this point.

  This is why, at this point, management of obligatory fields and matters of maintaining DID archive is deferred to modules and systems using DoAuth to implement authentication and authorization protocols.
  """
  use DoAuth.Boilerplate.DatabaseStuff

  schema "subjects" do
    field(:subject, :map)
    field(:misc, :map)
  end

  @spec sin_any_credential_subject(map()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def sin_any_credential_subject(credential_subject) do
    try do
      {:ok, sin_any_credential_subject!(credential_subject)}
    rescue
      e -> {:error, %{"exception" => e, "stack trace" => __STACKTRACE__}}
    end
  end

  @spec sin_any_credential_subject!(map()) :: %__MODULE__{}
  def sin_any_credential_subject!(credential_subject) do
    {:ok, res} =
      Repo.transaction(fn ->
        case Subject.all_by_credential_subject(credential_subject) do
          [%Subject{} = s | _] -> s
          [] -> Subject.from_credential_subject!(credential_subject)
        end
      end)

    res
  end

  @spec compose_by_kv(Ecto.Query.t() | atom(), String.t(), any()) :: Ecto.Query.t()
  def compose_by_kv(query, key, value) do
    from(s in query,
      where:
        fragment(
          ~s(? ->> ? = ?),
          s.subject,
          ^key,
          ^value
        )
    )
  end

  @spec all_by_kv(String.t(), any()) :: [%__MODULE__{}]
  def all_by_kv(key, value) do
    build_by_kv(key, value) |> Repo.all() |> preload()
  end

  @spec build_by_kv(String.t(), String.t()) :: Ecto.Query.t()
  def build_by_kv(key, value) do
    compose_by_kv(__MODULE__, key, value)
  end

  @spec all_by_credential_subject(map()) :: [%__MODULE__{}]
  def all_by_credential_subject(%{} = credential_subject_map) do
    from(s in __MODULE__, where: s.subject == ^credential_subject_map) |> Repo.all()
  end

  @spec build_from_credential_subject(map()) :: Changeset.t()
  def build_from_credential_subject(credential_subject_map) do
    %{"subject" => credential_subject_map} |> changeset()
  end

  @spec from_credential_subject(map()) :: {:ok, %__MODULE__{}}
  def from_credential_subject(credential_subject_map) do
    build_from_credential_subject(credential_subject_map) |> Repo.insert() |> preload()
  end

  @spec from_credential_subject!(map()) :: %__MODULE__{}
  def from_credential_subject!(credential_subject_map) do
    {:ok, subject} = from_credential_subject(credential_subject_map)
    subject
  end

  @spec changeset(%__MODULE__{}, map()) :: Changeset.t()
  def changeset(subject_schema \\ %__MODULE__{}, third_party_data) do
    subject_schema |> cast(third_party_data, [:subject]) |> validate_required(:subject)
  end

  @spec to_map(%__MODULE__{}) :: map()
  def to_map(%__MODULE__{} = subject) do
    subject.subject
  end

  @spec preload(
          %__MODULE__{}
          | {:ok, %__MODULE__{}}
          | list(%__MODULE__{})
          | {:error, any()}
        ) ::
          %__MODULE__{}
          | {:ok, %__MODULE__{}}
          | list(%__MODULE__{})

  def preload({:error, e}), do: {:error, e}

  def preload({:ok, subject = %__MODULE__{}}) do
    {:ok, preload(subject)}
  end

  def preload(subject_data) do
    subject_data |> Repo.preload(build_preload())
  end

  # lol
  @spec build_preload :: list()
  def build_preload() do
    []
  end
end
