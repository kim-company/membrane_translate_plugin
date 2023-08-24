defmodule Membrane.TranslateTest do
  use ExUnit.Case
  doctest Membrane.Translate

  test "greets the world" do
    assert Membrane.Translate.hello() == :world
  end
end
