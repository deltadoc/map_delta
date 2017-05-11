defmodule MapDelta do
  @moduledoc """
  Delta format for maps.
  """

  defstruct ops: []

  alias MapDelta.{Operation, Composition, Transformation}

  @type t :: %MapDelta{}

  @type document :: %MapDelta{ops: [Operation.add]}

  def add(key, item_init), do: wrap([Operation.add(key, item_init)])

  def remove(key), do: wrap([Operation.remove(key)])

  def replace(key, item_init), do: wrap([Operation.replace(key, item_init)])

  def change(key, item_delta), do: wrap([Operation.change(key, item_delta)])

  def new(ops \\ [])
  def new([]), do: %MapDelta{}
  def new(ops) do
    ops
    |> Enum.map(&List.wrap/1)
    |> Enum.map(&wrap/1)
    |> Enum.reduce(new(), &compose(&2, &1))
  end

  def add(delta, key, item_init) do
    compose(delta, add(key, item_init))
  end

  def remove(delta, key) do
    compose(delta, remove(key))
  end

  def replace(delta, key, item_init) do
    compose(delta, replace(key, item_init))
  end

  def change(delta, key, item_delta) do
    compose(delta, change(key, item_delta))
  end

  defdelegate compose(first, second), to: Composition

  defdelegate transform(left, right, priority), to: Transformation

  def operations(%MapDelta{ops: ops}), do: ops

  defp wrap(ops), do: %MapDelta{ops: ops}
end
