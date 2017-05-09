defmodule MapDelta.TransformationTest do
  use ExUnit.Case
  use EQC.ExUnit
  doctest MapDelta.Composition

  import MapDelta.Generators

  describe "transform" do
    test "add / add" do
      a = MapDelta.add("a", nil)
      b = MapDelta.add("a", 5)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == MapDelta.replace("a", nil)
    end

    test "add / remove" do
      a = MapDelta.add("a", nil)
      b = MapDelta.remove("a")
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "add / replace" do
      a = MapDelta.add("a", nil)
      b = MapDelta.replace("a", 5)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == MapDelta.replace("a", nil)
    end

    test "add / change" do
      a = MapDelta.add("a", nil)
      b = MapDelta.change("a", 5)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == MapDelta.replace("a", nil)
    end

    test "remove / add" do
      a = MapDelta.remove("a")
      b = MapDelta.add("a", nil)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "remove / remove" do
      a = MapDelta.remove("a")
      assert MapDelta.transform(a, a, :left) == MapDelta.new()
      assert MapDelta.transform(a, a, :right) == MapDelta.new()
    end

    test "remove / replace" do
      a = MapDelta.remove("a")
      b = MapDelta.replace("a", nil)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "remove / change" do
      a = MapDelta.remove("a")
      b = MapDelta.change("a", 5)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "replace / add" do
      a = MapDelta.replace("a", 5)
      b = MapDelta.add("a", 3)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "replace / remove" do
      a = MapDelta.replace("a", 5)
      b = MapDelta.remove("a")
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == MapDelta.add("a", 5)
    end

    test "replace / replace" do
      a = MapDelta.replace("a", 5)
      b = MapDelta.replace("a", 2)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "replace / change" do
      a = MapDelta.replace("a", 5)
      b = MapDelta.change("a", 2)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "change / add" do
      # Server doesn't win as the change is incremental,
      # but the add is destructive.
      a = MapDelta.change("a", 5)
      b = MapDelta.add("a", 2)
      assert MapDelta.transform(a, b, :left) == MapDelta.replace("a", 2)
      assert MapDelta.transform(b, a, :right) == MapDelta.new()
    end

    test "change / remove" do
      # Server doesn't win as the change is incremental,
      # but the remove is destructive.
      a = MapDelta.change("a", 5)
      b = MapDelta.remove("a")
      assert MapDelta.transform(a, b, :left) == MapDelta.remove("a")
      assert MapDelta.transform(b, a, :right) == MapDelta.new()
    end

    test "change / replace" do
      # Server doesn't win as the change is incremental,
      # but the replace is destructive.
      a = MapDelta.change("a", 5)
      b = MapDelta.replace("a", nil)
      assert MapDelta.transform(a, b, :left) == b
      assert MapDelta.transform(b, a, :right) == MapDelta.new()
    end

    test "change / change" do
      a = MapDelta.change("a", 3)
      b = MapDelta.change("a", 6)
      assert MapDelta.transform(a, b, :left) == a
      assert MapDelta.transform(b, a, :right) == a
      assert MapDelta.transform(a, b, :right) == b
      assert MapDelta.transform(b, a, :left) == b
    end
  end
end
