defmodule MapDelta do
  @moduledoc """
  Delta format for maps.
  """

  defstruct ops: []

  alias MapDelta.{Operation, Composition}

  @type t :: %MapDelta{}

  @type document :: %MapDelta{ops: [Operation.add]}

  def new(ops \\ [])
  def new([]), do: %MapDelta{}
  def new(ops) do
    ops
    |> Enum.map(&List.wrap/1)
    |> Enum.map(&wrap/1)
    |> Enum.reduce(new(), &compose(&2, &1))
  end

  def add(prop, init), do: wrap([Operation.add(prop, init)])

  def remove(prop), do: wrap([Operation.remove(prop)])

  def replace(prop, init), do: wrap([Operation.replace(prop, init)])

  def change(prop, delta), do: wrap([Operation.change(prop, delta)])

  defdelegate compose(first, second), to: Composition

  def operations(%MapDelta{ops: ops}), do: ops

  defp wrap(ops), do: %MapDelta{ops: ops}
end
