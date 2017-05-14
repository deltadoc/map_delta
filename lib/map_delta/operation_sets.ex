defmodule MapDelta.OperationSets do
  @moduledoc """
  Logic to operate on sets of operations.
  """

  alias MapDelta.Operation

  @typedoc """
  Set of operations.
  """
  @type set :: [Operation.t]

  @typedoc """
  Pair of operation sets.
  """
  @type sets :: {set, sets}

  @typedoc """
  Pair of operations.
  """
  @type pair :: {Operation.t, Operation.t}

  @typedoc """
  List of operation pairs.
  """
  @type pairs :: [pair]

  @doc """
  Pairs operations from two given sets by their item keys.

  ## Example

      iex> ops_a = [MapDelta.Operation.add("a", nil),
      iex>          MapDelta.Operation.remove("b")]
      [%{add: "a", init: nil}, %{remove: "b"}]
      iex> ops_b = [MapDelta.Operation.change("a", 4),
      iex>          MapDelta.Operation.replace("c", nil)]
      [%{change: "a", delta: 4}, %{replace: "c", init: nil}]
      iex> MapDelta.OperationSets.item_pairs({ops_a, ops_b})
      [{%{add: "a", init: nil}, %{change: "a", delta: 4}},
       {%{remove: "b"}, nil},
       {nil, %{replace: "c", init: nil}}]
  """
  @spec item_pairs(sets) :: pairs
  def item_pairs({ops_a, ops_b}) do
    ops_a
    |> shared_item_keys(ops_b)
    |> item_operations(ops_a, ops_b)
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
