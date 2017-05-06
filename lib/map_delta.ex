defmodule MapDelta do
  @moduledoc """
  Delta format for maps.
  """

  defstruct ops: []

  alias MapDelta.{Operation, PropertyDelta}

  @type t :: %MapDelta{}

  def new, do: wrap([])

  def add(prop, init), do: wrap([Operation.add(prop, init)])

  def remove(prop), do: wrap([Operation.remove(prop)])

  def replace(prop, init), do: wrap([Operation.replace(prop, init)])

  def change(prop, delta), do: wrap([Operation.change(prop, delta)])

  def compose(%MapDelta{ops: [op_a]}, %MapDelta{ops: [op_b]}) do
    op_a
    |> do_compose(op_b)
    |> List.wrap()
    |> wrap()
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

  def operations(%MapDelta{ops: ops}), do: ops

  defp wrap(ops), do: %MapDelta{ops: ops}
end

defmodule MapDelta.PropertyDelta do
  def compose(_first, second), do: second
end

defmodule MapDelta.Operation do
  @moduledoc """
  Map format for operations.
  """

  @type property :: String.t
  @type delta :: any

  @type add :: %{add: property, init: delta}
  @type remove :: %{remove: property}
  @type replace :: %{replace: property, init: delta}
  @type change :: %{change: property, delta: delta}

  @type t :: add | remove | replace | change

  def add(prop, init), do: %{add: prop, init: init}

  def remove(prop), do: %{remove: prop}

  def replace(prop, init), do: %{replace: prop, init: init}

  def change(prop, delta), do: %{change: prop, delta: delta}
end
