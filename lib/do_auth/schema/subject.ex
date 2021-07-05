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

  def all_by_credential_subject(%{} = credential_subject_map) do
    from(s in __MODULE__, where: s.subject == ^credential_subject_map) |> Repo.all()
  end

  def build_from_credential_subject(credential_subject_map) do
    %{"subject" => credential_subject_map} |> changeset()
  end

  def from_credential_subject(credential_subject_map) do
    build_from_credential_subject(credential_subject_map) |> Repo.insert() |> preload()
  end

  def from_credential_subject!(credential_subject_map) do
    {:ok, subject} = from_credential_subject(credential_subject_map)
    subject
  end

  def changeset(subject_schema \\ %__MODULE__{}, third_party_data) do
    subject_schema |> cast(third_party_data, [:subject]) |> validate_required(:subject)
  end

  def to_map(%__MODULE__{} = subject) do
    subject.subject
  end

  @spec preload(%__MODULE__{}) :: %__MODULE__{} | {:ok, %__MODULE__{}} | [%__MODULE__{}]
  def preload({:ok, subject = %__MODULE__{}}) do
    {:ok, preload(subject)}
  end

  def preload(subject_data) do
    subject_data |> Repo.preload(build_preload())
  end

  # lol
  def build_preload() do
    []
  end
end
