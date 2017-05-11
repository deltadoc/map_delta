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

  def add(key, init), do: %{add: key, init: init}

  def remove(key), do: %{remove: key}

  def replace(key, init), do: %{replace: key, init: init}

  def change(key, delta), do: %{change: key, delta: delta}

  def item_key(%{add: key}), do: key
  def item_key(%{remove: key}), do: key
  def item_key(%{replace: key}), do: key
  def item_key(%{change: key}), do: key
end
