defmodule FixApiTest do
  use ExUnit.Case
  doctest FixApi

  test "greets the world" do
    assert FixApi.hello() == :world
  end
end
