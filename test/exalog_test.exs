defmodule ExalogTest do
  use ExUnit.Case
  doctest Exalog

  test "greets the world" do
    assert Exalog.hello() == :world
  end
end
