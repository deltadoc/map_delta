defmodule MapDeltaTest do
  use ExUnit.Case
  doctest MapDelta

  alias MapDelta.Operation

  describe "construct" do
    test "add" do
      assert ops(MapDelta.add("a", nil)) == [Operation.add("a", nil)]
    end

    test "remove" do
      assert ops(MapDelta.remove("a")) == [Operation.remove("a")]
    end

    test "replace" do
      assert ops(MapDelta.replace("a", 2)) == [Operation.replace("a", 2)]
    end

    test "change" do
      assert ops(MapDelta.change("a", 5)) == [Operation.change("a", 5)]
    end
  end

  describe "compose" do
    test "add with add" do
      a = MapDelta.add("a", nil)
      b = MapDelta.add("a", 5)
      assert MapDelta.compose(a, b) == b
    end

    test "add with remove" do
      a = MapDelta.add("a", nil)
      b = MapDelta.remove("a")
      assert MapDelta.compose(a, b) == MapDelta.new()
    end

    test "add with replace" do
      a = MapDelta.add("a", nil)
      b = MapDelta.replace("a", 2)
      assert MapDelta.compose(a, b) == MapDelta.add("a", 2)
    end

    test "add with change" do
      a = MapDelta.add("a", 2)
      b = MapDelta.change("a", 3)
      assert MapDelta.compose(a, b) == MapDelta.add("a", 3)
    end

    test "change with add" do
      a = MapDelta.change("a", 5)
      b = MapDelta.add("a", 3)
      assert MapDelta.compose(a, b) == MapDelta.replace("a", 3)
    end

    test "change with remove" do
      a = MapDelta.change("a", 5)
      b = MapDelta.remove("a")
      assert MapDelta.compose(a, b) == b
    end

    test "change with replace" do
      a = MapDelta.change("a", 3)
      b = MapDelta.replace("a", nil)
      assert MapDelta.compose(a, b) == b
    end

    test "change with change" do
      a = MapDelta.change("a", 3)
      b = MapDelta.change("a", 5)
      assert MapDelta.compose(a, b) == MapDelta.change("a", 5)
    end

    test "remove with add" do
      a = MapDelta.remove("a")
      b = MapDelta.add("a", 3)
      assert MapDelta.compose(a, b) == MapDelta.replace("a", 3)
    end

    test "remove with remove" do
      a = MapDelta.remove("a")
      b = MapDelta.remove("a")
      assert MapDelta.compose(a, b) == b
    end

    test "remove with replace" do
      a = MapDelta.remove("a")
      b = MapDelta.replace("a", 5)
      assert MapDelta.compose(a, b) == b
    end

    test "remove with change" do
      # Technically this should never happen as
      # it is obviously a broken-state operation,
      # resulting in a change loss.
      #
      # But I'm covering it anyways, just in case.
      a = MapDelta.remove("a")
      b = MapDelta.change("a", 5)
      assert MapDelta.compose(a, b) == a
    end

    test "replace with add" do
      a = MapDelta.replace("a", 3)
      b = MapDelta.add("a", 5)
      assert MapDelta.compose(a, b) == MapDelta.replace("a", 5)
    end

    test "replace with remove" do
      a = MapDelta.replace("a", 3)
      b = MapDelta.remove("a")
      assert MapDelta.compose(a, b) == b
    end

    test "replace with replace" do
      a = MapDelta.replace("a", 3)
      b = MapDelta.replace("a", 5)
      assert MapDelta.compose(a, b) == b
    end

    test "replace with change" do
      a = MapDelta.replace("a", 3)
      b = MapDelta.change("a", 5)
      assert MapDelta.compose(a, b) == MapDelta.replace("a", 5)
    end
  end

  defp ops(delta), do: MapDelta.operations(delta)
end
