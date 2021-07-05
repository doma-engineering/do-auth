defmodule DoAuth.Repo do
  use Ecto.Repo,
    otp_app: :do_auth,
    adapter: Ecto.Adapters.Postgres

  alias Ecto.Changeset

  @doc """
  PostgreSQL-compatible current UTC timestamp.
  """
  @spec now :: DateTime.t()
  def now() do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end

  @doc """
  Validates that there is at exactly one field set in the changeset amonst
  the fields supplied.
  """
  @spec validate_xor(Ecto.Changeset.t(), atom() | nonempty_list(atom()), keyword()) ::
          Ecto.Changeset.t()
  def validate_xor(changeset, fields, opts \\ []) when not is_nil(fields) do
    trim = Keyword.get(opts, :trim)
    xor_map = List.wrap(fields) |> Enum.map(fn x -> {x, missing?(changeset, x, trim)} end)
    has = xor_map |> Enum.filter(fn {_, b} -> not b end) |> Enum.map(&elem(&1, 0))

    case has |> length() do
      1 ->
        xor_mark_as_required(changeset, has)

      _ ->
        xor_insert_errors(
          changeset,
          xor_map |> Enum.filter(&elem(&1, 0)) |> Enum.map(&elem(&1, 0))
        )
    end
  end

  @doc """
  Validates that there is at least one field set in the changeset amongst
  the fields supplied.
  """
  @spec validate_or(Ecto.Changeset.t(), atom() | nonempty_list(atom()), keyword()) ::
          Ecto.Changeset.t()
  def validate_or(changeset, fields, opts \\ []) when not is_nil(fields) do
    trim = Keyword.get(opts, :trim)
    or_map = List.wrap(fields) |> Enum.map(fn x -> {x, missing?(changeset, x, trim)} end)
    has = or_map |> Enum.filter(fn {_, b} -> not b end) |> Enum.map(&elem(&1, 0))

    case has |> length() do
      0 ->
        or_insert_errors(
          changeset,
          or_map |> Enum.filter(&elem(&1, 0)) |> Enum.map(&elem(&1, 0))
        )

      _ ->
        or_mark_as_required(changeset, has)
    end
  end

  defp missing?(changeset, field, trim) when is_atom(field) do
    case Changeset.get_field(changeset, field) do
      %{__struct__: Ecto.Association.NotLoaded} ->
        raise ArgumentError,
              "attempting to validate association `#{field}` " <>
                "that was not loaded. Please preload your associations " <>
                "before calling validate_required/3 or pass the :required " <>
                "option to Ecto.Changeset.cast_assoc/3"

      value when is_binary(value) and trim ->
        String.trim_leading(value) == ""

      value when is_binary(value) ->
        value == ""

      nil ->
        true

      _ ->
        false
    end
  end

  defp missing?(_changeset, field, _trim) do
    raise ArgumentError,
          "validate_required/3 expects field names to be atoms, got: `#{inspect(field)}`"
  end

  defp or_mark_as_required(changeset, has) do
    %{required: required} = changeset
    %{changeset | required: has ++ required}
  end

  defp or_insert_errors(changeset, fields) do
    %{changes: changes, errors: errs} = changeset
    msg = "exactly one must be set"
    errs1 = Enum.map(fields, &{&1, {msg, [validation: :xor]}})
    cs = Map.drop(changes, fields)
    %{changeset | changes: cs, errors: errs1 ++ errs, valid?: false}
  end

  defp xor_mark_as_required(changeset, [the_field]) do
    %{required: required} = changeset
    %{changeset | required: [the_field | required]}
  end

  defp xor_insert_errors(changeset, fields) do
    %{changes: changes, errors: errs} = changeset
    msg = "exactly one must be set"
    errs1 = Enum.map(fields, &{&1, {msg, [validation: :xor]}})
    cs = Map.drop(changes, fields)
    %{changeset | changes: cs, errors: errs1 ++ errs, valid?: false}
  end
end
