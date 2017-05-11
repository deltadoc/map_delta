defmodule MapDelta.TransformationTest do
  use ExUnit.Case
  use EQC.ExUnit

  doctest MapDelta.Composition

  import MapDelta.Generators

  property "map states converge via opposite-priority transformations" do
    forall {map, side} <- {state(), priority_side()} do
      forall {delta_a, delta_b} <- {state_delta(map), state_delta(map)} do
        delta_a_prime = MapDelta.transform(delta_b, delta_a, side)
        delta_b_prime = MapDelta.transform(delta_a, delta_b, opposite(side))

        map_a =
          map
          |> MapDelta.compose(delta_a)
          |> MapDelta.compose(delta_b_prime)
        map_b =
          map
          |> MapDelta.compose(delta_b)
          |> MapDelta.compose(delta_a_prime)

        ensure map_a == map_b
      end
    end
  end

  describe "transform add" do
    test "against add" do
      a = MapDelta.add("a", nil)
      b = MapDelta.add("a", 5)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == MapDelta.replace("a", nil)
    end

    test "against remove" do
      a = MapDelta.remove("a")
      b = MapDelta.add("a", nil)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "against replace" do
      a = MapDelta.replace("a", 5)
      b = MapDelta.add("a", 3)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "against change" do
      # Server doesn't win as the change is incremental,
      # but the add is destructive.
      a = MapDelta.change("a", 5)
      b = MapDelta.add("a", 2)
      assert MapDelta.transform(a, b, :left) == MapDelta.replace("a", 2)
      assert MapDelta.transform(b, a, :right) == MapDelta.new()
    end
  end

  describe "transform remove" do
    test "against add" do
      a = MapDelta.add("a", nil)
      b = MapDelta.remove("a")
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "against remove" do
      a = MapDelta.remove("a")
      assert MapDelta.transform(a, a, :left) == MapDelta.new()
      assert MapDelta.transform(a, a, :right) == MapDelta.new()
    end

    test "against replace" do
      a = MapDelta.replace("a", 5)
      b = MapDelta.remove("a")
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == MapDelta.add("a", 5)
    end

    test "against change" do
      # Server doesn't win as the change is incremental,
      # but the remove is destructive.
      a = MapDelta.change("a", 5)
      b = MapDelta.remove("a")
      assert MapDelta.transform(a, b, :left) == MapDelta.remove("a")
      assert MapDelta.transform(b, a, :right) == MapDelta.new()
    end
  end

  describe "transform replace" do
    test "against add" do
      a = MapDelta.add("a", nil)
      b = MapDelta.replace("a", 5)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == MapDelta.replace("a", nil)
    end

    test "against remove" do
      a = MapDelta.remove("a")
      b = MapDelta.replace("a", nil)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "against replace" do
      a = MapDelta.replace("a", 5)
      b = MapDelta.replace("a", 2)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "against change" do
      # Server doesn't win as the change is incremental,
      # but the replace is destructive.
      a = MapDelta.change("a", 5)
      b = MapDelta.replace("a", nil)
      assert MapDelta.transform(a, b, :left) == b
      assert MapDelta.transform(b, a, :right) == MapDelta.new()
    end
  end

  describe "transform change" do
    test "against add" do
      a = MapDelta.add("a", nil)
      b = MapDelta.change("a", 5)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == MapDelta.replace("a", nil)
    end

    test "against remove" do
      a = MapDelta.remove("a")
      b = MapDelta.change("a", 5)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "against replace" do
      a = MapDelta.replace("a", 5)
      b = MapDelta.change("a", 2)
      assert MapDelta.transform(a, b, :left) == MapDelta.new()
      assert MapDelta.transform(b, a, :right) == a
    end

    test "against change" do
      a = MapDelta.change("a", 3)
      b = MapDelta.change("a", 6)
      assert MapDelta.transform(a, b, :left) == a
      assert MapDelta.transform(b, a, :right) == a
      assert MapDelta.transform(a, b, :right) == b
      assert MapDelta.transform(b, a, :left) == b
    end
  end

  describe "transform" do
    test "operations on different keys" do
      a = MapDelta.add("a", 5)
      b = MapDelta.replace("b", 3)
      assert MapDelta.transform(a, b, :left) == b
      assert MapDelta.transform(b, a, :right) == a
    end

    test "nothing against add" do
      a = MapDelta.add("a", nil)
      b = MapDelta.new()
      assert MapDelta.transform(a, b, :left) == b
      assert MapDelta.transform(b, a, :right) == a
    end

    test "add against nothing" do
      a = MapDelta.new()
      b = MapDelta.add("a", nil)
      assert MapDelta.transform(a, b, :left) == b
      assert MapDelta.transform(b, a, :right) == a
    end

    test "recursively" do
      a = MapDelta.change("a", MapDelta.add(".c", nil))
      b = MapDelta.change("a", MapDelta.add(".c", 6))
      assert MapDelta.transform(a, b, :left) ==
        MapDelta.change("a", MapDelta.new())
      assert MapDelta.transform(b, a, :right) ==
        MapDelta.change("a", MapDelta.replace(".c", nil))
    end
  end
end
