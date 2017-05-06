defmodule MapDelta.Composition do
  @moduledoc """
  Map deltas composition.
  """

  alias MapDelta.{Operation, PropertyDelta}

  def compose(%MapDelta{ops: ops_a}, %MapDelta{ops: ops_b}) do
    ops_a
    |> Kernel.++(ops_b)
    |> Enum.group_by(&Operation.property/1)
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&do_compose/1)
    |> Enum.concat()
    |> MapDelta.new()
  end

  defp do_compose([_] = ops) do
    ops
  end

  defp do_compose([%{add: _}, %{add: _} = add_b]) do
    [add_b]
  end

  defp do_compose([%{add: _}, %{remove: _}]) do
    []
  end

  defp do_compose([%{add: prop}, %{replace: _, init: init}]) do
    [Operation.add(prop, init)]
  end

  defp do_compose([%{add: prop, init: init}, %{change: _, delta: delta}]) do
    [Operation.add(prop, PropertyDelta.compose(init, delta))]
  end

  defp do_compose([%{replace: prop, init: init}, %{change: _, delta: delta}]) do
    [Operation.replace(prop, PropertyDelta.compose(init, delta))]
  end

  defp do_compose([%{change: prop, delta: delta_a},
                   %{change: _, delta: delta_b}]) do
    [Operation.change(prop, PropertyDelta.compose(delta_a, delta_b))]
  end

  defp do_compose([%{remove: _} = remove, %{change: _}]) do
    [remove]
  end

  defp do_compose([_, %{add: prop, init: init}]) do
    [Operation.replace(prop, init)]
  end

  defp do_compose([_, %{remove: _} = remove]) do
    [remove]
  end

  defp do_compose([_, %{replace: _} = replace]) do
    [replace]
  end
end
