defmodule DoAuth.Schema.Subject do
  @moduledoc """
  Credential subjects are just free-form claims in DoAuth thus far.

  Management of obligatory fields is deferred to modules and systems using
  DoAuth to implement authentication and authorization protocols.
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
      e -> {:error, e}
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
