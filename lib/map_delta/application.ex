defmodule MapDelta.Application do
  @moduledoc """
  The application allows to modify a given map `t:MapDelta.state/0` with a given
  `t:MapDelta.t/0`.

  Map state is represented as a set of `t:MapDelta.Operation.add/0` operations.
  By this token, applying delta to a state should still result in a set of `add`
  operations. If application returns anything but a set of `add` operatins, this
  is conisdered and error.

  In simpler terms, you would not be able to remove, change or replace items
  that weren't first added to the state.
  """

  alias MapDelta.{Operation, OperationSets, ItemDelta}

  @typedoc """
  Specifies path at which error happened.
  """
  @type item_path :: [String.t]

  @typedoc """
  An atom representing reason for an application error.
  """
  @type error_reason :: atom

  @typedoc """
  Result of `&MapDelta.appy/2` operation.

  Either a successful new state or an error with a clear reason.
  """
  @type result :: {:ok, MapDelta.state}
                | {:error, {item_path, error_reason}}

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
      {:error, {["b"], :item_not_found}}
  """
  @spec apply(MapDelta.state, MapDelta.t) :: result
  def apply(state, delta) do
    result =
      {MapDelta.operations(state), MapDelta.operations(delta)}
      |> OperationSets.item_pairs()
      |> Enum.reduce_while([], &do_compose/2)
    case result do
      {:error, error} ->
        {:error, error}
      ops ->
        {:ok, %MapDelta{ops: ops}}
    end
  end

  @doc """
  Applies given delta to a particular map state, resulting in a new state.

  Equivalent to `&MapDelta.apply/2`, but raises an exception on failed
  composition.
  """
  @spec apply!(MapDelta.state, MapDelta.t) :: MapDelta.state
  def apply!(state, delta) do
    case __MODULE__.apply(state, delta) do
      {:ok, new_state} ->
        new_state
      {:error, {path, reason}} ->
        path_string = Enum.join(path, ".")
        reason_string = Atom.to_string(reason)
        raise "Can not apply change to `#{path_string}`: #{reason_string}"
    end
  end

  defp do_compose({%{add: _} = add, nil}, ops) do
    {:cont, ops ++ [add]}
  end

  defp do_compose({_, %{add: _} = add}, ops) do
    {:cont, ops ++ [add]}
  end

  defp do_compose({%{add: _}, %{remove: _}}, ops) do
    {:cont, ops}
  end

  defp do_compose({%{add: key}, %{replace: _, init: init}}, ops) do
    add = Operation.add(key, init)
    {:cont, ops ++ [add]}
  end

  defp do_compose({%{add: key, init: init}, %{change: _, delta: delta}}, ops) do
    case ItemDelta.apply(init, delta) do
      {:ok, new_delta} ->
        add = Operation.add(key, new_delta)
        {:cont, ops ++ [add]}
      {:error, {path, reason}} ->
        {:halt, {:error, {[key | path], reason}}}
    end
  end

  defp do_compose({%{} = op_a, _}, _) do
    key = Operation.item_key(op_a)
    {:halt, {:error, {[key], :item_not_found}}}
  end

  defp do_compose({_, %{} = op_b}, _) do
    key = Operation.item_key(op_b)
    {:halt, {:error, {[key], :item_not_found}}}
  end
end
