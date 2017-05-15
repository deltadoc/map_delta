defmodule MapDelta do
  @moduledoc """
  Map delta is a format used to describe map states and changes.

  At the low level map delta is simply an array of `t:MapDelta.Operation.t/0`.
  Each operation contains an `t:MapDelta.Operation.item_key/0` and delta insures
  that it represents the shortest path to an end state through composition.
  Enforced composition means there's always only one operation per a single item
  key.

  Map delta can describe both map changes and maps themselves. We can think of a
  final map state as an artefact of all the item additions to it. This way final
  state of a map is represented simply as an array of `add` operations.

  Map deltas are also transformable. This attribute of deltas is what enables
  [Operational Transformation][ot] - a way to transform one operation against
  the context of another one. Operational Transformation allows us to build
  optimistic, non-locking collaborative editors.

  ## Example

      iex> delta = MapDelta.add("a", nil)
      %MapDelta{ops: [%{add: "a", init: nil}]}
      iex> delta = MapDelta.compose(delta, MapDelta.change("a", 3))
      %MapDelta{ops: [%{add: "a", init: 3}]}
      iex> MapDelta.compose(delta, MapDelta.remove("a"))
      %MapDelta{ops: []}

  [ot]: https://en.wikipedia.org/wiki/Operational_transformation
  """

  alias MapDelta.{Operation, Composition, Transformation}

  defstruct ops: []

  @typedoc """
  Map delta is a set of `t:MapDelta.Operation.t/0` operations.
  """
  @type t :: %MapDelta{ops: [Operation.t]}

  @typedoc """
  A map state represented as a set of `t:MapDelta.Operation.add/0` operations.
  """
  @type state :: %MapDelta{ops: [Operation.add]}

  @doc """
  Creates new map delta.

  ## Examples

      iex> MapDelta.new()
      %MapDelta{}

  You can also pass set of operations using optional argument:

      iex> MapDelta.new([MapDelta.Operation.add("a", 5)])
      %MapDelta{ops: [%{add: "a", init: 5}]}

  Given operations will be compacted/composed appropriately:

      iex> MapDelta.new([MapDelta.Operation.add("a", 5),
      iex>               MapDelta.Operation.change("a", 3)])
      %MapDelta{ops: [%{add: "a", init: 3}]}
  """
  @spec new([Operation.t]) :: t
  def new(ops \\ [])
  def new([]), do: %MapDelta{}
  def new(ops) do
    ops
    |> Enum.map(&wrap/1)
    |> Enum.reduce(new(), &compose(&2, &1))
  end

  @doc """
  Creates a new `add` delta.

  Uses `MapDelta.Operation.add/2` under the hood.

  Function has an optional first argument, which you can use to provide existing
  delta. In that case newly generated `add` delta will be composed with the
  given one.

  ## Examples

      iex> delta = MapDelta.add("a", nil)
      %MapDelta{ops: [%{add: "a", init: nil}]}
      iex> MapDelta.add(delta, "b", 3)
      %MapDelta{ops: [%{add: "a", init: nil}, %{add: "b", init: 3}]}
  """
  @spec add(t, Operation.item_key, Operation.item_delta) :: t
  def add(delta \\ %MapDelta{}, item_key, item_init) do
    compose(delta, wrap(Operation.add(item_key, item_init)))
  end

  @doc """
  Creates a new `remove` delta.

  Uses `MapDelta.Operation.remove/1` under the hood.

  Function has an optional first argument, which you can use to provide existing
  delta. In that case newly generated `remove` delta will be composed with the
  given one.

  ## Examples

      iex> delta = MapDelta.remove("a")
      %MapDelta{ops: [%{remove: "a"}]}
      iex> MapDelta.remove(delta, "b")
      %MapDelta{ops: [%{remove: "a"}, %{remove: "b"}]}
  """
  @spec remove(t, Operation.item_key) :: t
  def remove(delta \\ %MapDelta{}, item_key) do
    compose(delta, wrap(Operation.remove(item_key)))
  end

  @doc """
  Creates a new `replace` delta.

  Uses `MapDelta.Operation.replace/2` under the hood.

  Function has an optional first argument, which you can use to provide existing
  delta. In that case newly generated `replace` delta will be composed with the
  given one.

  ## Examples

      iex> delta = MapDelta.replace("a", 6)
      %MapDelta{ops: [%{replace: "a", init: 6}]}
      iex> MapDelta.replace(delta, "a", 2)
      %MapDelta{ops: [%{replace: "a", init: 2}]}
  """
  @spec replace(t, Operation.item_key, Operation.item_delta) :: t
  def replace(delta \\ %MapDelta{}, item_key, item_init) do
    compose(delta, wrap(Operation.replace(item_key, item_init)))
  end

  @doc """
  Creates a new `change` delta.

  Uses `MapDelta.Operation.change/2` under the hood.

  Function has an optional first argument, which you can use to provide existing
  delta. In that case newly generated `change` delta will be composed with the
  given one.

  ## Examples

      iex> delta = MapDelta.change("a", 2)
      %MapDelta{ops: [%{change: "a", delta: 2}]}
      iex> MapDelta.change(delta, "a", 3)
      %MapDelta{ops: [%{change: "a", delta: 3}]}
  """
  @spec change(t, Operation.item_key, Operation.item_delta) :: t
  def change(delta \\ %MapDelta{}, item_key, item_delta) do
    compose(delta, wrap(Operation.change(item_key, item_delta)))
  end

  @doc """
  Applies given delta to a particular map state, resulting in a new state.

  Map state is a set of `add` operations. If composing state with delta results
  in anything but a set of `add` operations, `:error` tuple is returned instead.

  ## Examples

      iex> state = MapDelta.add("a", nil)
      %MapDelta{ops: [%{add: "a", init: nil}]}
      iex> MapDelta.apply_to_state(MapDelta.change("a", 5), state)
      {:ok, %MapDelta{ops: [%{add: "a", init: 5}]}}
  """
  @spec apply_to_state(t, state) :: {:ok, state} | {:error, atom}
  def apply_to_state(delta, state) do
    new_state = compose(state, delta)
    case has_only_add_operations?(new_state) do
      true -> {:ok, new_state}
      false -> {:error, :bad_state}
    end
  end

  @doc """
  Applies given delta to a particular map state, resulting in a new state.

  Equivalent to `&MapDelta.apply_to_state/2`, but raises an exception on failed
  composition.
  """
  @spec apply_to_state!(t, state) :: state
  def apply_to_state!(delta, state) do
    case apply_to_state(delta, state) do
      {:ok, new_state} ->
        new_state
      {:error, :bad_state} ->
        raise "Application resulted in a bad state"
    end
  end

  defdelegate compose(first, second), to: Composition
  defdelegate transform(left, right, priority), to: Transformation

  @doc """
  Returns list of operations in the given delta.

  ## Example

      iex> MapDelta.new()
      iex> |> MapDelta.add("a", 3)
      iex> |> MapDelta.remove("b")
      iex> |> MapDelta.operations()
      [%{add: "a", init: 3}, %{remove: "b"}]
  """
  @spec operations(t) :: [Operation.t]
  def operations(delta)
  def operations(delta), do: delta.ops

  defp wrap(ops), do: %MapDelta{ops: List.wrap(ops)}

  defp has_only_add_operations?(delta) do
    delta.ops
    |> Enum.filter(&(Operation.type(&1) != :add))
    |> Enum.count()
    |> Kernel.==(0)
  end
end
