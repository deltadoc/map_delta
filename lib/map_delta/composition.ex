defmodule MapDelta.Composition do
  @moduledoc """
  The composition of two non-concurrent delta into a single one.

  The deltas are composed in such a way that the resulting delta has the same
  effect on document state as applying one delta and then the other:

    S ○ compose(Oa, Ob) = S ○ Oa ○ Ob

  In more simple terms, composition allows you to take many deltas and
  transform them into one of equal effect. When used together with Operational
  Transformation that allows to reduce system overhead when tracking non-synced
  changes.
  """

  alias MapDelta.{Operation, OperationSets, ItemDelta}

  @typedoc """
  Specifies path at which error happened.
  """
  @type error_path :: [String.t]

  @typedoc """
  Provides a reason for a failure.
  """
  @type error_reason :: atom

  @typedoc """
  Result of `&MapDelta.apply_to_state/2` operation.

  Either a successful new state or an error with a clear reason.
  """
  @type state_application_result :: {:ok, MapDelta.state}
                                  | {:error, {error_path, error_reason}}

  @doc """
  Composes two deltas into a single equivalent one.

  ## Examples

      iex> delta = MapDelta.add("a", 3)
      %MapDelta{ops: [%{add: "a", init: 3}]}
      iex> MapDelta.compose(delta, MapDelta.replace("a", 5))
      %MapDelta{ops: [%{add: "a", init: 5}]}
  """
  @spec compose(MapDelta.t, MapDelta.t) :: MapDelta.t
  def compose(first, second) do
    {MapDelta.operations(first), MapDelta.operations(second)}
    |> OperationSets.item_pairs()
    |> Enum.reduce_while({:ok, MapDelta.new()}, &do_compose(&1, &2, :delta))
    |> elem(1)
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
  @spec apply_to_state(MapDelta.t, MapDelta.state) :: state_application_result
  def apply_to_state(delta, state) do
    {MapDelta.operations(state), MapDelta.operations(delta)}
    |> OperationSets.item_pairs()
    |> Enum.reduce_while({:ok, MapDelta.new()}, &do_compose(&1, &2, :state))
  end

  @doc """
  Applies given delta to a particular map state, resulting in a new state.

  Equivalent to `&MapDelta.apply_to_state/2`, but raises an exception on failed
  composition.
  """
  @spec apply_to_state!(MapDelta.t, MapDelta.state) :: MapDelta.state
  def apply_to_state!(delta, state) do
    case apply_to_state(delta, state) do
      {:ok, new_state} ->
        new_state
      {:error, {_path, _reason}} ->
        raise "Application resulted in a bad state"
    end
  end

  defp do_compose({%{add: _} = op_a, nil}, result, :state) do
    {:cont, append_to_result(result, op_a)}
  end

  defp do_compose({nil, %{add: _} = op_b}, result, :state) do
    {:cont, append_to_result(result, op_b)}
  end

  defp do_compose({op_a, nil}, _, :state) do
    {:halt, {:error, {[Operation.item_key(op_a)], :item_not_found}}}
  end

  defp do_compose({nil, op_b}, _, :state) do
    {:halt, {:error, {[Operation.item_key(op_b)], :item_not_found}}}
  end

  defp do_compose({op_a, nil}, result, _) do
    {:cont, append_to_result(result, op_a)}
  end

  defp do_compose({nil, op_b}, result, _) do
    {:cont, append_to_result(result, op_b)}
  end

  defp do_compose({%{add: _},
                   %{add: _} = add_b}, result, _) do
    {:cont, append_to_result(result, add_b)}
  end

  defp do_compose({%{add: _},
                   %{remove: _}}, result, _) do
    {:cont, result}
  end

  defp do_compose({%{add: key},
                   %{replace: _, init: init}}, result, _) do
    add = Operation.add(key, init)
    {:cont, append_to_result(result, add)}
  end

  defp do_compose({%{add: key, init: init},
                   %{change: _, delta: op_delta}}, result, :state) do
    case ItemDelta.apply_to_state(op_delta, init) do
      {:ok, new_state} ->
        add = Operation.add(key, new_state)
        {:cont, append_to_result(result, add)}
      {:error, {path, reason}} ->
        {:halt, {:error, {[key | path], reason}}}
    end
  end

  defp do_compose({%{add: key, init: init},
                   %{change: _, delta: op_delta}}, result, _) do
    add = Operation.add(key, ItemDelta.compose(init, op_delta))
    {:cont, append_to_result(result, add)}
  end

  defp do_compose({%{replace: key},
                   %{change: _}}, _, :state) do
    {:halt, {:error, {[key], :item_not_found}}}
  end

  defp do_compose({%{replace: key, init: init},
                   %{change: _, delta: op_delta}}, result, _) do
    replace = Operation.replace(key, ItemDelta.compose(init, op_delta))
    {:cont, append_to_result(result, replace)}
  end

  defp do_compose({%{change: key},
                   %{change: _}}, _, :state) do
    {:halt, {:error, {[key], :item_not_found}}}
  end

  defp do_compose({%{change: key, delta: op_a_delta},
                   %{change: _, delta: op_b_delta}}, result, _) do
    change = Operation.change(key, ItemDelta.compose(op_a_delta, op_b_delta))
    {:cont, append_to_result(result, change)}
  end

  defp do_compose({%{change: key},
                   %{remove: _}}, _, :state) do
    {:halt, {:error, {[key], :item_not_found}}}
  end

  defp do_compose({%{remove: _} = remove,
                   %{change: _}}, result, _) do
    {:cont, append_to_result(result, remove)}
  end

  defp do_compose({_, %{add: key}}, _, :state) do
    {:halt, {:error, {[key], :item_not_found}}}
  end

  defp do_compose({_, %{add: key, init: init}}, result, _) do
    replace = Operation.replace(key, init)
    {:cont, append_to_result(result, replace)}
  end

  defp do_compose({_, %{remove: key}}, _, :state) do
    {:halt, {:error, {[key], :item_not_found}}}
  end

  defp do_compose({_, %{remove: _} = remove}, result, _) do
    {:cont, append_to_result(result, remove)}
  end

  defp do_compose({_, %{replace: key}}, _, :state) do
    {:halt, {:error, {[key], :item_not_found}}}
  end

  defp do_compose({_, %{replace: _} = replace}, result, _) do
    {:cont, append_to_result(result, replace)}
  end

  defp append_to_result({:ok, %MapDelta{ops: ops}}, new_ops) do
    {:ok, %MapDelta{ops: ops ++ List.wrap(new_ops)}}
  end
end
