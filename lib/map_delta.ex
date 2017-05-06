defmodule MapDelta do
  @moduledoc """
  Delta format for maps.
  """

  defstruct ops: []

  alias MapDelta.{Operation, Composition}

  @type t :: %MapDelta{}

  def new(ops \\ []), do: wrap(ops)

  def add(prop, init), do: wrap([Operation.add(prop, init)])

  def remove(prop), do: wrap([Operation.remove(prop)])

  def replace(prop, init), do: wrap([Operation.replace(prop, init)])

  def change(prop, delta), do: wrap([Operation.change(prop, delta)])

  defdelegate compose(first, second), to: Composition

  def operations(%MapDelta{ops: ops}), do: ops

  defp wrap(ops), do: %MapDelta{ops: ops}
end
