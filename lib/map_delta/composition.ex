defmodule MapDelta.Composition do
  @moduledoc """
  Map deltas composition.
  """

  alias MapDelta.{Operation, Operations, ItemDelta}

  def compose(first, second) do
    {MapDelta.operations(first), MapDelta.operations(second)}
    |> Operations.group_by_item()
    |> Enum.map(&do_compose/1)
    |> Enum.reject(&is_nil/1)
    |> wrap_into_delta()
  end

  defp do_compose({op_a, nil}) do
    op_a
  end

  defp do_compose({nil, op_b}) do
    op_b
  end

  defp do_compose({%{add: _}, %{add: _} = add_b}) do
    add_b
  end

  defp do_compose({%{add: _}, %{remove: _}}) do
    nil
  end

  defp do_compose({%{add: key}, %{replace: _, init: init}}) do
    Operation.add(key, init)
  end

  defp do_compose({%{add: key, init: init}, %{change: _, delta: delta}}) do
    Operation.add(key, ItemDelta.compose(init, delta))
  end

  defp do_compose({%{replace: key, init: init}, %{change: _, delta: delta}}) do
    Operation.replace(key, ItemDelta.compose(init, delta))
  end

  defp do_compose({%{change: key, delta: delta_a},
                   %{change: _, delta: delta_b}}) do
    Operation.change(key, ItemDelta.compose(delta_a, delta_b))
  end

  defp do_compose({%{remove: _} = remove, %{change: _}}) do
    remove
  end

  defp do_compose({_, %{add: key, init: init}}) do
    Operation.replace(key, init)
  end

  defp do_compose({_, %{remove: _} = remove}) do
    remove
  end

  defp do_compose({_, %{replace: _} = replace}) do
    replace
  end

  defp wrap_into_delta(ops), do: %MapDelta{ops: ops}
end
