defmodule MapDelta.ApplicationTest do
  use ExUnit.Case
  use EQC.ExUnit

  doctest MapDelta.Application

  alias MapDelta.Operation
  import MapDelta.Generators

  property "state modifications always result in a proper state" do
    forall state <- state() do
      forall delta <- state_delta(state) do
        new_state = MapDelta.apply!(state, delta)
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

  describe "apply" do
    test "nothing" do
      state = MapDelta.new()
      delta = MapDelta.new()
      assert MapDelta.apply(state, delta) == {:ok, state}
    end

    test "adding a field" do
      state = MapDelta.new()
      delta = MapDelta.add("a", nil)
      assert MapDelta.apply(state, delta) == {:ok, delta}
    end

    test "changng a field" do
      state = MapDelta.add("a", nil)
      delta = MapDelta.change("a", 5)
      assert MapDelta.apply(state, delta) == {:ok, MapDelta.add("a", 5)}
    end

    test "removing a field" do
      state = MapDelta.add("a", nil)
      delta = MapDelta.remove("a")
      assert MapDelta.apply(state, delta) == {:ok, MapDelta.new()}
    end

    test "attempting to change inexistent field" do
      state = MapDelta.new()
      delta = MapDelta.change("a", 5)
      assert MapDelta.apply(state, delta) ==
        {:error, ["a"], :item_not_found}
    end

    test "attempting to remove inexistent field" do
      state = MapDelta.new()
      delta = MapDelta.remove("b")
      assert MapDelta.apply(state, delta) ==
        {:error, ["b"], :item_not_found}
    end

    test "attempting to remove deep inexistent field" do
      state = MapDelta.add("a", MapDelta.new())
      delta = MapDelta.change("a", MapDelta.remove("b"))
      assert MapDelta.apply(state, delta) ==
        {:error, ["a", "b"], :item_not_found}
    end

    test "a force, by changing a field" do
      state = MapDelta.add("a", nil)
      delta = MapDelta.change("a", 5)
      assert MapDelta.apply!(state, delta) == MapDelta.add("a", 5)
    end

    test "a force, by changing inexistent field" do
      state = MapDelta.new()
      delta = MapDelta.change("a", 5)
      assert_raise RuntimeError, fn ->
        MapDelta.apply!(state, delta)
      end
    end
  end
end
