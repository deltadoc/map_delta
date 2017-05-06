defmodule MapDelta.Composition do
  @moduledoc """
  Map deltas composition.
  """

  alias MapDelta.{Operation, PropertyDelta}

  def compose(%MapDelta{ops: [op_a]}, %MapDelta{ops: [op_b]}) do
    op_a
    |> do_compose(op_b)
    |> List.wrap()
    |> MapDelta.new()
  end

  defp do_compose(%{add: _}, %{add: _} = add_b) do
    add_b
  end

  defp do_compose(%{add: _}, %{remove: _}) do
    nil
  end

  defp do_compose(%{add: prop}, %{replace: _, init: init}) do
    Operation.add(prop, init)
  end

  defp do_compose(%{add: prop, init: init}, %{change: prop, delta: delta}) do
    Operation.add(prop, PropertyDelta.compose(init, delta))
  end

  defp do_compose(%{change: prop}, %{add: _, init: init}) do
    Operation.replace(prop, init)
  end

  defp do_compose(%{change: _}, %{remove: _} = rem) do
    rem
  end

  defp do_compose(%{change: _}, %{replace: _} = rep) do
    rep
  end

  defp do_compose(%{change: prop, delta: delta_a},
                  %{change: _, delta: delta_b}) do
    Operation.change(prop, PropertyDelta.compose(delta_a, delta_b))
  end

  defp do_compose(%{remove: prop}, %{add: _, init: init}) do
    Operation.replace(prop, init)
  end

  defp do_compose(%{remove: _}, %{remove: _} = rem_b) do
    rem_b
  end

  defp do_compose(%{remove: _}, %{replace: _} = rep) do
    rep
  end

  defp do_compose(%{remove: _} = rem, %{change: _}) do
    rem
  end

  defp do_compose(%{replace: prop}, %{add: _, init: init}) do
    Operation.replace(prop, init)
  end

  defp do_compose(%{replace: _}, %{remove: _} = rem) do
    rem
  end

  defp do_compose(%{replace: _}, %{replace: _} = rep_b) do
    rep_b
  end

  defp do_compose(%{replace: prop, init: init}, %{change: _, delta: delta}) do
    Operation.replace(prop, PropertyDelta.compose(init, delta))
  end
end
