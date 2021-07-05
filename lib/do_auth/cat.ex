defmodule DoAuth.Cat do
  @moduledoc """
  Collection of funcitons that work together with standard Elixir protocols to improve UX.
  """

  @doc """
  Exploding version of fmap.
  """
  def fmap!(f_a, a__b) do
    {:ok, f_b} = fmap(f_a, a__b)
    f_b
  end

  @doc """
  Apply a function deeply traversing f_a for which an Enumerable implementation exists.
  2-tuples are traversed on the right.
  """
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
end
