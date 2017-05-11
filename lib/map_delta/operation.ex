defmodule MapDelta.Operation do
  @moduledoc """
  Map format for operations.
  """

  @type item_key :: String.t
  @type item_delta :: any

  @type add :: %{add: item_key, init: item_delta}
  @type remove :: %{remove: item_key}
  @type replace :: %{replace: item_key, init: item_delta}
  @type change :: %{change: item_key, delta: item_delta}

  @type t :: add | remove | replace | change

  def add(prop, init), do: %{add: prop, init: init}

  def remove(prop), do: %{remove: prop}

  def replace(prop, init), do: %{replace: prop, init: init}

  def change(prop, item_delta), do: %{change: prop, delta: item_delta}

  def item_key(%{add: prop}), do: prop
  def item_key(%{remove: prop}), do: prop
  def item_key(%{replace: prop}), do: prop
  def item_key(%{change: prop}), do: prop
end
