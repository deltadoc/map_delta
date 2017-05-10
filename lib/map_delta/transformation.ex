defmodule MapDelta.Transformation do
  @moduledoc """
  Map deltas transformation.
  """

  alias MapDelta.{Operation, Iterator, ItemDelta}

  def transform(%MapDelta{ops: ops_a}, %MapDelta{ops: ops_b}, priority) do
    ops_a
    |> Iterator.iterate2(ops_b, &do_transform(&1, priority))
    |> wrap_into_delta()
  end

  defp do_transform({nil, right}, _) do
    [right]
  end

  defp do_transform({_, nil}, _) do
    []
  end

  defp do_transform({%{remove: _}, %{remove: _}}, :right) do
    []
  end

  defp do_transform({_, %{remove: _} = remove}, :right) do
    [remove]
  end

  defp do_transform({%{change: _}, %{remove: _} = remove}, :left) do
    [remove]
  end

  defp do_transform({%{remove: _}, %{add: _} = add}, :right) do
    [add]
  end

  defp do_transform({%{remove: _}, %{replace: prop, init: init}}, :right) do
    [Operation.add(prop, init)]
  end

  defp do_transform({_, %{add: prop, init: init}}, :right) do
    [Operation.replace(prop, init)]
  end

  defp do_transform({%{change: _}, %{add: prop, init: init}}, :left) do
    [Operation.replace(prop, init)]
  end

  defp do_transform({_, %{replace: _} = replace}, :right) do
    [replace]
  end

  defp do_transform({%{change: _}, %{replace: _} = replace}, :left) do
    [replace]
  end

  defp do_transform({%{change: prop, delta: left},
                     %{change: _, delta: right}}, priority) do
    [Operation.change(prop, ItemDelta.transform(left, right, priority))]
  end

  defp do_transform({_, _}, _) do
    []
  end

  defp wrap_into_delta(ops), do: %MapDelta{ops: ops}
end
