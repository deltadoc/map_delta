defmodule MapDelta.Transformation do
  @moduledoc """
  The transformation of two concurrent deltas such that they satisfy the
  convergence properties of Operational Transformation.

  Transformation allows optimistic conflict resolution in concurrent editing.
  Given a delta A that occurred at the same time as delta B against the same
  map state, we can transform the operations of delta A such that the state of
  the map after applying delta A and then delta B is the same as after applying
  delta B and then the transformation of delta A against delta B:

    S ○ Oa ○ transform(Ob, Oa) = S ○ Ob ○ transform(Oa, Ob)

  There is a great article writte on [Operational Transformation][ot1] that
  author of this library used. It is called [Understanding and Applying
  Operational Transformation][ot2].

  [tp1]: https://en.wikipedia.org/wiki/Operational_transformation#Convergence_properties
  [ot1]: https://en.wikipedia.org/wiki/Operational_transformation
  [ot2]: http://www.codecommit.com/blog/java/understanding-and-applying-operational-transformation
  """

  alias MapDelta.{Operation, OperationSets, ItemDelta}

  @typedoc """
  Atom representing transformation priority. Which delta came first?
  """
  @type priority :: :left | :right

  @doc """
  Transforms `right` delta against the `left` one.

  The function also takes a third `t:MapDelta.Transformation.priority/0`
  argument that indicates which delta came first. This is important when
  resolving conflicts.
  """
  @spec transform(MapDelta.t, MapDelta.t, priority) :: MapDelta.t
  def transform(left, right, priority) do
    {MapDelta.operations(left), MapDelta.operations(right)}
    |> OperationSets.item_pairs()
    |> Enum.map(&do_transform(&1, priority))
    |> Enum.reject(&is_nil/1)
    |> wrap_into_delta()
  end

  defp do_transform({nil, right}, _) do
    right
  end

  defp do_transform({_, nil}, _) do
    nil
  end

  defp do_transform({%{remove: _}, %{remove: _}}, :right) do
    nil
  end

  defp do_transform({_, %{remove: _} = remove}, :right) do
    remove
  end

  defp do_transform({%{change: _}, %{remove: _} = remove}, :left) do
    remove
  end

  defp do_transform({%{remove: _}, %{add: _} = add}, :right) do
    add
  end

  defp do_transform({%{remove: _}, %{replace: key, init: init}}, :right) do
    Operation.add(key, init)
  end

  defp do_transform({_, %{add: key, init: init}}, :right) do
    Operation.replace(key, init)
  end

  defp do_transform({%{change: _}, %{add: key, init: init}}, :left) do
    Operation.replace(key, init)
  end

  defp do_transform({_, %{replace: _} = replace}, :right) do
    replace
  end

  defp do_transform({%{change: _}, %{replace: _} = replace}, :left) do
    replace
  end

  defp do_transform({%{change: key, delta: left},
                     %{change: _, delta: right}}, priority) do
    Operation.change(key, ItemDelta.transform(left, right, priority))
  end

  defp do_transform({_, _}, _) do
    nil
  end

  defp wrap_into_delta(ops), do: %MapDelta{ops: ops}
end
