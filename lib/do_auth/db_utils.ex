defmodule DoAuth.DBUtils do
  @moduledoc """
  Meta-module to import and alias handy things when it comes to defining
  schemas.
  """
  import Ecto.Changeset
  alias Ecto.Changeset

  @spec __using__([] | [{:into, any}, ...]) ::
          {:__block__, [], [{:=, [], [...]} | {:__block__, [], [...]}, ...]}
  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts, module: opts[:into]] do
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query, only: [from: 2]

      alias DoAuth.Repo
      alias Ecto.Schema
      alias Ecto.Changeset
      alias DoAuth.DBUtils

      if module do
        @typedoc """
        Used to definine changeset/2 that has `cast/4` as its first step.

        Cauldron is where the ingredients go, after we throw away the spoiled
        ones.
        """
        @type cauldron() ::
                Schema.t()
                | Changeset.t()
                | Changeset.t(%unquote(module){})
                | %unquote(module){}
                | {Changeset.data(), Changeset.types()}

        @typedoc """
        Used to define changeset/2 that has `cast/4` as its first step.

        Ingredients is the stuff that users or anyone, really, can wish to put
        into the cauldron.
        """
        @type ingredients() ::
                %{binary() => term()}
                | %{atom => term}
                | :invalid
      end
    end
  end

  @spec codegen([] | [{:into, any()}, ...]) ::
          {:__block__, [], [{:=, [], [...]} | {:if, [...], [...]}, ...]}
  defmacro codegen(opts \\ []) do
    quote bind_quoted: [opts: opts, module: opts[:into]] do
      if module do
        if !opts[:only_binary] and !opts[:no_changeset] do
          @spec changeset(ingredients()) :: Changeset.t()
          def changeset(stuff), do: changeset(%unquote(module){}, stuff)
        end

        if opts[:canonical_from_map] do
          @spec to_json(%unquote(module){}) :: binary()
          def to_json(x) do
            to_map(x) |> Jason.encode!()
          end

          @spec to_ebin(%unquote(module){}) :: binary()
          def to_ebin(x) do
            to_map(x) |> :erlang.term_to_binary()
          end
        end

        if opts[:canonical_from_show] do
          @spec to_json(%unquote(module){}) :: binary()
          def to_json(x) do
            show(x) |> Jason.encode!()
          end

          @spec to_ebin(%unquote(module){}) :: binary()
          def to_ebin(x) do
            :erlang.term_to_binary(x)
          end
        end
      end
    end
  end

  @doc """
  PostgreSQL-compatible current UTC timestamp.
  """
  @spec now :: DateTime.t()
  def now() do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end

  @doc """
  Standard changeset that's used rather often. Casts and requires the same fileds.
  """
  @spec castreq(map() | {Changeset.data(), Changeset.types()}, map(), atom() | list(atom) | atom) ::
          Changeset.t()
  def castreq(cauldron, ingredients, fields) do
    with xs <- List.wrap(fields) do
      cauldron |> cast(ingredients, xs) |> validate_required(xs)
    end
  end

  @doc """
  Validates that there is at exactly one field set in the changeset amonst
  the fields supplied.
  """
  @spec validate_xor(Ecto.Changeset.t(), atom() | nonempty_list(atom()), keyword()) ::
          Ecto.Changeset.t()
  def validate_xor(changeset = %Changeset{}, fields, opts \\ []) when not is_nil(fields) do
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
  def validate_or(changeset = %Changeset{}, fields, opts \\ []) when not is_nil(fields) do
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

  defp or_mark_as_required(changeset = %Changeset{}, has) do
    %{required: required} = changeset
    %{changeset | required: has ++ required}
  end

  defp or_insert_errors(changeset = %Changeset{}, fields) do
    %{changes: changes, errors: errs} = changeset
    msg = "exactly one must be set"
    errs1 = Enum.map(fields, &{&1, {msg, [validation: :xor]}})
    cs = Map.drop(changes, fields)
    %{changeset | changes: cs, errors: errs1 ++ errs, valid?: false}
  end

  defp xor_mark_as_required(changeset = %Changeset{}, [the_field]) do
    %{required: required} = changeset
    %{changeset | required: [the_field | required]}
  end

  defp xor_insert_errors(changeset = %Changeset{}, fields) do
    %{changes: changes, errors: errs} = changeset
    msg = "exactly one must be set"
    errs1 = Enum.map(fields, &{&1, {msg, [validation: :xor]}})
    cs = Map.drop(changes, fields)
    %{changeset | changes: cs, errors: errs1 ++ errs, valid?: false}
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
end
