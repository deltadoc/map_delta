defmodule MapDelta.Iterator do
  @moduledoc """
  Iterates over two sets of operations.
  """

  alias MapDelta.Operation

  def iterate(ops_a, ops_b, fun) do
    ops_a
    |> shared_item_keys(ops_b)
    |> item_operations(ops_a, ops_b)
    |> Enum.map(fun)
    |> Enum.reject(&is_nil/1)
  end

  defp shared_item_keys(ops_a, ops_b) do
    ops_a
    |> item_keys()
    |> Kernel.++(item_keys(ops_b))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp item_keys(ops) do
    Enum.map(ops, &Operation.item_key/1)
  end

  defp item_operations(item_keys, ops_a, ops_b) do
    Enum.map item_keys, fn item_key ->
      {item_operation(ops_a, item_key),
       item_operation(ops_b, item_key)}
    end
  end

  defp item_operation(ops, item_key) do
    ops
    |> Enum.filter(&(Operation.item_key(&1) == item_key))
    |> List.first()
  end
end
