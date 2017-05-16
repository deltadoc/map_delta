defmodule MapDeltaTest do
  use ExUnit.Case
  use EQC.ExUnit

  doctest MapDelta

  alias MapDelta.Operation
  import MapDelta.Generators

  property "state modifications always result in a proper state" do
    forall state <- non_empty(state()) do
      forall delta <- state_delta(state) do
        new_state = MapDelta.apply_to_state!(delta, state)
        operation_types =
          new_state
          |> MapDelta.operations()
          |> Enum.map(&Operation.type/1)
          |> Kernel.++([:add])
          |> Enum.uniq()
        ensure operation_types == [:add]
      end
    end
  end

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

    test "composition of multiple operations" do
      delta =
        MapDelta.new()
        |> MapDelta.add("a", nil)
        |> MapDelta.change("b", 4)
        |> MapDelta.change("a", 3)
        |> MapDelta.remove("b")
        |> MapDelta.change("a", 5)
      assert ops(delta) == [Operation.add("a", 5), Operation.remove("b")]
    end
  end

  describe "modify state" do
    test "by doing nothing" do
      state = MapDelta.new()
      delta = MapDelta.new()
      assert MapDelta.apply_to_state(delta, state) == {:ok, state}
    end

    test "by adding a field" do
      state = MapDelta.new()
      delta = MapDelta.add("a", nil)
      assert MapDelta.apply_to_state(delta, state) == {:ok, delta}
    end

    test "by changng a field" do
      state = MapDelta.add("a", nil)
      delta = MapDelta.change("a", 5)
      assert MapDelta.apply_to_state(delta, state) == {:ok, MapDelta.add("a", 5)}
    end

    test "by removing a field" do
      state = MapDelta.add("a", nil)
      delta = MapDelta.remove("a")
      assert MapDelta.apply_to_state(delta, state) == {:ok, MapDelta.new()}
    end

    test "by attempting to change inexistent field" do
      state = MapDelta.new()
      delta = MapDelta.change("a", 5)
      assert MapDelta.apply_to_state(delta, state) ==
        {:error, {["a"], :item_not_found}}
    end

    test "by attempting to remove inexistent field" do
      state = MapDelta.new()
      delta = MapDelta.remove("b")
      assert MapDelta.apply_to_state(delta, state) ==
        {:error, {["b"], :item_not_found}}
    end

    test "by attempting to remove deep inexistent field" do
      state = MapDelta.add("a", MapDelta.new())
      delta = MapDelta.change("a", MapDelta.remove("b"))
      assert MapDelta.apply_to_state(delta, state) ==
        {:error, {["a", "b"], :item_not_found}}
    end

    test "with a force, by changing a field" do
      state = MapDelta.add("a", nil)
      delta = MapDelta.change("a", 5)
      assert MapDelta.apply_to_state!(delta, state) == MapDelta.add("a", 5)
    end

    test "with a force, by changing inexistent field" do
      state = MapDelta.new()
      delta = MapDelta.change("a", 5)
      assert_raise RuntimeError, fn ->
        MapDelta.apply_to_state!(delta, state)
      end
    end
  end

  defp ops(delta), do: MapDelta.operations(delta)
end
