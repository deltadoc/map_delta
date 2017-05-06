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
