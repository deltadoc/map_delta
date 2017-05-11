defmodule MapDelta.Operation do
  @moduledoc """
  Operations represent a smallest possible change applicable to a map.

  This library differentiates 4 map operations:

  - `t:MapDelta.Operation.add/0`: add item to a map under specified key with
    provided item init value
  - `t:MapDelta.Operation.remove/0`: remove item with specified key from a map
  - `t:MapDelta.Operation.replace/0`: replace item under specified key with
    different item init value
  - `t:MapDelta.Operation.change/0`: change value under specified key using
    provided item delta

  Every operation has a `key`, indicating the name of a map item to be added,
  removed, replaced or changed.

  In addition to `key` every operation except `remove` comes with an `init` or
  `delta` payloads. Both `init` and `delta` values must have implementations of
  `MapDelta.ItemDelta` protocol. This allows item values themselves to be
  recursively composed and transformed much like the `MapDelta` itself.
  """

  @typedoc """
  Add operation represents an intention to add an item into a map.

  In addition to an item key every add operation must come with an `init` value.
  `init` value, as the name suggests, is an initial value that the added item
  should have. `init` must have an associated implementation of
  `MapDelta.ItemDelta` protocol to allow its composition and transformation.
  """
  @type add :: %{add: item_key, init: item_delta}

  @typedoc """
  Remove operation represents an intention to remove an item from a map.
  """
  @type remove :: %{remove: item_key}

  @typedoc """
  Replace operation represents an intention to replace an item value in a map.

  In addition to an item key every replace operation must come with an `init`
  value. `init` value is a new initial value that the replaced item should have
  after applying the operation. `init` must have an associated implementation of
  `MapDelta.ItemDelta` protocol to allow its composition and transformation.
  """
  @type replace :: %{replace: item_key, init: item_delta}

  @typedoc """
  Change operation represents an intention to modify an item value in a map.

  In addition to an item key every replace operation must come with a `delta`
  value. `delta` value is a delta expected to be applied to the item value.
  `delta` must have an associated implementation of `MapDelta.ItemDelta` protocol
  to allow its composition and transformation.
  """
  @type change :: %{change: item_key, delta: item_delta}

  @typedoc """
  An operation. Either `add`, `remove`, `replace` or `change`.
  """
  @type t :: add | remove | replace | change

  @typedoc """
  A key of an item inside a map represented via string.
  """
  @type item_key :: String.t

  @typedoc """
  A map item delta. Must implement `MapDelta.ItemDelta` protocol.
  """
  @type item_delta :: any

  @doc """
  Creates a new `add` operation.

  ## Example

      iex> MapDelta.Operation.add("a", nil)
      %{add: "a", init: nil}
  """
  @spec add(item_key, item_delta) :: add
  def add(key, init), do: %{add: key, init: init}

  @doc """
  Creates a new `remove` operation.

  ## Example

      iex> MapDelta.Operation.remove("a")
      %{remove: "a"}
  """
  @spec remove(item_key) :: remove
  def remove(key), do: %{remove: key}

  @doc """
  Creates a new `replace` operation.

  ## Example

      iex> MapDelta.Operation.replace("a", 5)
      %{replace: "a", init: 5}
  """
  @spec replace(item_key, item_delta) :: replace
  def replace(key, init), do: %{replace: key, init: init}

  @doc """
  Creates a new `change` operation.

  ## Example

      iex> MapDelta.Operation.change("a", 3)
      %{change: "a", delta: 3}
  """
  @spec change(item_key, item_delta) :: change
  def change(key, delta), do: %{change: key, delta: delta}

  @doc """
  Returns an operation item key.

  ## Example

      iex> MapDelta.Operation.item_key(MapDelta.Operation.add("ab", 3))
      "ab"
  """
  @spec item_key(t) :: item_key
  def item_key(op)
  def item_key(%{add: key}), do: key
  def item_key(%{remove: key}), do: key
  def item_key(%{replace: key}), do: key
  def item_key(%{change: key}), do: key
end
