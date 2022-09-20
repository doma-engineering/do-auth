defmodule Tau do
  @moduledoc """
  UTC-only timestamps, with resolution up to nanoseconds.

  We used to support VC-data-model-compatible timestamps, but we stopped doing it because of race conditions in tests etc.
  I honestly have no idea why VC data model wants time encoded up to seconds, but ok.
  """

  alias Uptight.Text, as: T
  alias Uptight.Result

  @spec resolve_old(DateTime.t()) :: DateTime.t()
  def resolve_old(dt), do: DateTime.truncate(dt, :second)

  @spec resolve(DateTime.t()) :: DateTime.t()
  def resolve(dt), do: dt

  @doc """
  PostgreSQL-compatible current UTC timestamp.
  """
  @spec now :: DateTime.t()
  def now() do
    DateTime.utc_now() |> resolve()
  end

  @doc """
  PostgreSQL-compatible ISO string to DateTime.
  """
  @spec from_utc_iso8601(T.t()) :: Result.t()
  def from_utc_iso8601(%T{} = iso_txt) do
    iso_str = iso_txt |> T.un()

    case DateTime.from_iso8601(iso_str) do
      {:ok, res, 0} ->
        res |> resolve() |> Result.Ok.new()

      {:error, e} ->
        %{"DateTime.from_iso8601 failed" => e} |> Result.Err.new()

      x ->
        %{"non-zero calendar offset produced, please submit a UTC timestamp" => x}
        |> Result.Err.new()
    end
  end

  @doc """
  Banging version!
  """
  @spec from_utc_iso8601!(T.t()) :: DateTime.t()
  def from_utc_iso8601!(%T{} = iso_txt) do
    from_utc_iso8601(iso_txt) |> Result.from_ok()
  end

  @doc """
  Defensive raw version.
  """
  @spec from_raw_utc_iso8601(binary()) :: Result.t()
  def from_raw_utc_iso8601(<<iso_str::binary>>) do
    from_utc_iso8601(iso_str |> T.new!())
  end

  @doc """
  Offensive raw version.
  """
  @spec from_raw_utc_iso8601!(binary()) :: DateTime.t()
  def from_raw_utc_iso8601!(<<iso_str::binary>>) do
    from_utc_iso8601!(iso_str |> T.new!())
  end
end
