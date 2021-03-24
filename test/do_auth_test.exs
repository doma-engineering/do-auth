defmodule DoAuthTest do
  use ExUnit.Case
  doctest DoAuth

  test "greets the world" do
    assert DoAuth.hello() == :world
  end
end
