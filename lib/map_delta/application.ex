defmodule MapDelta.Application do
  @moduledoc """
  Application of a map delta to a map state, resulting in a new state.

  Map state is represented as a set of `t:MapDelta.Operation.add/0` operations.
  By this token, applying delta to a state must always result in a set of `add`
  operations. If application results in anything but a set of `add` operatins,
  this is conisdered an error.

  In simpler terms, you would not be able to remove, change or replace items
  that weren't been first added to the map.
  """

  alias MapDelta.{Operation, OperationSets, ItemDelta}

  @typedoc """
  Specifies path at which error happened.
  """
  @type item_path :: [String.t]

  @typedoc """
  A reason for an application error.
  """
  @type error_reason :: :item_not_found

  @typedoc """
  Result of an application.

  Either an `:ok` tupple with a new `t:MapDelta.state/0` or an `:error` tupple
  with a `t:MapDelta.Application.error_reason/0` as well as
  `t:MapDelta.Application.item_path/0`.
  """
  @type result :: {:ok, MapDelta.state}
                | {:error, item_path, error_reason}

  @doc """
  Applies given delta to a particular map state, resulting in a new state.

  Map state is a set of `add` operations. If composing state with delta results
  in anything but a set of `add` operations, `:error` tuple is returned instead.

  ## Examples

      iex> state = MapDelta.add("a", nil)
      %MapDelta{ops: [%{add: "a", init: nil}]}
      iex> MapDelta.apply(state, MapDelta.change("a", 5))
      {:ok, %MapDelta{ops: [%{add: "a", init: 5}]}}
      iex> MapDelta.apply(state, MapDelta.remove("b"))
      {:error, ["b"], :item_not_found}
  """
  @spec apply(MapDelta.state, MapDelta.t) :: result
  def apply(state, delta) do
    result =
      {MapDelta.operations(state), MapDelta.operations(delta)}
      |> OperationSets.item_pairs()
      |> Enum.reduce_while([], &do_apply/2)
    case result do
      {:error, path, reason} ->
        {:error, path, reason}
      ops ->
        {:ok, %MapDelta{ops: ops}}
    end
  end

  alias MapDelta

  @doc """
  Applies given delta to a particular map state, resulting in a new state.

  Equivalent to `&MapDelta.apply/2`, but raises an exception on failed
  application.
  """
  @spec apply!(MapDelta.state, MapDelta.t) :: MapDelta.state | no_return
  def apply!(state, delta) do
    case __MODULE__.apply(state, delta) do
      {:ok, new_state} ->
        new_state
      {:error, path, reason} ->
        path_string = Enum.join(path, ".")
        reason_string = Atom.to_string(reason)
        raise "Map application error (`#{path_string}`: #{reason_string})"
    end
  end

  defp do_apply({%{add: _} = add, nil}, ops) do
    {:cont, ops ++ [add]}
  end

  defp do_apply({_, %{add: _} = add}, ops) do
    {:cont, ops ++ [add]}
  end

  defp do_apply({%{add: _}, %{remove: _}}, ops) do
    {:cont, ops}
  end

  defp do_apply({%{add: key}, %{replace: _, init: init}}, ops) do
    add = Operation.add(key, init)
    {:cont, ops ++ [add]}
  end

  defp do_apply({%{add: key, init: init}, %{change: _, delta: delta}}, ops) do
    case ItemDelta.apply(init, delta) do
      {:ok, new_delta} ->
        add = Operation.add(key, new_delta)
        {:cont, ops ++ [add]}
      {:error, path, reason} ->
        {:halt, {:error, [key | path], reason}}
    end
  end

  defp do_apply({%{} = op_a, _}, _) do
    key = Operation.item_key(op_a)
    {:halt, {:error, [key], :item_not_found}}
  end

  defp do_apply({_, %{} = op_b}, _) do
    key = Operation.item_key(op_b)
    {:halt, {:error, [key], :item_not_found}}
  end
end
