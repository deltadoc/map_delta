defmodule MapDelta.Iterator do
  @moduledoc """
  Iterates over two sets of operations.
  """

  alias MapDelta.Operation

  def iterate(ops_a, ops_b, fun) do
    ops_a
    |> Kernel.++(ops_b)
    |> Enum.group_by(&Operation.property/1)
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(fun)
    |> Enum.concat()
  end

  def iterate2(ops_a, ops_b, fun) do
    ops_a
    |> shared_properties(ops_b)
    |> property_operations(ops_a, ops_b)
    |> Enum.map(fun)
    |> Enum.concat()
  end

  defp shared_properties(ops_a, ops_b) do
    ops_a
    |> properties()
    |> Kernel.++(properties(ops_b))
    |> Enum.dedup()
  end

  defp properties(ops) do
    Enum.map(ops, &Operation.property/1)
  end

  defp property_operations(props, ops_a, ops_b) do
    Enum.map props, fn prop ->
      {property_operation(ops_a, prop),
       property_operation(ops_b, prop)}
    end
  end

  defp property_operation(ops, prop) do
    ops
    |> Enum.filter(&(Operation.property(&1) == prop))
    |> List.first()
  end
end
