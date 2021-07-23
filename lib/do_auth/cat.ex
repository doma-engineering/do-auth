defmodule DoAuth.Cat do
  @moduledoc """
  Collection of funcitons that work together with standard Elixir protocols to improve UX.
  """

  @doc """
  Exploding version of fmap.
  """
  @spec fmap!(any, any) :: list | map
  def fmap!(f_a, a__b) do
    {:ok, f_b} = fmap(f_a, a__b)
    f_b
  end

  @doc """
  Apply a function deeply traversing f_a for which an Enumerable implementation exists.
  2-tuples are traversed on the right.
  """
  @spec fmap(any, any) :: {:ok, list | map} | {:error, any}
  def fmap(%{} = f_a, a__b) do
    case fmap(f_a |> Enum.into([]), a__b) do
      {:ok, f_b} -> {:ok, f_b |> Enum.into(%{})}
      err -> err
    end
  end

  def fmap(f_a, a__b) do
    if Enumerable.impl_for(f_a) do
      {:ok, Enum.map(f_a, &fmap_do(&1, a__b))}
    else
      {:error, "f_a doesn't have Enumerable implemented for it"}
    end
  end

  defp fmap_do({k, a}, a__b) do
    {k, fmap_do(a, a__b)}
  end

  defp fmap_do(a__or__f_a, a__b) do
    if Enumerable.impl_for(a__or__f_a) do
      fmap!(a__or__f_a, a__b)
    else
      a__b.(a__or__f_a)
    end
  end

  @doc """
  Take a nillable value and if it's not nil, put_new it into the map under key.
  """
  @spec put_new_value(map(), any(), any()) :: map()
  def put_new_value(%{} = map, key, value) do
    if value == nil do
      map
    else
      Map.put_new(map, key, value)
    end
  end

  @doc """
  Take a loadable value (association) and if it's loaded, put_new it into the map under key.
  """
  @spec put_new_association(map, any, Ecto.Association.t(), (Ecto.Association.t() -> any())) ::
          map()
  def put_new_association(%{} = map, key, assoc, normalise_fn) do
    case assoc do
      %Ecto.Association.NotLoaded{} -> map
      value -> Map.put_new(map, key, normalise_fn.(value))
    end
  end
end
