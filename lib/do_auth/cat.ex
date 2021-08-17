defmodule DoAuth.Cat do
  @moduledoc """
  Collection of funcitons that work together with standard Elixir protocols to improve UX.
  Should really be called "Control" because it basically defines functional control structures, but oh well.
  """

  @doc """
  Exploding version of fmap.
  """
  @spec fmap!(any, any) :: list | map
  def fmap!(f_a, a___b) do
    {:ok, f_b} = fmap(f_a, a___b)
    f_b
  end

  @doc """
  Apply a function deeply traversing f_a for which an Enumerable implementation exists.
  2-tuples are traversed on the right.
  """
  @spec fmap(any, any) :: {:ok, list | map} | {:error, any}
  def fmap(%{} = f_a, a___b) do
    case fmap(f_a |> Enum.into([]), a___b) do
      {:ok, f_b} -> {:ok, f_b |> Enum.into(%{})}
      err -> err
    end
  end

  def fmap(f_a, a___b) do
    if Enumerable.impl_for(f_a) do
      {:ok, Enum.map(f_a, &fmap_do(&1, a___b))}
    else
      {:error, "f_a doesn't have Enumerable implemented for it"}
    end
  end

  defp fmap_do({k, a}, a___b) do
    {k, fmap_do(a, a___b)}
  end

  defp fmap_do(a___or___f_a, a___b) do
    if Enumerable.impl_for(a___or___f_a) do
      fmap!(a___or___f_a, a___b)
    else
      a___b.(a___or___f_a)
    end
  end

  @doc """
  Take a nillable value and if it's not nil, shove it into an addressed structure under given address.
  """
  @spec fval(any(), any(), any(), any()) :: any()
  def fval(f_a_b, a, b, f_a_b___a___b___f_a_b) do
    if b == nil do
      f_a_b
    else
      f_a_b___a___b___f_a_b.(f_a_b, a, b)
    end
  end

  @doc """
  Take a nillable value and if it's not nil, put_new it into the map under key.
  """
  @spec put_value(map(), any(), any()) :: map()
  def put_value(%{} = map, key, value) do
    fval(map, key, value, &Map.put(&1, &2, &3))
  end

  @doc """
  Take a nillable value and if it's not nil, put_new it into the map under key.
  """
  @spec put_new_value(map(), any(), any()) :: map()
  def put_new_value(%{} = map, key, value) do
    fval(map, key, value, &Map.put_new(&1, &2, &3))
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

  @doc """
  Forgetful continuation over {:error, reason}, {:ok, _value}
  """
  @spec cont({:ok | :error, any()}, (() -> any())) :: {:ok | :error, any()}
  def cont({:error, _} = e, _), do: e
  def cont({:ok, _}, f), do: f.()
end
