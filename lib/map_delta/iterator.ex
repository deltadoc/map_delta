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
end
